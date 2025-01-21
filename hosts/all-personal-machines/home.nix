{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: let
  beets-copyartifacts3 = pkgs.python3Packages.buildPythonPackage rec {
    pname = "copyartifacts";
    version = "0.1.5";

    src = pkgs.fetchFromGitHub {
      owner = "adammillerio";
      repo = "beets-copyartifacts";
      rev = "v${version}";
      sha256 = "UTZh7T6Z288PjxFgyFxHnPt0xpAH3cnr8/jIrlJhtyU=";
    };

    doCheck = false; # check requires infrastructure
  };
in {
  home.packages =
    (with pkgs; [
      activate-linux
      appimage-run
      audacity
      chirp
      deskreen

      # beets and plugins
      # beets-copyartifacts3
      # beetsPackages.copyartifacts
      # python312Packages.chromaprint

      # python312Packages.pip

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
      python39
      redshift
      restic
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
    # "${config.xdg.configHome}/beets/config.yaml" = {
    #   source = ../../dotfiles/.config/beets/config.yaml;
    # };
    "${config.xdg.configHome}/kmonad" = {
      source = ../../dotfiles/.config/kmonad;
      recursive = true;
    };
  };
}
