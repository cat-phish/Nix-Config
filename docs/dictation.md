# Dictation (Voxtype)

Numen does voice **commands** (see `docs/numen.md`). **Dictation** (typing prose) is
[Voxtype](https://github.com/peteonrails/voxtype). It runs NVIDIA's Parakeet TDT 0.6B v3 (int8)
on the CPU and types with dotool.

Everything is in `modules/home/app-dictation.nix`, imported by `modules/home/common.nix`.

## Using it

| Start | Stop and type |
|---|---|
| **Mod+D** | **Mod+D** |
| say **"dictate"** (numen running) | say **"stop dictating"** |

Any start works with any stop. The text is typed about half a second after you stop. A recording
stops by itself after 10 minutes and types what it has. Filler words (uh, um...) are dropped.

While you dictate, numen listens only for "stop dictating", so your words aren't run as
commands. Afterwards it goes back to whatever mode it was in (awake or asleep). "Stop dictating"
is removed from the end of the text, since Voxtype hears it too.

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
- **`dictate`.** Starts and stops recording with `voxtype record start|stop`, and switches numen
  with `numen-mode dictating` / `numen-mode restore`. Voxtype's `post_output_command` also runs
  `numen-mode restore`, so numen comes back even when a recording ends on its own.
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

- **Nothing happens on Mod+D.** Run `systemctl --user status voxtype` and check the log.
  "Failed to start audio" means the ALSA plugin fix above is missing.
- **Numen ignores commands after dictating.** Run `numen-mode restore`, or `numen-mode wake`.
- **"Stop dictating" isn't recognised.** Use Mod+D. Check numen's log
  (`journalctl --user -u numen`) for unknown-word warnings when the dictating phrases load.
