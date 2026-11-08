"""Rolling microphone buffer for numen-dictate (see app-numen.nix).

numen only performs the "say" trigger after the utterance ends, so speech
that comes right after "say" has already happened by then. This daemon keeps
the last BUFFER_SECS of 16 kHz mono audio in RAM; a capture request pulls the
most recent stretch of speech out of it and keeps recording live until the
speaker goes quiet.

  numen-dictate-buffer serve
  numen-dictate-buffer capture OUT.wav [--gap S] [--end S] [--max S] [--threshold F]
  numen-dictate-buffer stream [--gap S] [--end S] [--max S] [--threshold F]

capture prints nothing and exits 0 if OUT.wav was written, 1 if no speech.
stream writes the same audio as raw s16le 16 kHz mono to stdout as it
arrives (buffered speech first, then live), for numen-dictate-stream; exits
0 if there was speech, 1 if not.
SIGINT/SIGTERM to either stops it early and keeps what was recorded.
"""

import argparse
import array
import collections
import math
import os
import select
import signal
import socket
import subprocess
import sys
import threading
import wave

RATE = 16000
FPS = 50  # 20 ms frames
FRAME_BYTES = RATE // FPS * 2
BUFFER_SECS = 30
LEAD_IN = 10  # frames of audio kept before detected speech start (200 ms)
REC = "@rec@"


def sock_path():
    run = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    return os.path.join(run, "numen-dictate", "buffer.sock")


def level(b):
    a = array.array("h")
    a.frombytes(b)
    return math.sqrt(sum(x * x for x in a) / len(a)) / 32768


class Buffer:
    def __init__(self):
        self.frames = collections.deque(maxlen=BUFFER_SECS * FPS)  # (seq, bytes, level)
        self.seq = 0
        self.cond = threading.Condition()

    def push(self, b):
        lv = level(b)
        with self.cond:
            self.frames.append((self.seq, b, lv))
            self.seq += 1
            self.cond.notify_all()


def reader(buf):
    cmd = os.environ.get("NUMEN_BUFFER_SOURCE")  # testing hook: shell command emitting raw s16le
    if cmd:
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    else:
        p = subprocess.Popen(
            [REC, "-q", "-t", "raw", "-c", "1", "-r", str(RATE), "-b", "16",
             "-e", "signed-integer", "-", "highpass", "100"],
            stdout=subprocess.PIPE)
    while True:
        b = p.stdout.read(FRAME_BYTES)
        if len(b) < FRAME_BYTES:
            break
        buf.push(b)
    print("numen-dictate-buffer: audio source ended", file=sys.stderr)
    os._exit(1)  # let systemd restart us


def speech_start(levels, thr, gap_frames):
    """Index where the most recent speech run begins, or None if no speech.

    A run ends at the last loud frame and extends back until a stretch of
    gap_frames quiet frames (so short pauses inside a sentence don't split it).
    """
    i = len(levels) - 1
    while i >= 0 and levels[i] < thr:
        i -= 1
    if i < 0:
        return None
    quiet = 0
    for j in range(i, -1, -1):
        if levels[j] < thr:
            quiet += 1
            if quiet >= gap_frames:
                return max(0, j + gap_frames - LEAD_IN)
        else:
            quiet = 0
    return 0


def speech_frames(conn, buf, gap, end, mx, thr, state):
    """Yield the frames of the most recent speech: what's already buffered
    since it started, then live frames until `end` seconds of quiet, `mx`
    seconds in total, or the client sends anything (stop) / goes away.
    Sets state["stopped"] and state["trailing"] (quiet frames at the end)."""
    gap_f, end_f, max_f = int(gap * FPS), int(end * FPS), int(mx * FPS)
    state["stopped"], state["trailing"] = False, 0
    with buf.cond:
        snap = list(buf.frames)
    levels = [x[2] for x in snap]
    start = speech_start(levels, thr, gap_f)
    heard, trailing, n = start is not None, 0, 0
    if heard:
        trailing = len(levels) - 1 - max(k for k, v in enumerate(levels) if v >= thr)
        for x in snap[start:]:
            n += 1
            yield x[1]
    last = snap[-1][0] if snap else buf.seq - 1

    while not (heard and trailing >= end_f) and n < max_f:
        if select.select([conn], [], [], 0)[0]:
            state["stopped"] = True  # client asked to stop (or went away)
            try:
                conn.recv(64)  # read it: closing with unread data resets the connection
            except OSError:
                pass
            break
        with buf.cond:
            buf.cond.wait_for(lambda: buf.seq - 1 > last, timeout=0.1)
            new = [x for x in buf.frames if x[0] > last]
        for seq, b, lv in new:
            last = seq
            if lv >= thr:
                heard, trailing = True, 0
            elif heard:
                trailing += 1
            if heard:
                n += 1
                yield b
    state["trailing"] = trailing


