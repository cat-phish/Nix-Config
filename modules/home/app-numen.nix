{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: let
  # Whisper-based dictation, a higher-accuracy alternative to numen's Vosk
  # @transcribe. Numen stays in charge of commands; this handles prose.
  #
  #   numen-dictate auto    record until ~1.5s of silence, then type (numen phrase)
  #   numen-dictate toggle  start recording; run again to stop and type (keybind)
  #
  # Numen is paused (`load` with no files) while recording so the dictated
  # prose isn't also run as commands, then resumed with $NUMEN_PHRASES.
  # Typing goes through dotoolc if dotoold is running, else dotool.
  numen-dictate = pkgs.writeShellApplication {
    name = "numen-dictate";
    runtimeInputs = with pkgs; [sox whisper-cpp libnotify coreutils procps gnused];
    # numenc/dotool/dotoolc come from the system PATH (built from source,
    # with the uinput udev rules).
    text = ''
      MODEL="''${WHISPER_MODEL:-$HOME/.local/share/whisper/ggml-small.en.bin}"
      MODEL_NAME="''${WHISPER_MODEL_NAME:-small.en}"
      SILENCE_SECS="''${DICTATE_SILENCE:-1.5}"
      THRESHOLD="''${DICTATE_THRESHOLD:-2%}"
      RUNDIR="''${XDG_RUNTIME_DIR:-/tmp}/numen-dictate"
      AUDIO="$RUNDIR/dictation.wav"
      PIDFILE="$RUNDIR/rec.pid"
      mkdir -p "$RUNDIR"

      notify() { notify-send -a Dictation -t 2000 "Dictation" "$1" || true; }

      numen_running() { pgrep -x numen >/dev/null; }
      numen_pause() { if numen_running; then echo load | numenc || true; fi; }
      numen_resume() {
        if numen_running; then
          # shellcheck disable=SC2086
          echo "load ''${NUMEN_PHRASES:-$(echo "$HOME"/.config/numen/phrases/*.phrases)}" | numenc || true
        fi
      }

      ensure_model() {
        [ -f "$MODEL" ] && return
        notify "Downloading Whisper model $MODEL_NAME (one time)..."
        mkdir -p "$(dirname "$MODEL")"
        whisper-cpp-download-ggml-model "$MODEL_NAME" "$(dirname "$MODEL")" >/dev/null \
          || { notify "Model download failed"; exit 1; }
      }

      record_args=(-q -c 1 -r 16000 -b 16 -e signed-integer "$AUDIO")

      transcribe_and_type() {
        notify "Processing..."
        local text
        text=$(whisper-cli -m "$MODEL" -f "$AUDIO" -nt -np -t "$(nproc)" 2>/dev/null \
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
          # Wait for 0.1s above threshold to start, stop after SILENCE_SECS below it.
          # Hard cap of 2 minutes per utterance.
          timeout -s INT 120 rec "''${record_args[@]}" \
            silence 1 0.1 "$THRESHOLD" 1 "$SILENCE_SECS" "$THRESHOLD" || true
          if [ -s "$AUDIO" ]; then transcribe_and_type; else notify "No speech detected."; fi
          ;;
        toggle)
          if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
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

  home.packages = [numen-dictate];

  home.file = {
    ".config/numen/phrases" = {
      source = ../../dotfiles/.config/numen/phrases;
      recursive = true;
    };
  };
}
