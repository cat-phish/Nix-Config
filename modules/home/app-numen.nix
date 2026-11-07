{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: let
  # Whisper models, fetched by Nix (pinned by hash). base.en is ~2-3x faster
  # than small.en on this hardware with slightly lower accuracy; tiny.en is
  # faster still but noticeably sloppier. Override per run with WHISPER_MODEL.
  whisperModels = lib.mapAttrs (name: hash:
    pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${name}.bin";
      inherit hash;
    }) {
    "tiny.en" = "sha256-kh5M+Ghv3Zk9zQgaXaW2w2W/3hFi5ysI11rHUomSCx8=";
    "base.en" = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
    "small.en" = "sha256-xhONbVjsyDIgl+D5h8MvG+i7ChhTKj+I9zTRu/nEHl0=";
  };
  whisperModel = whisperModels."base.en";

  # Talon-style sleep mode. Numen's own pause (`load` with no files) can't be
  # undone by voice, so "sleep" instead loads sleep.phrases, which only
  # contains the wake phrase. State is a flag file so other scripts (e.g.
  # numen-dictate) restore the right mode after temporarily pausing numen.
  #
  #   numen-mode sleep|wake|toggle  switch mode (with a notification)
  #   numen-mode pause              load nothing (used while dictating)
  #   numen-mode restore            reload whatever the current mode is
  #   numen-mode status             print "awake" or "asleep"
  numen-mode = pkgs.writeShellApplication {
    name = "numen-mode";
    runtimeInputs = with pkgs; [libnotify coreutils procps];
    text = ''
      FLAG="''${XDG_RUNTIME_DIR:-/tmp}/numen-asleep"
      SLEEP_FILE="$HOME/.config/numen/sleep.phrases"

      numen_load() {
        pgrep -x numen >/dev/null || return 0
        echo "load $*" | numenc || true
      }
      load_awake() {
        # shellcheck disable=SC2086
        numen_load ''${NUMEN_PHRASES:-"$HOME"/.config/numen/phrases/*.phrases}
      }
      notify() { (notify-send -a Numen -t 1500 "Numen" "$1" || true) & }

      case "''${1:-status}" in
        sleep) touch "$FLAG"; numen_load "$SLEEP_FILE"; notify "Asleep (say \"wake up\")" ;;
        wake) rm -f "$FLAG"; load_awake; notify "Awake" ;;
        toggle) if [ -f "$FLAG" ]; then "$0" wake; else "$0" sleep; fi ;;
        pause) numen_load ;;
        restore) if [ -f "$FLAG" ]; then numen_load "$SLEEP_FILE"; else load_awake; fi ;;
        status) if [ -f "$FLAG" ]; then echo asleep; else echo awake; fi ;;
        *) echo "usage: numen-mode [sleep|wake|toggle|pause|restore|status]" >&2; exit 2 ;;
      esac
    '';
  };

  # Whisper-based dictation, a higher-accuracy alternative to numen's Vosk
  # @transcribe. Numen stays in charge of commands; this handles prose.
  #
  #   numen-dictate auto    record until ~1s of silence, then type (numen phrase)
  #   numen-dictate toggle  start recording; run again to stop and type (keybind)
  #
  # Numen is paused while recording so the dictated prose isn't also run as
  # commands, then restored to its previous mode (awake/asleep) via numen-mode.
  # Typing goes through dotoolc if dotoold is running, else dotool.
  numen-dictate = pkgs.writeShellApplication {
    name = "numen-dictate";
    # Vulkan build: ~2-3x faster on the Intel iGPU than CPU; falls back to CPU
    # if no Vulkan device is found.
    runtimeInputs = with pkgs; [numen-mode sox whisper-cpp-vulkan libnotify coreutils procps gnused gawk];
    # numenc/dotool/dotoolc come from the system PATH (built from source,
    # with the uinput udev rules).
    text = ''
      MODEL="''${WHISPER_MODEL:-${whisperModel}}"
      SILENCE_SECS="''${DICTATE_SILENCE:-1.0}"
      THRESHOLD="''${DICTATE_THRESHOLD:-3%}"
      THREADS="''${WHISPER_THREADS:-4}" # more threads is slower on hybrid P/E-core CPUs
      RUNDIR="''${XDG_RUNTIME_DIR:-/tmp}/numen-dictate"
      AUDIO="$RUNDIR/dictation.wav"
      PIDFILE="$RUNDIR/rec.pid"
      AUTOPID="$RUNDIR/auto.pid"
      mkdir -p "$RUNDIR"

      # Backgrounded so the notification never delays recording/typing.
      notify() { (notify-send -a Dictation -t 2000 "Dictation" "$1" || true) & }

      numen_pause() { numen-mode pause; }
      numen_resume() { numen-mode restore; }

      ensure_model() {
        [ -f "$MODEL" ] || { notify "Whisper model not found: $MODEL"; exit 1; }
      }

      record_args=(-q -c 1 -r 16000 -b 16 -e signed-integer "$AUDIO")

      transcribe_and_type() {
        notify "Processing..."
        local text ac
        # Encode only as much audio context as the clip needs (50 frames/s,
        # 1500 = full 30s window) instead of always padding to 30s. Greedy
        # decoding (-bs 1 -bo 1) instead of 5-way beam search.
        ac=$(soxi -D "$AUDIO" | awk '{a=int($1*50)+128; if(a<384)a=384; if(a>1500)a=0; print a}')
        text=$(whisper-cli -m "$MODEL" -f "$AUDIO" -nt -np -t "$THREADS" -bs 1 -bo 1 -ac "$ac" 2>/dev/null \
          | sed -E 's/\[[^]]*\]//g; s/\((music|silence|inaudible|blank_audio)[^)]*\)//Ig' \
          | tr '\n' ' ' | tr -s '[:space:]' ' ' | sed -E 's/^ +| +$//g')
        rm -f "$AUDIO"
        if [ -z "$text" ]; then
          notify "No speech detected."
          return
        fi
        if pgrep -x dotoold >/dev/null; then
          printf 'type %s\n' "$text" | dotoolc
        else
          printf 'type %s\n' "$text" | dotool
        fi
      }

      case "''${1:-auto}" in
        auto)
          ensure_model
          numen_pause
          trap numen_resume EXIT
          notify "Listening... (pause ''${SILENCE_SECS}s to finish)"
          # highpass drops fan/hum rumble so it doesn't hold the recording open.
          # Wait for 0.1s above threshold to start, stop after SILENCE_SECS below it,
          # cap at 2 minutes. `numen-dictate toggle` (Mod+D) stops it early.
          rec "''${record_args[@]}" highpass 100 \
            silence 1 0.1 "$THRESHOLD" 1 "$SILENCE_SECS" "$THRESHOLD" trim 0 120 &
          echo $! >"$AUTOPID"
          wait $! || true
          rm -f "$AUTOPID"
          if [ -s "$AUDIO" ]; then transcribe_and_type; else notify "No speech detected."; fi
          ;;
        toggle)
          if [ -f "$AUTOPID" ] && kill -0 "$(cat "$AUTOPID")" 2>/dev/null; then
            # An auto recording is hanging: stop it; the auto run transcribes.
            kill -INT "$(cat "$AUTOPID")"
          elif [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            kill -INT "$(cat "$PIDFILE")"
            while kill -0 "$(cat "$PIDFILE")" 2>/dev/null; do sleep 0.05; done
            rm -f "$PIDFILE"
            transcribe_and_type
            numen_resume
          else
            ensure_model
            numen_pause
            rm -f "$AUDIO"
            rec "''${record_args[@]}" &
            echo $! >"$PIDFILE"
            notify "Listening... run again to type."
          fi
          ;;
        *)
          echo "usage: numen-dictate [auto|toggle]" >&2
          exit 2
          ;;
      esac
    '';
  };
in {
  imports = [
  ];

  home.packages = [numen-mode numen-dictate];

  home.file = {
    ".config/numen/phrases" = {
      source = ../../dotfiles/.config/numen/phrases;
      recursive = true;
    };
    # Outside phrases/ so the *.phrases glob for awake mode doesn't include it.
    ".config/numen/sleep.phrases".source = ../../dotfiles/.config/numen/sleep.phrases;
  };
}
