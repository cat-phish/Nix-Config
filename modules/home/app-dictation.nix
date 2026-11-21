{
  config,
  lib,
  pkgs,
  isNixos,
  ...
}:
# Dictation with Voxtype (Parakeet on CPU, typed with dotool). docs/dictation.md
#   Mod+D, or say "dictate"   start; Mod+D or "stop dictating" to stop
# Numen keeps doing voice commands; while you dictate it only listens for
# "stop dictating" (numen-mode dictating, in app-numen.nix).
let
  # onnxSupport: Parakeet/Moonshine (off by default in nixpkgs, Whisper only).
  # sqlite/oniguruma: our nixpkgs pin links them without listing them ("cannot
  # find -lsqlite3"); newer nixpkgs has the fix, drop them after a flake update.
  voxtype = (pkgs.voxtype.override {onnxSupport = true;}).overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [pkgs.sqlite pkgs.oniguruma];
  });
  voxtypeModel = "parakeet-tdt-0.6b-v3-int8";

  #   dictate [toggle]  start, or stop if recording (Mod+D)
  #   dictate start     start (numen "dictate")
  #   dictate stop      stop and type (numen "stop dictating")
  #   dictate cancel    stop without typing
  # Numen goes into dictating mode at start and back to its previous mode
  # (awake/asleep) at stop. numen-mode comes from app-numen.nix via PATH.
  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = [voxtype pkgs.coreutils pkgs.libnotify];
    text = ''
      notify() { (notify-send -a Dictation -t 1500 "Dictation" "$1" || true) & }
      numen() { if command -v numen-mode >/dev/null; then numen-mode "$1" || true; fi; }
      recording() { [ "$(voxtype status 2>/dev/null)" = recording ]; }

      start() {
        if ! systemctl --user is-active --quiet voxtype; then
          notify "voxtype isn't running (systemctl --user status voxtype)"
          exit 1
        fi
        numen dictating
        voxtype record start || { numen restore; exit 1; }
      }
      stop() {
        voxtype record "$1" || true
        numen restore
      }

      case "''${1:-toggle}" in
        toggle) if recording; then stop stop; else start; fi ;;
        start) recording || start ;;
        stop) stop stop ;;
        cancel) stop cancel ;;
        *) echo "usage: dictate [toggle|start|stop|cancel]" >&2; exit 2 ;;
      esac
    '';
  };

  # Voxtype is still recording when you say "stop dictating", so it hears the
  # phrase too: drop it from the end of the text (empty output types nothing).
  stripStopPhrase = pkgs.writeShellScript "voxtype-strip-stop" ''
    ${pkgs.gnused}/bin/sed -zE 's/[[:space:],]*\bstop dictat(ing|ion)[[:punct:]]*[[:space:]]*$//I'
  '';

  voxtypeConfig = (pkgs.formats.toml {}).generate "voxtype-config.toml" {
    engine = "parakeet";
    state_file = "auto"; # needed by `voxtype record toggle` / `voxtype status`
    hotkey.enabled = false; # Mod+D and numen call `dictate`
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
      # After typing (also when it hits max_duration_secs): put numen back.
      post_output_command = "numen-mode restore";
      post_process = {
        command = "${stripStopPhrase}";
        timeout_ms = 2000;
        fallback_on_empty = false; # "stop dictating" alone types nothing
      };
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
  home.packages = [voxtype dictate];

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
      # Fedora: Nix alsa-lib can't find dnf's PipeWire ALSA plugin ("Cannot open
      # shared library libasound_module_pcm_pipewire.so"), so no mic.
      Environment = lib.mkIf (!isNixos) ["ALSA_PLUGIN_DIR=${pkgs.pipewire}/lib/alsa-lib"];
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
