# Dictation (Voxtype)

Numen does voice **commands** (see `docs/numen.md`). **Dictation** (typing prose) is
[Voxtype](https://github.com/peteonrails/voxtype). It runs NVIDIA's Parakeet TDT 0.6B v3 (int8)
on the CPU and types with dotool.

Everything is in `modules/home/app-dictation.nix`, imported by `modules/home/common.nix`.

## Using it

| Start | Stop and type |
|---|---|
| **hold F9** | let go (push-to-talk) |
| **Mod+D** | a 2 s pause, or **Mod+D** |
| say **"dictate"** (numen running), wait for the panel | a 2 s pause, or say **"stop dictating"** |

Any start works with any stop. A beep plays at start and stop, and a waveform panel shows at
the bottom of the screen while recording. The text is typed about half a second after you stop.
A recording stops by itself after 10 minutes and types what it has. Filler words (uh, um...)
are dropped, and recordings with no speech (an accidental F9 tap) are thrown away.

The 2 s pause stop only applies to recordings started with Mod+D or by voice
(`external_trigger_silence_timeout_secs`); push-to-talk records until you let go.

While Voxtype records, numen listens only for "stop dictating", so your words aren't run as
commands. Afterwards it goes back to whatever mode it was in (awake or asleep). "Stop dictating"
is removed from the end of the text, since Voxtype hears it too.

### Numen "dictate"

Numen only acts once you pause, so say "dictate", wait for the panel, then talk. Words said
straight after "dictate", before the panel shows, go to numen as commands.

"Say" used to start Voxtype too, but numen's Vosk grammar snapped stray sounds to that one
short word and opened the panel at random. "Say <words>" and the formatted phrases ("snake
say", "camel say"...) use numen's own transcription (Vosk).

From a terminal:

```sh
dictate            # start, or stop if recording (Mod+D)
dictate start      # start (numen "dictate")
dictate stop       # stop and type (numen "stop dictating")
dictate cancel     # stop without typing
voxtype status     # idle / recording / transcribing
journalctl --user -fu voxtype
```

## How it fits together

- **`voxtype` user service.** Started at login. It keeps the model loaded, so there's no wait
  at start.
- **Push-to-talk.** Voxtype's own evdev hotkey (`hotkey.key = "F9"`), which needs the
  user in the `input` group. The key still reaches apps.
- **`dictate`.** Starts and stops recording with `voxtype record start|stop`. Voxtype's
  `pre_recording_command` runs `numen-mode dictating` and `post_output_command` runs
  `numen-mode restore`, for every kind of recording.
- **Feedback.** `audio.feedback` (beeps) and the Quickshell OSD. nixpkgs doesn't build the gtk4
  OSD or install the QML, so the service sets `VOXTYPE_OSD_QML_PATH` to the `quickshell/`
  folder of Voxtype's source; `qs` comes from DMS.
- **`numen-mode dictating`.** Loads `~/.config/numen/dictating.phrases`. Like sleep mode, it is
  generated in `app-numen.nix`: the one real phrase ("stop dictating"), padded with do-nothing
  decoy words so other speech doesn't trigger it.
- **Config.** Generated from `voxtypeConfig` in `app-dictation.nix` into
  `~/.config/voxtype/config.toml`. Because the file is read-only, `voxtype config set` and the
  `voxtype configure` TUI can't save; edit the Nix file instead. Check the result with
  `voxtype config`. Valid keys: `voxtype config schema`.
- **Model.** Downloaded by a Home Manager activation step to `~/.local/share/voxtype/models/` on
  the first switch. To change models, edit `voxtypeModel` (see `voxtype info models`). Whisper
  instead needs `engine = "whisper"` plus `whisper.model`.

## Local package fixes

The nixpkgs package is overridden in `app-dictation.nix`:

- **`onnxSupport = true`.** nixpkgs builds Whisper only by default, and Parakeet needs ONNX.
- **Extra `sqlite` and `oniguruma` build inputs.** Our nixpkgs pin fails to link without them.
  Newer nixpkgs has the fix, so drop them after a flake update.
- **`ALSA_PLUGIN_DIR` on Fedora.** Without it, Nix alsa-lib can't load dnf's PipeWire plugin and
  recording fails with `snd_pcm_open` errors.

Because of the overrides, Voxtype is compiled from source (about 10 minutes). The Rust build can
run a laptop out of memory; if it gets killed, build with `--max-jobs 1 --cores 4`.

The nixpkgs build has no `parakeet.streaming`, so text can't appear while you're still talking.

## Why not the old numen-dictate

Until Nov 2026, dictation was `numen-dictate`, with FUTO asr4all streaming or whisper.cpp,
plus a 30 s mic buffer for numen's "say …". Problems:

- "say" only started after numen's Vosk finished hearing you, so long dictations lost their
  start, and nothing was typed until the end.
- asr4all loaded its model on every run and redrew the whole transcript every 320 ms, so it got
  slower the longer you talked.
- Recordings were cut off at 120 s.

Handy was also tried; it worked as well as Voxtype, but its settings live in its own GUI, not in
this repo. The old code is in git history (removed in the commit that added this section).

## Troubleshooting

- **No waveform panel.** Check the log for "could not find 'shell.qml'" or OSD child exits.
- **F9 does nothing.** `id -nG` must list `input` (log out and in after adding it).
- **Say/dictate stops while you're still talking**, or never stops: tune
  `my.dictation.speechThresholdDbfs` (Voxtype's `audio.external_trigger_speech_threshold_dbfs`).
  Lower it if it cuts you off, raise it if it never stops. Set it per host in
  `hosts/<host>-home.nix`. The threshold has to sit above that mic's room noise and below speech:
  - **Default -38** (desktop). Voxtype's own default, -20, was louder than the desktop mic, so
    every recording stopped after 2 s. Desktop noise floor is about -53, room noise up to -34.
  - **fedora-laptop -15.** The X1 Carbon's digital mic runs a DSP compressor
    (`Dmic0 Capture DRC`, on), which lifts a quiet room to 100 ms peaks of -28 median and
    -20 max (RMS -35). That was above -38, so recordings never stopped by themselves.

  To measure a mic, stay quiet for 5 s with
  `pw-record --rate 16000 --channels 1 --format s16 /tmp/noise.wav` and look at the peak levels.
  Pick a threshold a few dB above the loudest noise.
- **Nothing happens on Mod+D.** Run `systemctl --user status voxtype` and check the log.
  "Failed to start audio" means the ALSA plugin fix above is missing.
- **Panel flashes up for a moment on its own.** Something ran `dictate start`: the voxtype log
  (`journalctl --user -u voxtype`) shows "Recording started (external trigger)" then "No speech
  detected". Usually numen matched a dictation phrase from noise; check
  `$XDG_RUNTIME_DIR/numen-phrases.log` at that time. This is why "say" no longer starts Voxtype
  and only "dictate" does.
- **Numen ignores commands after dictating.** Run `numen-mode restore`, or `numen-mode wake`.
- **"Stop dictating" isn't recognised.** Use Mod+D. Check numen's log
  (`journalctl --user -u numen`) for unknown-word warnings when the dictating phrases load.
