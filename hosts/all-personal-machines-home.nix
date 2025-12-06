{
  config,
  pkgs,
  pkgs-stable,
  # isNixos will be passed via extraSpecialArgs from the flake.
  # Default to true to preserve current behaviour for your NixOS hosts.
  isNixos ? true,
  lib,
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
      chromium
      cmatrix # just take the blue pill
      deskreen
      dropbox
      eza # ls replacement
      fd
      flameshot
      ghostty
      gimp
      gparted
      google-chrome
      hypnotix
      kdePackages.konversation
      kvirc
      libreoffice-fresh
      lsp-plugins
      mouseless
      mpv
      multiviewer-for-f1
      navi
      neofetch
      neovide
      noisetorch
      nurl # fetching nix package options from git, maybe others
      pinta
      pocket-casts
      # python39
      puddletag
      pulseaudio
      qdirstat
      redshift
      ripgrep
      syncthing
      # talon-nix.packages.${builtins.currentSystem}.default
      # thefuck # correct messed up commands
      tlrc # abbreviated man pages
      traceroute
      # wineasio
      # winetricks
      vlc
      vscode
      # winboat
      youtube-music
      yt-dlp
      zoom
      zoxide
    ])
    ++ (with pkgs-stable; [
      restic
      # wavebox
    ]);

  # Example: if you later need to add home items that should only be applied
  # on NixOS hosts (for example, user config that relies on system-level units),
  # use `lib.mkIf isNixos [ ... ]` to guard them. On Fedora (isNixos=false)
  # those blocks will be skipped.
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: with epkgs; []; # Add any additional packages if desired
  };

  services.emacs.enable = true;

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
    "${config.xdg.dataHome}/applications/foobar2000.desktop".text = ''
      [Desktop Entry]
      Name=foobar2000
      Exec=env WINEPREFIX="$HOME/.wine-foobar2000" WINEARCH=win32 wine "$HOME/wineapps/foobar2000_2.0/foobar2000.exe"
      Type=Application
      Icon="$HOME/.nix/dotfiles/.img/foobar.jpg"
      Categories=AudioVideo;Player;
    '';
  };
}
