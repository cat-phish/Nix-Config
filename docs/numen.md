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

**Claude Code** (`programming.phrases`): "slash clear", "slash compact", "slash resume",
"slash review" (`/code-review`), "slash model", "slash context", "slash init" and "slash help"
type that slash command. "mode switch" presses Shift+Tab (cycle normal/auto-accept/plan mode),
"rewind" presses Escape twice (rewind or edit the previous prompt); "escape" alone still
interrupts. The slash phrases use a `slash` prefix because bare "clear" already clears modifiers
(`control.phrases`), and they don't press Enter (say "enter") so a misheard phrase can't wipe
the session context.

Sleep mode loads `~/.config/numen/sleep.phrases`, which is generated at build time from
`dotfiles/.config/numen/sleep-filler.words` plus every word in the phrase files, so random
speech doesn't wake it.

**herdr-app** (`environment.phrases`): "agent up/down" and "space up/down" switch herdr-app agents and spaces through `herdr-app do`, so they work without focusing the app. See `docs/herdr.md`.

**Typing text:** "say <words>" types the words using numen's own Vosk transcription, and
"snake say", "camel say", "title say"... type them formatted (`voice.phrases`). If the whole
transcript is a single filler word (the, a, an, uh, um, huh, hmm, ah, oh, and), nothing is
typed: that's what Vosk makes of noise when a transcribe phrase is triggered by accident.
Longer dictation is Voxtype ("dictate", see below).

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

The Vosk `@transcribe` phrases ("say …", "snake say …" etc. in `voice.phrases`) still type
short text through numen itself.

## Files

| File | What |
|---|---|
| `modules/home/app-numen.nix` | services, `numen-mode`, sleep/dictating phrase files, desktop entry |
| `modules/home/numen-tray.py` | tray icon |
| `dotfiles/.config/numen/phrases/` | numen voice commands |
| `dotfiles/.config/numen/sleep-filler.words` | extra decoy words for sleep and dictating modes |
| `dotfiles/.config/niri/config.kdl` | Mod+D (dictation) and Mod+Delete (on/off) bindings |
| `pkgs/numen.nix` | builds numen from `numen-src`, applies the local fixes below |
| `pkgs/numen-unk.patch` | `[unk]` noise rejection and timestamped phrase log (see below) |
| `$XDG_RUNTIME_DIR/numen-phrases.log` | what numen matched, ran or ignored, with times; recreated each time numen starts (`--phraselog` in the service) |

User services: `numen` (on demand) and `numen-tray` (at login); `voxtype` is in
`docs/dictation.md`.

## Local package fixes

`pkgs/numen.nix` changes upstream numen in two ways:

- **`numen-unk.patch`: noise rejection.** Numen limits Vosk's grammar to the words in your
  phrases, so stock numen maps any speech or noise onto the nearest command: random "say",
  arrow keys, letters. The patch adds `[unk]` to the grammar (`vox/vox.go`, in
  `NewRecognizer` and `SetGrm`), so speech that isn't a phrase comes out as `[unk]`. In
  `numen.go`, a result containing `[unk]` drops the whole utterance instead of trying Vosk's
  next alternative, unless a `@transcribe` phrase ("say", "snake say"...) matched first; dropped
  utterances are logged as `(ignored: ...)`. The patch also puts the time at the start of each
  `--phraselog` line. Limit: short filler sounds can still match short commands (in a test,
  "um yeah I guess so" still ran "gust" and "oh").
- **`postPatch`: filler-word filter.** A transcribe phrase triggered by noise transcribes that
  noise, which Vosk hears as "the". A rule added to `scripts/tweak` empties the transcript when
  it is one filler word (the, a, an, uh, um, huh, hmm, ah, oh, and), so nothing is typed.

If a `numen-src` update makes the patch fail, make it again: copy `numen.go` and `vox/` from the
new source, re-apply the changes, and `diff -ru` the two copies into `pkgs/numen-unk.patch`. If
`substituteInPlace` fails, upstream changed the `{ print; print line }` line in `scripts/tweak`.

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
- **Commands or words firing on their own:** see what numen matched or ignored, and when:
  `tail -f $XDG_RUNTIME_DIR/numen-phrases.log`. The `[unk]` patch catches most stray speech
  (see "Local package fixes"); a short phrase that keeps misfiring needs a longer name.
- **Ghost "the" typed:** a transcribe phrase ("say"...) was triggered by noise. The filler
  filter should stop it typing anything; if another word gets through, find it in the phrase
  log and add it to the filter in `pkgs/numen.nix`.
