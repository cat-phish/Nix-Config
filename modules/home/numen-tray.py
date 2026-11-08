# Tray icon for numen: shows its state and starts, stops, sleeps and wakes it.
# Wrapped by modules/home/app-numen.nix, which substitutes @numen_mode@ and
# runs it from the numen-tray user service.
#
# numen itself runs as the numen.service user unit (never auto-started);
# a numen started by hand in a terminal is still detected and can be stopped.
#
# States: stopped, starting (loading the model; not listening yet), awake,
# asleep, stopping.
import signal
import subprocess
import sys

from PyQt6.QtCore import QPointF, QRectF, Qt, QTimer
from PyQt6.QtGui import QColor, QIcon, QPainter, QPen, QPixmap
from PyQt6.QtWidgets import QApplication, QMenu, QSystemTrayIcon

NUMEN_MODE = "@numen_mode@"
POLL_MS = 1000
FAST_POLL_MS = 250
FAST_POLLS = 20  # ~5s of fast polling after an action

COLORS = {
    "stopped": QColor("#8a8a8a"),
    "stopping": QColor("#8a8a8a"),
    "starting": QColor("#58a6ff"),
    "awake": QColor("#3fb950"),
    "asleep": QColor("#d29922"),
}
LABELS = {
    "stopped": "Numen: stopped",
    "stopping": "Numen: stopping…",
    "starting": "Numen: starting… (not listening yet)",
    "awake": "Numen: running · awake",
    "asleep": "Numen: running · asleep",
}
LISTENING = ("awake", "asleep")


def run(*cmd):
    """Run a command quietly; return stdout, or None if it failed."""
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


def spawn(*cmd):
    """Start a command without waiting for it."""
    try:
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
    except OSError as e:
        print(f"numen-tray: {cmd[0]}: {e}", file=sys.stderr)


def current_state():
    unit = run("systemctl", "--user", "show", "numen", "-p", "ActiveState", "--value") or ""
    if unit == "deactivating":
        return "stopping"
    if unit == "activating":
        return "starting"
    pids = (run("pgrep", "-x", "numen") or "").split()
    if not pids:
        return "stopped"
    # numen starts arecord only once the model and recognizers are loaded.
    if not any(run("pgrep", "-P", pid, "-x", "arecord") for pid in pids):
        return "starting"
    return "asleep" if run(NUMEN_MODE, "status") == "asleep" else "awake"


def make_icon(state):
    """A microphone: hollow when stopped/stopping (slash when stopped), filled
    when starting/running, with a z when asleep."""
    size = 64
    pix = QPixmap(size, size)
    pix.fill(Qt.GlobalColor.transparent)
    p = QPainter(pix)
    p.setRenderHint(QPainter.RenderHint.Antialiasing)
    color = COLORS[state]
    pen = QPen(color, 5)
    pen.setCapStyle(Qt.PenCapStyle.RoundCap)
    p.setPen(pen)
    hollow = state in ("stopped", "stopping")
    p.setBrush(Qt.BrushStyle.NoBrush if hollow else color)
    p.drawRoundedRect(QRectF(20, 6, 24, 34), 12, 12)
    # Holder arc and stand
    p.setBrush(Qt.BrushStyle.NoBrush)
    p.drawArc(QRectF(12, 18, 40, 32), 180 * 16, 180 * 16)
    p.drawLine(32, 50, 32, 58)
    p.drawLine(22, 58, 42, 58)
    if state == "stopped":
        p.drawLine(10, 8, 54, 56)
    elif state == "asleep":
        p.setPen(QPen(QColor("#ffffff"), 4))
        z = [(26, 14), (38, 14), (26, 30), (38, 30)]
        p.drawPolyline([QPointF(x, y) for x, y in z])
    p.end()
    return QIcon(pix)


class NumenTray:
    def __init__(self, app):
        self.state = None
        self.fast_polls = 0
        self.icons = {s: make_icon(s) for s in COLORS}

        self.tray = QSystemTrayIcon()
        self.tray.activated.connect(self.on_activated)

        self.menu = QMenu()
        self.status_action = self.menu.addAction("")
        self.status_action.setEnabled(False)
        self.menu.addSeparator()
        self.startstop_action = self.menu.addAction("", self.toggle_running)
        self.restart_action = self.menu.addAction("Restart numen", self.restart)
        self.sleep_action = self.menu.addAction("", self.toggle_sleep)
        self.menu.addSeparator()
        self.menu.addAction("Show log", self.show_log)
        self.menu.addAction("Quit tray", app.quit)
        self.tray.setContextMenu(self.menu)

        self.timer = QTimer()
        self.timer.timeout.connect(self.tick)
        self.timer.start(POLL_MS)
        self.refresh()
        self.tray.show()

    def tick(self):
        self.refresh()
        if self.fast_polls:
            self.fast_polls -= 1
            if not self.fast_polls:
                self.timer.setInterval(POLL_MS)

    def poll_fast(self):
        # Show the change quickly instead of waiting for the next slow poll.
        self.fast_polls = FAST_POLLS
        self.timer.setInterval(FAST_POLL_MS)

    def refresh(self):
        state = current_state()
        if state == self.state:
            return
        self.state = state
        self.tray.setIcon(self.icons[state])
        self.tray.setToolTip(LABELS[state])
        self.status_action.setText(LABELS[state])
        # While stopping, the next click starts it again (queued after the stop).
        on = state not in ("stopped", "stopping")
        self.startstop_action.setText("Stop numen" if on else "Start numen")
        self.restart_action.setEnabled(on)
        self.sleep_action.setText("Wake" if state == "asleep" else "Sleep")
        self.sleep_action.setEnabled(state in LISTENING)
        # A state still in transition: keep polling fast until it settles.
        if state in ("starting", "stopping") and not self.fast_polls:
            self.poll_fast()

    def toggle_running(self):
        state = current_state()
        spawn(NUMEN_MODE, "on" if state in ("stopped", "stopping") else "off")
        self.poll_fast()

    def restart(self):
        if run("systemctl", "--user", "is-active", "--quiet", "numen") is not None:
            spawn("systemctl", "--user", "restart", "numen")
        else:
            # Started by hand in a terminal: stop it, then start the service.
            spawn("sh", "-c", f"{NUMEN_MODE} off && {NUMEN_MODE} on")
        self.poll_fast()

    def toggle_sleep(self):
        if current_state() in LISTENING:
            spawn(NUMEN_MODE, "toggle")
            self.poll_fast()

    def show_log(self):
        spawn("kitty", "--title", "numen log", "journalctl", "--user", "-fu", "numen")

    def on_activated(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.Trigger:
            self.toggle_running()
        elif reason == QSystemTrayIcon.ActivationReason.MiddleClick:
            self.toggle_sleep()


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("numen-tray")
    app.setQuitOnLastWindowClosed(False)
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    signal.signal(signal.SIGTERM, signal.SIG_DFL)
    _tray = NumenTray(app)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