def handle(conn, buf):
    try:
        f = conn.makefile("rb")
        parts = f.readline().decode().split()
        state = {}
        if len(parts) == 6 and parts[0] == "capture":
            out = parts[1]
            frames = list(speech_frames(conn, buf, *map(float, parts[2:]), state))
            if not frames:
                conn.sendall(b"empty\n")
                return
            # Drop most of the trailing silence; whisper doesn't need it.
            if not state["stopped"] and state["trailing"] > LEAD_IN:
                frames = frames[: len(frames) - state["trailing"] + LEAD_IN]
            with wave.open(out, "wb") as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(RATE)
                w.writeframes(b"".join(frames))
            conn.sendall(b"ok\n")
        elif len(parts) == 5 and parts[0] == "stream":
            # Raw audio, then the connection closes; no header or status line.
            for b in speech_frames(conn, buf, *map(float, parts[1:]), state):
                conn.sendall(b)
        else:
            conn.sendall(b"error bad request\n")
    except (OSError, ValueError) as e:
        try:
            conn.sendall(f"error {e}\n".encode())
        except OSError:
            pass
    finally:
        conn.close()


def serve():
    path = sock_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass
    buf = Buffer()
    threading.Thread(target=reader, args=(buf,), daemon=True).start()
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    old = os.umask(0o077)
    s.bind(path)
    os.umask(old)
    s.listen(4)
    while True:
        conn, _ = s.accept()
        threading.Thread(target=handle, args=(conn, buf), daemon=True).start()


def capture(a):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(sock_path())
    out = os.path.abspath(a.out)
    s.sendall(f"capture {out} {a.gap} {a.end} {a.max} {a.threshold}\n".encode())

    def stop(*_):
        try:
            s.sendall(b"stop\n")
        except OSError:
            pass

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    resp = s.makefile("rb").readline().decode().strip()
    if resp.startswith("error"):
        print(f"numen-dictate-buffer: {resp}", file=sys.stderr)
    sys.exit(0 if resp == "ok" else 1)


def stream(a):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(sock_path())
    s.sendall(f"stream {a.gap} {a.end} {a.max} {a.threshold}\n".encode())

    def stop(*_):
        try:
            s.sendall(b"stop\n")
        except OSError:
            pass

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    out, got = sys.stdout.buffer, False
    while True:
        try:
            b = s.recv(FRAME_BYTES * 8)
        except InterruptedError:
            continue
        except ConnectionResetError:
            break
        if not b:
            break
        got = True
        try:
            out.write(b)
            out.flush()
        except BrokenPipeError:
            break  # the reader went away
    sys.exit(0 if got else 1)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("serve")
    c = sub.add_parser("capture")
    c.add_argument("out")
    st = sub.add_parser("stream")
    for x in (c, st):
        x.add_argument("--gap", type=float, default=1.0, help="silence (s) that separates utterances")
        x.add_argument("--end", type=float, default=1.0, help="silence (s) that ends the capture")
        x.add_argument("--max", type=float, default=120.0, help="max capture length (s)")
        x.add_argument("--threshold", type=float, default=0.03, help="speech level, fraction of full scale")
    a = p.parse_args()
    {"serve": lambda: serve(), "capture": lambda: capture(a), "stream": lambda: stream(a)}[a.cmd]()


if __name__ == "__main__":
    main()
