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
      asciiquarium-transparent # an aquarium, duh
      audacity
      bat # cat replacement with syntax highlighting
      chirp
      cmatrix # just take the blue pill
      deskreen
      dropbox
      eza # ls replacement
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
      thefuck # correct messed up commands
      tlrc # abbreviated man pages
      wavebox
      wineasio
      winetricks
      wineWowPackages.unstable
      # wineWowPackages.waylandFull
      vlc
      youtube-music
      yt-dlp
      zoom
      zoxide
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
