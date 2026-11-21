# Numen voice control and dictation

Numen handles voice **commands** (Vosk, phrase files in `dotfiles/.config/numen/phrases/`).
**Dictation** (typing prose) is Voxtype: see `docs/dictation.md`.

Everything here is in `modules/home/app-numen.nix`, imported by `modules/home/common.nix`, so
every host gets it (fedora-desktop and fedora-laptop included).

## Contents

1. [Starting and stopping](#starting-and-stopping)
2. [Voice commands](#voice-commands)
3. [Dictation](#dictation)
4. [Files](#files)
5. [Setting up a new machine](#setting-up-a-new-machine)
6. [Troubleshooting](#troubleshooting)

---

## Starting and stopping

Numen runs as the `numen` systemd user service. It is **not** started at login. The tray icon
(`numen-tray`) is, so you start numen when you want it.

**Tray icon** (microphone in the DMS tray):

| Icon | State |
|---|---|
| grey with a slash | stopped |
| grey outline | stopping |
| blue | starting (loading the model; not listening yet) |
| green | running, awake |
| amber with a "z" | running, asleep |
| purple | running, ignoring speech after "Alexa" |

**Mod+Delete:** start / stop numen (the tray icon stays and shows the state).

- Left click: start / stop numen
- Middle click: sleep / wake
- Right click: menu (status, start/stop, restart, sleep/wake, show log, quit tray)

**"Numen" launcher entry** (Mod+Space or fuzzel): starts numen, and brings the tray icon back
if it was quit or killed.

**From a terminal:**

```sh
numen-mode on        # start numen (and the tray if needed)
numen-mode off       # stop numen; the tray stays
numen-mode power     # on if stopped, off if running (Mod+Delete)
numen-mode sleep     # only listen for "wake up"
numen-mode wake
numen-mode ignore 20 # ignore speech for 20s, then go back (what "alexa" runs)
numen-mode status    # awake / asleep / ignoring
journalctl --user -fu numen   # numen's log (also "Show log" in the tray)
```

A numen started by hand in a terminal is detected too; the tray shows it and can stop it.

## Voice commands

Phrase files: `dotfiles/.config/numen/phrases/*.phrases`. A few that control numen itself:

| Say | Does |
|---|---|
| `sleep` | sleep mode: ignore everything except "wake up" |
| `wake up` | back to normal |
| `alexa …` | ignore speech for 20s so Alexa commands and replies don't run numen commands |
| `newman off` | stop numen (say it like "numen off"; "numen" isn't in Vosk's vocabulary) |

Sleep mode loads `~/.config/numen/sleep.phrases`, which is generated at build time from
`dotfiles/.config/numen/sleep-filler.words` plus every word in the phrase files, so random
speech doesn't wake it.

**Alexa:** "alexa" is a `@transcribe` phrase (`control.phrases`), so the rest of that utterance
("alexa, turn off the lights") is swallowed instead of run as commands; said alone, the next
utterance is swallowed. It then runs `numen-mode ignore`, which loads
`~/.config/numen/ignore.phrases` (decoy words plus "alexa", which restarts the timer) for
`ignoreSeconds` (20, in `app-numen.nix`) and then `numen-mode restore`. Sleep, wake, dictate
and off cancel the timer; when asleep, "alexa" does nothing.

## Dictation

Say **"dictate"** (or press Mod+D) to start Voxtype, talk, then say **"stop dictating"** (or
press Mod+D). Meanwhile numen loads `~/.config/numen/dictating.phrases` (`numen-mode
dictating`), which, like sleep mode, holds only the stop phrase plus decoy words. Afterwards
`numen-mode restore` puts it back in the mode it was in. Details: `docs/dictation.md`.

The Vosk `@transcribe` phrases ("plain say …", "snake say …" etc. in `voice.phrases`) still type
short text through numen itself.

## Files

| File | What |
|---|---|
| `modules/home/app-numen.nix` | services, `numen-mode`, sleep/dictating phrase files, desktop entry |
| `modules/home/numen-tray.py` | tray icon |
| `dotfiles/.config/numen/phrases/` | numen voice commands |
| `dotfiles/.config/numen/sleep-filler.words` | extra decoy words for sleep and dictating modes |
| `dotfiles/.config/niri/config.kdl` | Mod+D (dictation) and Mod+Delete (on/off) bindings |

User services: `numen` (on demand) and `numen-tray` (at login); `voxtype` is in
`docs/dictation.md`.

## Setting up a new machine

Home Manager installs numen itself: `pkgs/numen.nix` builds `numen`/`numenc` from the
`numen-src` flake input (upstream master, updated by `nix flake update` / `update-system`) with
the prebuilt libvosk and the `en-us-0.22-lgraph` Vosk model, and links its helper scripts to
`~/.config/numen/scripts` (used by `voice.phrases`). If an update fails with a hash mismatch on
`numen-…-go-modules`, upstream changed its Go dependencies: paste the "got:" hash into
`vendorHash` in `pkgs/numen.nix`. Still needed outside this repo on Fedora:

- the uinput udev rule (`/etc/udev/rules.d/80-dotool.rules`) and your user in the `input` group
  (dotool itself comes from nixpkgs)

Then `home-manager switch --flake ~/.nix#jordan@<host>` and log out and back in (or
`systemctl --user start numen-tray`).

## Troubleshooting

- **Tray icon missing:** launch "Numen" from the launcher, or `systemctl --user start numen-tray`.
- **Numen shows "failed" after stopping:** expected. Numen often hangs while exiting, so the
  service kills it after 2 s, which systemd records as a failed stop. Starting it again works.
- **Started, but commands don't work yet:** wait for the icon to turn green (blue = still loading).
- **Dictation:** see the troubleshooting section of `docs/dictation.md`.
