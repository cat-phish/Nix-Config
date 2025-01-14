{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  # nixpkgs.config.allowUnfree = true;
  home.packages =
    (with pkgs; [
      activate-linux
      appimage-run
      audacity
      chirp
      deskreen

      #beets
      beets
      # beetsPackages.copyartifacts # TODO: causing build issue
      python312Packages.discogs-client
      python312Packages.flask
      python312Packages.pyacoustid
      python312Packages.pylast
      python312Packages.requests

      flameshot
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
      redshift
      wineasio
      winetricks
      # wineWowPackages
      wineWowPackages.waylandFull
      vlc
      youtube-music
      yt-dlp
      zoom
    ])
    ++ (with pkgs-unstable; [
      google-chrome
      wavebox
    ]);
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: with epkgs; []; # Add any additional packages if desired
  };

  home.file = {
    ".clang-format" = {
      source = ../../dotfiles/.clang-format;
    };
    "prettierrc" = {
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
    # TODO: add scripts to dotfiles
    # "scripts" = {
    #   source = ../../dotfiles/scripts;
    #   recursive = true;
    # };
  };
}
