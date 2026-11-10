{
  config,
  lib,
  pkgs,
  ...
}: {
  # Vicinae: Raycast-style launcher (Mod+Space) and clipboard history (Mod+Y), replacing
  # DMS Spotlight and its launcher plugins. Binds live in dotfiles/.config/niri/config.kdl.
  # Built in: apps, calculator/units/currency, emoji (core:search-emojis), clipboard,
  # window switching (niri IPC), "Run" (system:run), files, power, media.
  # Left to the GUI: favorites, fallbacks (vicinae://launch/core/manage-fallback, e.g. add
  # "Search DuckDuckGo"), shortcuts/quicklinks and snippets. Vicinae needs settings.json writable,
  # so `settings` below go through VICINAE_OVERRIDES (mutableSettings) and win over GUI edits of
  # the same keys; keep GUI-managed keys out of it.
  # Extensions aren't managed here: they're listed in dotfiles/.config/vicinae/extensions.conf
  # and installed/updated by ~/.scripts/vicinae-extensions (run by update-system). See docs/vicinae.md.
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
      # Don't crawl the rclone FUSE mounts. When Wi-Fi drops at suspend, a readdir on them
      # hangs in uninterruptible sleep, the indexer can't be frozen, and suspend fails
      # (laptop stays awake and the lock screen ignores input for a minute after opening the lid).
      providers.files.preferences.excludedIndexingPaths = map (p: "${config.home.homeDirectory}/${p}") [
        "gdrive"
        "mediaserver"
      ];
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
  };

  # Script commands (replace the DMS web search and nix package runner plugins).
  home.file.".local/share/vicinae/scripts" = {
    source = ../../dotfiles/.local/share/vicinae/scripts;
    recursive = true;
  };
}
