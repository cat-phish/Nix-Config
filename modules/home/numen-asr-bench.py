"""Compare dictation models on your own voice (see app-numen.nix).

  numen-asr-bench record   read each sentence aloud (Enter to start/stop)
  numen-asr-bench run      transcribe with every model, print WER and timings

Clips go to ~/.local/state/numen/bench. Whisper is timed as numen-dictate
runs it (one whisper-cli per clip, after you stop talking). asr4all is fed in
320 ms chunks as it is live; "wait" is only the final flush, since the rest is
decoded while you talk.
"""

import json
import os
import re
import signal
import subprocess
import sys
import time
import wave

WHISPER_CLI = "@whisper_cli@"
WHISPER_MODELS = json.loads('@whisper_models@')
ASR4ALL_MODELS = json.loads('@asr4all_models@')
REC = "@rec@"
SENTENCES = "@sentences@"
DIR = os.path.expanduser("~/.local/state/numen/bench")
TIERS = ["stream_c16r4", "stream_c32r8", "stream_c64r16"]


def refs():
    return [l.strip() for l in open(SENTENCES) if l.strip() and not l.startswith("#")]


def clip(i):
    return os.path.join(DIR, f"clip{i + 1:02d}.wav")


def record():
    os.makedirs(DIR, exist_ok=True)
    rs = refs()
    for i, ref in enumerate(rs):
        print(f"\n[{i + 1}/{len(rs)}] {ref}")
        input("    Enter to start recording... ")
        p = subprocess.Popen([REC, "-q", "-c", "1", "-r", "16000", "-b", "16",
                              "-e", "signed-integer", clip(i), "highpass", "100"])
        input("    recording; Enter when done ")
        p.send_signal(signal.SIGINT)
        p.wait()
        print(f"    saved {clip(i)} ({duration(clip(i)):.1f} s)")


def duration(f):
    with wave.open(f) as w:
        return w.getnframes() / w.getframerate()


def norm(t):
    return re.sub(r"[^a-z' ]", " ", t.lower()).split()


def errors(ref, hyp):
    """Word edit distance, reference length."""
    r, h = norm(ref), norm(hyp)
    d = list(range(len(h) + 1))
    for i in range(1, len(r) + 1):
        prev, d[0] = d[0], i
        for j in range(1, len(h) + 1):
            prev, d[j] = d[j], min(d[j] + 1, d[j - 1] + 1, prev + (r[i - 1] != h[j - 1]))
    return d[len(h)], len(r)


def run():
    rs = refs()
    pairs = [(clip(i), r) for i, r in enumerate(rs) if os.path.exists(clip(i))]
    if not pairs:
        sys.exit("no clips; run `numen-asr-bench record` first")
    rows, outs = [], {}

    for name, model in WHISPER_MODELS.items():
        err = n = 0
        waits, hyps = [], []
        for c, ref in pairs:
            ac = min(1500, max(384, int(duration(c) * 50) + 128))
            t = time.time()
            out = subprocess.run([WHISPER_CLI, "-m", model, "-f", c, "-nt", "-np", "-t", "4",
                                  "-bs", "1", "-bo", "1", "-ac", str(ac)],
                                 capture_output=True, text=True).stdout
            waits.append(time.time() - t)
            hyp = " ".join(re.sub(r"\[[^]]*\]", "", out).split())
            hyps.append(hyp)
            e, k = errors(ref, hyp)
            err, n = err + e, n + k
        rows.append((f"whisper {name}", 100 * err / n, sum(waits) / len(waits), "after"))
        outs[rows[-1][0]] = hyps

    import numpy as np
    import onnxruntime as ort

    base = ort.SessionOptions

    def options():
        so = base()
        so.intra_op_num_threads = 4
        so.inter_op_num_threads = 1
        so.add_session_config_entry("session.intra_op.allow_spinning", "0")
        return so

    ort.SessionOptions = options
    import importlib

    for size, d in ASR4ALL_MODELS.items():
        sys.path.insert(0, d)
        sys.modules.pop("asr4all_onnx", None)
        a = importlib.import_module("asr4all_onnx")
        sys.path.pop(0)
        eng = a.load_engine(d)
        for tier in TIERS:
            eng.set_tier(tier)
            lag = next(t for t in eng.tiers if t["name"] == tier)
            first = (lag["commit"] + lag["lookahead"]) * 0.04
            err = n = 0
            waits, hyps = [], []
            for c, ref in pairs:
                pcm = a.load_wav(c)
                eng.reset()
                for i in range(0, len(pcm), 5120):
                    eng.decode_stream(pcm[i:i + 5120])
                t = time.time()
                eng.finish()
                hyp = eng.decode_pcec(decode_tail=True)
                waits.append(time.time() - t)
                hyps.append(hyp)
                e, k = errors(ref, hyp)
                err, n = err + e, n + k
            rows.append((f"asr4all-{size} {tier}", 100 * err / n, sum(waits) / len(waits),
                         f"~{first:.1f}s behind"))
            outs[rows[-1][0]] = hyps

    print(f"\n{'model':28} {'WER %':>6} {'wait (s)':>9}  typing")
    for name, wer, wait, typing in rows:
        print(f"{name:28} {wer:6.1f} {wait:9.2f}  {typing}")
    print()
    for i, (_, ref) in enumerate(pairs):
        print(f"REF {ref}")
        for name, hyps in outs.items():
            if norm(hyps[i]) != norm(ref):
                print(f"    {name:28} {hyps[i]}")


if __name__ == "__main__":
    {"record": record, "run": run}.get(sys.argv[1] if len(sys.argv) > 1 else "", lambda: sys.exit(__doc__))()
