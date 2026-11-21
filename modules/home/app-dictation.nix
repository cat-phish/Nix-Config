{
  config,
  lib,
  pkgs,
  ...
}:
# Dictation tools on trial alongside numen-dictate (docs/dictation.md).
#   Mod+D       Voxtype (Parakeet, types with dotool)
#   Mod+Ctrl+D  Handy   (configured in its own GUI)
#   Mod+Alt+D   the old numen-dictate (asr4all)
# Numen keeps doing voice commands; `dictate` pauses it while you talk.
let
  # onnxSupport: Parakeet/Moonshine (off by default in nixpkgs, Whisper only).
  # sqlite/oniguruma: our nixpkgs pin links them without listing them ("cannot
  # find -lsqlite3"); newer nixpkgs has the fix, drop them after a flake update.
  voxtype = (pkgs.voxtype.override {onnxSupport = true;}).overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [pkgs.sqlite pkgs.oniguruma];
  });
  handy = pkgs.handy;
  voxtypeModel = "parakeet-tdt-0.6b-v3-int8";

  # dictate voxtype|handy: start dictating with that tool, or stop if it's
  # already recording (pressing the other tool's key stops this one first).
  # numen is paused at start and restored at stop, so you can talk freely.
  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = [voxtype handy pkgs.coreutils pkgs.libnotify];
    # numen-mode comes from app-numen.nix (on PATH via the HM profile).
    text = ''
      RUNDIR="''${XDG_RUNTIME_DIR:-/tmp}/dictate"
      STATE="$RUNDIR/active" # holds the tool that is recording
      mkdir -p "$RUNDIR"

      notify() { (notify-send -a Dictation -t 1500 "Dictation" "$1" || true) & }
      pause_numen() { command -v numen-mode >/dev/null && numen-mode pause || true; }
      restore_numen() { command -v numen-mode >/dev/null && numen-mode restore || true; }

      start() {
        case "$1" in
          voxtype) voxtype record start ;;
          handy) handy --toggle-transcription ;;
        esac
      }
      stop() {
        case "$1" in
          voxtype) voxtype record stop ;;
          handy) handy --toggle-transcription ;;
        esac
      }

      tool="''${1:-voxtype}"
      case "$tool" in
        voxtype | handy) ;;
        *) echo "usage: dictate [voxtype|handy]" >&2; exit 2 ;;
      esac

      active=$(cat "$STATE" 2>/dev/null || true)
      # Voxtype stops by itself at max_duration_secs: forget a stale state.
      if [ "$active" = voxtype ] && [ "$(voxtype status 2>/dev/null)" != recording ]; then
        rm -f "$STATE"
        restore_numen
        active=""
      fi

      if [ -n "$active" ]; then
        stop "$active"
        rm -f "$STATE"
        restore_numen
        [ "$active" = "$tool" ] && exit 0
      fi

      pause_numen
      if start "$tool"; then
        echo "$tool" >"$STATE"
      else
        restore_numen
        notify "$tool isn't running (systemctl --user status $tool)"
        exit 1
      fi
    '';
  };

  voxtypeConfig = (pkgs.formats.toml {}).generate "voxtype-config.toml" {
    engine = "parakeet";
    state_file = "auto"; # needed by `voxtype record toggle` / `voxtype status`
    hotkey.enabled = false; # niri binds call `dictate`
    audio = {
      device = "default";
      sample_rate = 16000;
      max_duration_secs = 600; # default 60
    };
    parakeet = {
      model = voxtypeModel;
      on_demand_loading = false; # keep it loaded: no wait at start
    };
    output = {
      mode = "type";
      driver_order = ["dotool" "wtype" "clipboard"];
      fallback_to_clipboard = true;
      type_delay_ms = 0;
      notification = {
        on_recording_start = false;
        on_recording_stop = false;
        on_transcription = false;
        on_no_speech = true;
      };
    };
    text.filter_filler_words = true;
  };
in {
  home.packages = [voxtype handy dictate];

  # Linked out of the store would block `voxtype config set`/the TUI; that's
  # fine: edit it here. Validate with `voxtype config`.
  xdg.configFile."voxtype/config.toml".source = voxtypeConfig;

  # Download the model once (~640 MB, into ~/.local/share/voxtype/models).
  home.activation.voxtypeModel = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -e "${config.xdg.dataHome}/voxtype/models/${voxtypeModel}" ]; then
      echo "voxtype: downloading ${voxtypeModel}..."
      run ${voxtype}/bin/voxtype setup --download --model ${voxtypeModel} --quiet \
        || echo "voxtype: model download failed; run: voxtype setup --download --model ${voxtypeModel}"
    fi
  '';

  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype dictation daemon";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target" "pipewire-pulse.service"];
      X-Restart-Triggers = ["${voxtypeConfig}"];
    };
    Service = {
      # Text is typed after you stop: nixpkgs builds voxtype without
      # parakeet.streaming (live typing). Parakeet int8 on CPU is quick anyway.
      ExecStart = "${voxtype}/bin/voxtype daemon";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # Handy keeps its settings in its own GUI store (not tracked here).
  systemd.user.services.handy = {
    Unit = {
      Description = "Handy dictation";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target" "dms.service" "pipewire-pulse.service"];
    };
    Service = {
      ExecStart = "${handy}/bin/handy --start-hidden";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
