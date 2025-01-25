{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  home.packages =
    (with pkgs; [
      activate-linux
      appimage-run
      audacity
      chirp
      deskreen
      dropbox
      flameshot
      ghostty
      google-chrome
      hypnotix
      libreoffice-fresh
      mpv
      multiviewer-for-f1
      navi
      neofetch
      neovide
      nurl # fetching nix package options from git, maybe others
      pinta
      pocket-casts
      python39
      redshift
      restic
      syncthing
      wavebox
      wineasio
      winetricks
      # wineWowPackages
      wineWowPackages.waylandFull
      vlc
      youtube-music
      yt-dlp
      zoom
    ])
    ++ (with pkgs-stable; [
      ]);
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: with epkgs; []; # Add any additional packages if desired
  };

  home.file = {
    ".clang-format" = {
      source = ../../dotfiles/.clang-format;
    };
    ".prettierrc" = {
      source = ../../dotfiles/.prettierrc;
    };
    ".scripts" = {
      source = ../../dotfiles/.scripts;
      recursive = true;
    };
    ".wezterm.lua" = {
      source = ../../dotfiles/.wezterm.lua;
    };
    "${config.xdg.configHome}/kmonad" = {
      source = ../../dotfiles/.config/kmonad;
      recursive = true;
    };
  };
}
