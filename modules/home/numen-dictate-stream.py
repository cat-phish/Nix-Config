"""Streaming dictation with FUTO's asr4all (see app-numen.nix).

Reads raw s16le 16 kHz mono audio from stdin (rec, or numen-dictate-buffer
stream) and types the transcript while you talk.

  numen-dictate-stream [--silence S] [--threshold F] [--strip-say]
  numen-dictate-stream --file CLIP.wav      # print the transcript, type nothing

It types the punctuated, cased text (the model's PCEC pass, rendered with its
tail so it isn't ~2.5s behind the raw transcript). The last word is held back
until the next one starts, since it may still grow ("meet" -> "meeting") or
get punctuation; anything already typed that the model then revises is fixed
with backspaces (measured: a handful per sentence).

Stops on end of input, SIGINT/SIGTERM (numen-dictate toggle), or --silence
seconds of quiet after speech; then flushes and types the rest.

Filler words (uh, um, erm...) are dropped; DICTATE_KEEP_FILLERS=1 keeps them.

Env: ASR4ALL_MODEL (onnx/ dir), ASR4ALL_TIER, ASR4ALL_THREADS (4: more is
slower on hybrid P/E-core CPUs).
"""

import argparse
import os
import re
import select
import signal
import subprocess
import sys

MODEL = os.environ.get("ASR4ALL_MODEL", "@model@")
TIER = os.environ.get("ASR4ALL_TIER", "@tier@")
THREADS = int(os.environ.get("ASR4ALL_THREADS", "4"))
CHUNK = 5120  # samples, 320 ms

sys.path.insert(0, MODEL)
import numpy as np  # noqa: E402
import onnxruntime as ort  # noqa: E402

# The model's engine script builds its own SessionOptions; pin the thread
# count (onnxruntime's default of every core ran ~4x slower here) and stop
# idle worker threads busy-waiting (40 s of CPU per 6 s of audio with it,
# 3 s without, same speed).
_SessionOptions = ort.SessionOptions


def _session_options():
    so = _SessionOptions()
    so.intra_op_num_threads = THREADS
    so.inter_op_num_threads = 1
    so.add_session_config_entry("session.intra_op.allow_spinning", "0")
    return so


ort.SessionOptions = _session_options
import asr4all_onnx  # noqa: E402  (ships with the model, in MODEL)


class Typer:
    """Keeps one dotool(c) process open and makes the typed text match a target."""

    def __init__(self, dry):
        self.typed = ""
        self.p = None
        if not dry:
            cmd = "dotoolc" if subprocess.run(["pgrep", "-x", "dotoold"],
                                              capture_output=True).returncode == 0 else "dotool"
            self.p = subprocess.Popen([cmd], stdin=subprocess.PIPE, text=True)

    def show(self, target):
        n = 0
        while n < min(len(self.typed), len(target)) and self.typed[n] == target[n]:
            n += 1
        back, add = len(self.typed) - n, target[n:]
        if not back and not add:
            return
        if self.p:
            if back:
                self.p.stdin.write("key" + " BackSpace" * back + "\n")
            if add:
                self.p.stdin.write("type " + add + "\n")
            self.p.stdin.flush()
        self.typed = target

    def close(self):
        if self.p:
            self.p.stdin.close()
            self.p.wait()


def strip_say(text):
    """Buffered audio starts at (or a few words before) the "say" trigger:
    drop everything up to it if it's within the first 4 words (as the
    Whisper path does)."""
    words = text.split(" ")
    for i, w in enumerate(words[:4]):
        if re.sub(r"[^\w]", "", w).lower() == "say":
            rest = " ".join(words[i + 1:])
            return rest[:1].upper() + rest[1:]
    return text


FILLERS = {"uh", "uhh", "um", "umm", "uhm", "erm"}


def drop_fillers(text):
    """Remove filler words, keeping punctuation and capitals sensible:
    "Uh, this works" -> "This works", "I was, um, thinking" -> "I was thinking",
    "that's it, uh." -> "that's it."."""
    out, cap = [], False
    for w in text.split(" "):
        core, punct = re.match(r"^(.*?)([,.?!]*)$", w).groups()
        if core.lower() in FILLERS:
            end = punct.replace(",", "")
            if out:
                # "word, um, next" -> "word next"; "word, um." -> "word."
                out[-1] = out[-1].rstrip(",") + end
            if not out or end:
                cap = cap or w[:1].isupper() or bool(end)
            continue
        if cap and w:
            w = w[:1].upper() + w[1:]
        cap = False
        out.append(w)
    return " ".join(out)


def stable(text):
    """All but the last word, which may still change."""
    i = text.rfind(" ")
    return text[:i] if i > 0 else ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", help="transcribe a 16 kHz mono wav and print it")
    ap.add_argument("--silence", type=float, default=0, help="stop after S s of quiet after speech (0 = off)")
    ap.add_argument("--threshold", type=float, default=0.03, help="speech level, fraction of full scale")
    ap.add_argument("--strip-say", action="store_true")
    ap.add_argument("--print", action="store_true", help="print instead of typing")
    a = ap.parse_args()

    e = asr4all_onnx.load_engine(MODEL)
    e.set_tier(TIER)

    if a.file:
        print(e.decode_offline(asr4all_onnx.load_wav(a.file)))
        return

    stop = False

    def on_signal(*_):
        nonlocal stop
        stop = True

    signal.signal(signal.SIGINT, on_signal)
    signal.signal(signal.SIGTERM, on_signal)

    typer = Typer(dry=a.print)
    heard, quiet = False, 0.0
    fd, pending, eof = sys.stdin.fileno(), b"", False

    def read_chunk():
        """Up to one chunk of audio; b"" at end of input or on stop. Polls so
        a stop is seen even while the source sends nothing (the buffer only
        streams once it hears speech)."""
        nonlocal pending, eof
        while not stop and not eof and len(pending) < CHUNK * 2:
            try:
                if select.select([fd], [], [], 0.2)[0]:
                    b = os.read(fd, CHUNK * 2 - len(pending))
                    if not b:
                        eof = True
                    pending += b
            except InterruptedError:
                pass
        n = len(pending) // 2 * 2
        out, pending = pending[:n], pending[n:]
        return out

    def render(final):
        t = e.decode_pcec(decode_tail=True)
        if not os.environ.get("DICTATE_KEEP_FILLERS"):
            t = drop_fillers(t)
        if a.strip_say:
            t = strip_say(t)
            if not final and len(t.split()) < 4:
                return ""  # don't type until we know whether it starts with "say"
        return t if final else stable(t)

    while True:
        b = read_chunk()
        if b:
            pcm = np.frombuffer(b, dtype=np.int16).astype(np.float32) / 32768.0
            e.decode_stream(pcm)
        if stop or eof or not b:
            break
        if a.silence:
            if np.sqrt(np.mean(pcm * pcm)) >= a.threshold:
                heard, quiet = True, 0.0
            elif heard:
                quiet += len(pcm) / 16000
                if quiet >= a.silence:
                    break
        typer.show(render(final=False))

    e.finish()
    typer.show(render(final=True))
    if a.print:
        print(typer.typed)
    typer.close()
    sys.exit(0 if typer.typed else 1)


if __name__ == "__main__":
    main()
