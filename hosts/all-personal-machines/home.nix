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
      neofetch
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
    ".wezterm.lua" = {
      source = ../../dotfiles/.wezterm.lua;
    };

    "${config.xdg.configHome}/kmonad" = {
      source = ../../dotfiles/.config/kmonad;
      recursive = true;
    };

    # Theming
    # ".img/wallpapers/blue.jpg" = {
    #   source = ../../dotfiles/.img/wallpapers/blue.jpg;
    # };

    # NOTE: deprecated in favor of copying once in init.sh on install
    # due to slow switching times from icon linking
    #
    # ".local/share/icons/Memphis98" = {
    #   source = ../../dotfiles/.local/share/icons/Memphis98;
    #   recursive = true;
    # };
    # ".local/share/icons/Reactionary" = {
    #   source = ../../dotfiles/.local/share/icons/Reactionary;
    #   recursive = true;
    # };
    #
    # ".local/share/plasma/desktoptheme/reactplus" = {
    #   source = ../../dotfiles/.local/share/plasma/desktoptheme/reactplus;
    #   recursive = true;
    # };
    #
    # ".local/share/plasma/look-and-feel/org.magpie.reactplus.desktop" = {
    #   source = ../../dotfiles/.local/share/plasma/look-and-feel/org.magpie.reactplus.desktop;
    #   recursive = true;
    # };
    #
    # ".local/share/plasma/desktoptheme/reactionary" = {
    #   source = ../../dotfiles/.local/share/plasma/desktoptheme/reactionary;
    #   recursive = true;
    # };
    #
    # ".local/share/plasma/look-and-feel/Reactionary" = {
    #   source = ../../dotfiles/.local/share/plasma/look-and-feel/Reactionary;
    #   recursive = true;
    # };
  };
}
