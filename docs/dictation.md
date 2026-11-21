# Dictation (Voxtype and Handy trial)

Numen does voice **commands** (see `docs/numen.md`). For **dictation** we're trying two
maintained Linux tools next to the old `numen-dictate`, to pick the one to keep.

Everything is in `modules/home/app-dictation.nix`, imported by `modules/home/common.nix`.

## Keys

| Key | Tool | Notes |
|---|---|---|
| **Mod+D** | Voxtype | Parakeet TDT 0.6B v3 (int8) on CPU, typed with dotool |
| **Mod+Ctrl+D** | Handy | model and options set in Handy's own window |
| **Mod+Alt+D** | `numen-dictate toggle` | the old asr4all setup, kept for comparison |

Press once to start, again to stop. The text is typed after you stop. Pressing one tool's key
while the other is recording stops that one first. `dictate` pauses numen while you talk, so
your words aren't run as commands, then restores whatever mode it was in (awake or asleep).

From a terminal: `dictate voxtype`, `dictate handy`.

## Why not numen-dictate

- **"say …"** starts only after numen's Vosk finishes hearing you, which is after you stop
  talking. It then reads the audio back from a 30 s buffer, so long dictations lose their start.
- **asr4all streaming** loads the model on every run (about 1.7 s), and redraws the whole
  transcript every 320 ms, so it gets slower the longer you talk. Recordings are cut off at
  120 s.

## Voxtype

- Daemon: the `voxtype` user service, which keeps the model loaded. Log:
  `journalctl --user -fu voxtype`.
- Config: generated from `voxtypeConfig` in `app-dictation.nix` into
  `~/.config/voxtype/config.toml`. Because the file is read-only, `voxtype config set` and the
  `voxtype configure` TUI can't save. Edit the Nix file instead, then check the result with
  `voxtype config`. Valid keys: `voxtype config schema`.
- Model: downloaded by a Home Manager activation step to `~/.local/share/voxtype/models/` on
  the first switch. To switch models, change `voxtypeModel` (see `voxtype info models`). Whisper
  instead needs `engine = "whisper"` plus a `whisper.model`.
- Recordings stop at `audio.max_duration_secs` (600).
- The nixpkgs build has no `parakeet.streaming`, so text can't appear while you're still
  talking.
- `voxtype status` shows idle / recording / transcribing.

## Handy

- App: the `handy` user service (`handy --start-hidden`), with a tray icon. Open the window
  from the tray to change settings.
- Its settings are stored by Handy itself and aren't tracked in this repo. Set these once on
  each machine:
  - Model: **Parakeet V3** (recommended, fast on CPU)
  - Advanced → Paste Method: direct typing (dotool), or leave it on clipboard if typing misbehaves
  - Turn off Handy's own shortcut: niri's Mod+Ctrl+D runs `handy --toggle-transcription`
- If the window fails with "Failed to create surface": `nix-gpu-setup`.

## Comparing

Read the same ~90 s passage into a text editor with Mod+D, Mod+Ctrl+D and Mod+Alt+D. For each,
note:

- the wait between stopping and the text appearing
- whether the start or end was lost
- word errors, punctuation and capitals

Then keep the winner on Mod+D, remove the other tool from `app-dictation.nix`, and decide
whether to remove the asr4all/whisper dictation code and `numen-dictate-buffer` from
`app-numen.nix`, or point numen's "say" phrase at the winner.
