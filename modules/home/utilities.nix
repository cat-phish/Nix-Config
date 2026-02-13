{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  # Plasma Manager KDE Configuration
  imports = [
  ];

  # sops.secrets = {
  # };

  home.packages =
    (with pkgs; [
      aerc
      appimage-run
      audacity
      browsh
      chirp # ham radio programmer
      chromium
      deskreen # screen mirroring
      # dropbox
      efibootmgr # show boot manager info
      filezilla
      gparted
      # htop
      htop-vim
      keepassxc
      #librewolf
      localsend
      lshw # list detailed hardware information
      neofetch
      noto-fonts-color-emoji
      nurl # fetching nix package options from git, maybe others
      # obs-studio # driver issue on fedora
      pinta
      qdirstat
      rclone
      sqlite
      steam-run
      thunar
      tlrc # man page summaries, command is tldr
      traceroute # trace packets over network
      winboat # run windows apps
      wl-color-picker
      # ventoy
      xwayland-run
      # cage
      zoom
    ])
    ++ (with pkgs-stable; [
      rssguard
    ]);

  home.file = {
    ".scripts" = {
      source = ../../dotfiles/.scripts;
      recursive = true;
    };
    ".local/share/applications/org-mode.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Org Mode
        Comment=Launch Tasks
        Generic Name=Task Tracker
        Exec=emacs ${config.home.homeDirectory}/org/main/Tasks.org
        Icon=${config.home.homeDirectory}/.img/org-mode-unicorn.png
        Categories=Office:TextEditor;
        Keywords=organization;tasks;
        Terminal=false
        StartupWMClass=Emacs
        StartupNotify=false
      '';
    };
  };
}
