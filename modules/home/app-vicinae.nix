{
  config,
  lib,
  pkgs,
  ...
}: let
  # Raycast extensions are built from a sparse checkout of github.com/raycast/extensions at this rev.
  # Vicinae's Raycast API coverage is partial: if one stops building or working, drop it here.
  raycastRev = "c12374ce5a5a26772418b1c3f624943eb8b9ec21";
  raycast = name: sha256: npmDepsHash:
    config.lib.vicinae.mkRayCastExtension {inherit name sha256 npmDepsHash; rev = raycastRev;};
in {
  # Vicinae: Raycast-style launcher (Mod+Space) and clipboard history (Mod+Y), replacing
  # DMS Spotlight and its launcher plugins. Binds live in dotfiles/.config/niri/config.kdl.
  # Built in: apps, calculator/units/currency, emoji (core:search-emojis), clipboard,
  # window switching (niri IPC), "Run" (system:run), files, power, media.
  # Left to the GUI: favorites, fallbacks (vicinae://launch/core/manage-fallback, e.g. add
  # "Search DuckDuckGo"), shortcuts/quicklinks and snippets. Vicinae needs settings.json writable,
  # so `settings` below go through VICINAE_OVERRIDES (mutableSettings) and win over GUI edits of
  # the same keys; keep GUI-managed keys out of it.
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
    mutableSettings = true;

    settings = {
      telemetry.system_info = false;
      pop_to_root_on_close = true;
      theme = {
        dark.name = "dms-blue";
        light.name = "vicinae-light";
      };
      launcher_window = {
        compact_mode.enabled = true;
        # "top" puts the launcher behind fullscreen windows on niri.
        layer_shell.layer = "overlay";
      };
    };

    # Static copy of the DMS "blue" theme (~/.cache/DankMaterialShell/dms-colors.json);
    # DMS has no matugen template for Vicinae.
    themes.dms-blue = {
      meta = {
        version = 1;
        name = "DMS Blue";
        description = "Matches the Dux Shell blue theme";
        variant = "dark";
        inherits = "vicinae-dark";
      };
      colors = {
        core = {
          background = "#101418";
          foreground = "#e0e2e8";
          secondary_background = "#1d2024";
          border = "#42474e";
          accent = "#42a5f5";
        };
        accents = {
          blue = "#42a5f5";
          green = "#42f558";
          magenta = "#7cc4ff";
          orange = "#fff77c";
          purple = "#8ab4f8";
          red = "#ff3270";
          yellow = "#fff332";
          cyan = "#abd9ff";
        };
      };
    };

    extensions = [
      (raycast "gitmoji" "sha256-Fn3QuysgWyo2YfV+WLS7oWbn4TuyiwalE3LFVWzkTd0=" "sha256-iE3IFLtwq0yqK+FOGEGGUofAiKvPxjR/g+INzdmHQAw=")
      (raycast "gif-search" "sha256-YU+pIaRyvFzCuUQG9sOT5wipBaE9yl7+5enq0RSbXnM=" "sha256-jDILjv/0Jo/nwJdVtLvYNz2NRf7dJPJ702W+wyzDDN0=")
      (raycast "nixpkgs-search" "sha256-7BjmyUm4i4XlEmSrsC0EBCTh51DhJy9EQKnfXzZQ+b4=" "sha256-8RddF785evDtABgXEAu1FBQ6dwuIgr5BmYkQVuIbjfg=")
    ];
  };

  # Script commands (replace the DMS web search and nix package runner plugins).
  home.file.".local/share/vicinae/scripts" = {
    source = ../../dotfiles/.local/share/vicinae/scripts;
    recursive = true;
  };
}
