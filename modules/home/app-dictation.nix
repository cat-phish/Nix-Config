{
  config,
  lib,
  pkgs,
  isNixos,
  ...
}:
# Dictation with Voxtype (Parakeet on CPU, typed with dotool). docs/dictation.md
#   hold Right Ctrl           push-to-talk: types when you let go
#   Mod+D                     start/stop (hands-free)
#   numen "dictate", "say"    start; stops after a pause (or "stop dictating")
# Numen keeps doing voice commands; while Voxtype records it only listens for
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
  #   dictate say FMT   numen "say" phrases (eval): types numen's own text if
  #                     you kept talking after "say", else records with
  #                     Voxtype until a pause, formatted by profile FMT
  # Voxtype's pre_recording_command puts numen in dictating mode and
  # post_output_command restores it (awake/asleep). numen-mode comes from
  # app-numen.nix via PATH.
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
        voxtype record start "$@" || { numen restore; exit 1; }
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
        say)
          # Output of `eval` is run by numen as actions, so keep it to the pen line.
          words="''${NUMEN_STATE_DIR:-/nonexistent}/transcripts"
          if grep -q '[^[:space:]]' "$words" 2>/dev/null; then
            echo 'pen /etc/numen/scripts/tweak; /etc/numen/scripts/transcripts | head -n 1'
          elif ! recording; then
            start --profile "''${2:-normal}" >/dev/null 2>&1 &
          fi
          ;;
        *) echo "usage: dictate [toggle|start|stop|cancel|say FMT]" >&2; exit 2 ;;
      esac
    '';
  };

  # Voxtype is still recording when you say "stop dictating", so it hears the
  # phrase too: drop it from the end of the text (empty output types nothing).
  # Then apply a numen "say" format (same names as numen's transcripts script):
  # code formats drop punctuation and case first.
  sayFormats = ["normal" "sentence" "title" "snake" "dash" "dot" "list" "path" "smash" "camel" "pascal" "dotcamel" "dotpascal"];
  voxtypeFormat = pkgs.writeShellScript "voxtype-format" ''
    PATH=${lib.makeBinPath [pkgs.gnused pkgs.gawk pkgs.coreutils]}
    text=$(sed -zE 's/[[:space:],]*\bstop dictat(ing|ion)[[:punct:]]*[[:space:]]*$//I')
    words() { printf '%s\n' "$text" | tr '[:upper:]' '[:lower:]' | sed -E "s/'//g; s/[^a-z0-9 ]+/ /g; s/ +/ /g; s/^ //; s/ $//"; }
    # $(...) drops the trailing newline, which would be typed as Enter.
    out=$(case "''${1:-normal}" in
      sentence) printf '%s\n' "$text" | awk '{print toupper(substr($0,1,1))substr($0,2)}' ;;
      title) printf '%s\n' "$text" | awk '{for(i=1; i<=NF; i++) $i = toupper(substr($i,1,1))substr($i,2); print}' ;;
      snake) words | sed 's/ /_/g' ;;
      dash) words | sed 's/ /-/g' ;;
      dot) words | sed 's/ /./g' ;;
      list) words | sed 's/ /, /g' ;;
      path) words | sed 's: :/:g' ;;
      smash) words | sed 's/ //g' ;;
      camel) words | awk '{for(i=1; i<=NF; i++) printf "%s", (i == 1 ? $i : toupper(substr($i,1,1))substr($i,2)); print ""}' ;;
      pascal) words | awk '{for(i=1; i<=NF; i++) printf "%s", toupper(substr($i,1,1))substr($i,2); print ""}' ;;
      dotcamel) words | awk '{printf "%s.", $1; for(i=2; i<=NF; i++) printf "%s", (i == 2 ? $i : toupper(substr($i,1,1))substr($i,2)); print ""}' ;;
      dotpascal) words | awk '{printf "%s.", $1; for(i=2; i<=NF; i++) printf "%s", toupper(substr($i,1,1))substr($i,2); print ""}' ;;
      *) printf '%s' "$text" ;;
    esac)
    printf '%s' "$out"
  '';

  voxtypeConfig = (pkgs.formats.toml {}).generate "voxtype-config.toml" {
    engine = "parakeet";
    state_file = "auto"; # needed by `voxtype record toggle` / `voxtype status`
    # Push-to-talk. Voxtype reads the key with evdev (user is in `input`);
    # the key still reaches apps. Mod+D and numen call `dictate` instead.
    hotkey = {
      enabled = true;
      key = "RIGHTCTRL";
      mode = "push_to_talk";
    };
    audio = {
      device = "default";
      sample_rate = 16000;
      max_duration_secs = 600; # default 60
      # Beeps at start and stop.
      feedback = {
        enabled = true;
        theme = "subtle";
      };
      # Only `voxtype record start` (Mod+D, numen): stop after a pause.
      # Push-to-talk ignores it.
      external_trigger_silence_timeout_secs = 2.0;
    };
    # Drop silent recordings (e.g. Right Ctrl used for Ctrl+C).
    vad.enabled = true;
    # Waveform panel while recording. The gtk4 frontend isn't built by
    # nixpkgs; the Quickshell one uses DMS's qs and the QML from the source
    # (VOXTYPE_OSD_QML_PATH in the service).
    osd = {
      enabled = true;
      frontend = "quickshell";
    };
    profiles = lib.genAttrs sayFormats (f: {post_process_command = "${voxtypeFormat} ${f}";});
    parakeet = {
      model = voxtypeModel;
      on_demand_loading = false; # keep it loaded: no wait at start
    };
    output = {
      mode = "type";
      driver_order = ["dotool" "wtype" "clipboard"];
      fallback_to_clipboard = true;
      type_delay_ms = 0;
      # Numen only listens for "stop dictating" while recording, then goes back.
      pre_recording_command = "numen-mode dictating";
      post_output_command = "numen-mode restore";
      post_process = {
        command = "${voxtypeFormat}";
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
      Environment =
        ["VOXTYPE_OSD_QML_PATH=${voxtype.src}/quickshell"]
        ++ lib.optional (!isNixos) "ALSA_PLUGIN_DIR=${pkgs.pipewire}/lib/alsa-lib";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
