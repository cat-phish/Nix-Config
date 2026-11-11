# Numen voice control and dictation

Numen handles voice **commands** (Vosk, phrase files in `dotfiles/.config/numen/phrases/`).
**Dictation** (typing prose) is a separate tool, `numen-dictate`, that streams speech through
FUTO's asr4all model by default, or Whisper if you switch engines.

Everything is in `modules/home/app-numen.nix`, imported by `modules/home/common.nix`, so every
host gets it (fedora-desktop and fedora-laptop included).

## Contents

1. [Starting and stopping](#starting-and-stopping)
2. [Voice commands](#voice-commands)
3. [Dictation](#dictation)
4. [Switching dictation models](#switching-dictation-models)
5. [Filler words](#filler-words)
6. [Comparing models on your voice](#comparing-models-on-your-voice)
7. [Files](#files)
8. [Setting up a new machine](#setting-up-a-new-machine)
9. [Troubleshooting](#troubleshooting)

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
numen-mode status    # awake / asleep
journalctl --user -fu numen   # numen's log (also "Show log" in the tray)
```

A numen started by hand in a terminal is detected too; the tray shows it and can stop it.

## Voice commands

Phrase files: `dotfiles/.config/numen/phrases/*.phrases`. A few that control numen itself:

| Say | Does |
|---|---|
| `sleep` | sleep mode: ignore everything except "wake up" |
| `wake up` | back to normal |
| `newman off` | stop numen (say it like "numen off"; "numen" isn't in Vosk's vocabulary) |

Sleep mode loads `~/.config/numen/sleep.phrases`, which is generated at build time from
`dotfiles/.config/numen/sleep-filler.words` plus every word in the phrase files, so random
speech doesn't wake it.

## Dictation

| How | What happens |
|---|---|
| **Mod+D** | start dictating; Mod+D again to stop |
| say **"say ..."** (numen running) | types what you say after "say"; stops after ~1 s of silence |
| `numen-dictate auto` | dictate from now until ~1 s of silence |

Numen is paused while you dictate so your words aren't also run as commands, then restored to
whatever mode it was in (awake or asleep).

With the default asr4all engine, text is typed **while you talk**, about 1–1.5 s behind,
with punctuation and capitals. The last word is held back until the next one starts, and small
corrections ("meet" → "meeting", a moved period) are made with a few backspaces. The model takes
~1.7 s to load at each start; audio is buffered meanwhile, so nothing is lost, but the first words
appear a little late.

Tuning (environment variables, per run): `DICTATE_SILENCE` (seconds of quiet that end a
dictation, default 1.0), `DICTATE_THRESHOLD` (speech level, default `3%`),
`ASR4ALL_THREADS` / `WHISPER_THREADS` (default 4; more is slower on hybrid P/E-core CPUs).

## Switching dictation models

The engine and models are Home Manager options. Set them in a host file
(`hosts/<host>-home.nix`) to change one machine, or change the defaults in
`modules/home/app-numen.nix` to change all of them, then switch:

```nix
# hosts/fedora-desktop-home.nix
my.numen.dictation = {
  engine = "asr4all";            # "asr4all" (streams while you talk) or "whisper" (types after you stop)
  asr4allSize = "m";             # "s" (28M), "m" (56M), "l" (97M)
  asr4allTier = "stream_c16r4";  # latency tier, see below
  whisperModel = "base.en";      # "tiny.en", "base.en", "small.en" (used when engine = "whisper")
};
```

| Option | Default | Choices |
|---|---|---|
| `engine` | `asr4all` | `asr4all`, `whisper` |
| `asr4allSize` | `m` | `s`, `m`, `l` |
| `asr4allTier` | `stream_c16r4` | `stream_c16r4` (~1.5 s behind), `stream_c32r8` (~3 s), `stream_c64r16` (~6 s), `stream_c128r24`, `stream_c256r32`, `stream_c512r8` |
| `whisperModel` | `base.en` | `tiny.en`, `base.en`, `small.en` |
| `bench` | `false` | install `numen-asr-bench` (below) |

Only the selected models are downloaded. All are pinned by hash (asr4all to a Hugging Face commit),
so a new model version means updating the `rev`/`hash` in `asr4allModels` or `whisperModels`.

To try another engine or model for **one run** without switching:

```sh
DICTATE_ENGINE=whisper numen-dictate auto
WHISPER_MODEL=/path/to/ggml-small.en.bin DICTATE_ENGINE=whisper numen-dictate auto
ASR4ALL_TIER=stream_c32r8 numen-dictate auto
```

Benchmark on fedora-laptop (Core Ultra 7 155U, 7 read sentences, Nov 2026):

| Model | Word errors | Wait after you stop | Text appears |
|---|---|---|---|
| whisper base.en | 3.6% | 0.5 s | after you stop |
| whisper small.en | 3.6% | 1.0 s | after you stop |
| asr4all-m c16r4 (default) | 6.0% | 0.2 s | ~1.6 s behind speech |
| asr4all-m c64r16 | 3.6% | 0.3 s | ~6 s behind speech |

## Filler words

Dictation drops filler words before typing: **uh, uhh, um, umm, uhm, erm**. "Ah", "hmm" and "er"
are kept, since you might mean them. Capitals and punctuation are fixed up around the removed word:
"Uh, this works" types "This works", and "I was, um, thinking" types "I was thinking". A comma right
before a filler goes too ("more coffee, um, soon" → "more coffee soon").

It works whenever the model writes the filler out as a word; it can't catch a filler the model
mistakes for a real word ("a", "and"). Applies to the asr4all engine.

To keep fillers for one run:

```sh
DICTATE_KEEP_FILLERS=1 numen-dictate auto
```

The list is `FILLERS` in `modules/home/numen-dictate-stream.py`.

## Comparing models on your voice

Enable `my.numen.dictation.bench = true;` (it downloads every model, ~1.2 GB), switch, then:

```sh
numen-asr-bench record   # read each sentence aloud: Enter to start, Enter to stop
numen-asr-bench run      # word error rate and timing for every whisper and asr4all model
```

Clips are saved to `~/.local/state/numen/bench/`; the sentences are in
`modules/home/numen-asr-bench.sentences`.

## Files

| File | What |
|---|---|
| `modules/home/app-numen.nix` | options, models, services, `numen-mode`, `numen-dictate`, desktop entry |
| `modules/home/numen-tray.py` | tray icon |
| `modules/home/numen-dictate-stream.py` | asr4all streaming dictation: decodes and types |
| `modules/home/numen-dictate-buffer.py` | always-on 30 s mic buffer, so "say" catches speech that started before numen recognised it |
| `modules/home/numen-asr-bench.py` | model comparison |
| `dotfiles/.config/numen/phrases/` | numen voice commands |
| `dotfiles/.config/niri/config.kdl` | Mod+D (dictation) and Mod+Delete (on/off) bindings |

User services: `numen` (on demand), `numen-tray` and `numen-dictate-buffer` (at login).

## Setting up a new machine

Home Manager installs everything above, but numen itself is not packaged by Nix yet (see the
backlog). On Fedora it needs, outside this repo:

- `numen` and `numenc` built from source (`~/.apps/source/numen`) into `/usr/local/bin`, with
  `/etc/numen/` (its scripts) and the Vosk model in `/usr/share/vosk-models/small-en-us`
- `dotool`, `dotoolc`, `dotoold` in `/usr/local/bin`, plus the uinput udev rule
  (`/etc/udev/rules.d/80-dotool.rules`) and your user in the `input` group

Then `home-manager switch --flake ~/.nix#jordan@<host>` and log out and back in (or
`systemctl --user start numen-tray numen-dictate-buffer`).

## Troubleshooting

- **Tray icon missing:** launch "Numen" from the launcher, or `systemctl --user start numen-tray`.
- **Numen shows "failed" after stopping:** expected. Numen often hangs while exiting, so the
  service kills it after 2 s, which systemd records as a failed stop. Starting it again works.
- **Started, but commands don't work yet:** wait for the icon to turn green (blue = still loading).
- **Dictation types nothing:** check `systemctl --user status numen-dictate-buffer` (needed for
  "say"), and that `dotool` works (`echo type hi | dotool`).
- **Dictation stops too early / never stops:** adjust `DICTATE_SILENCE` or `DICTATE_THRESHOLD`.
