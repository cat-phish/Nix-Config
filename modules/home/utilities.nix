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
      cargo
      caligula # iso to disk burning, dd alternative
      chafa
      chirp # ham radio programmer
      chromium
      cinny-unwrapped
      deskreen # screen mirroring
      # dropbox
      # TODO: package durdraw
      efibootmgr # show boot manager info
      element-desktop
      filezilla
      fswatch # a file change watcher
      gparted
      httpie # http api tool
      # htop
      htop-vim
      keepassxc
      #librewolf
      localsend
      lshw # list detailed hardware information
      ncdu
      neofetch
      # nheko # matrix client # has cve in dependency
      noto-fonts-color-emoji
      nurl # fetching nix package options from git, maybe others
      # obs-studio # driver issue on fedora
      pastel # cli color picker
      pinta
      qdirstat
      rclone
      rofi
      strace # stack racer for linux system calls
      sqlite
      steam-run
      thunar
      tlrc # man page summaries, command is tldr
      traceroute # trace packets over network
      trashy # trash files
      winboat # run windows apps
      wl-color-picker
      # ventoy
      xmlto
      xwayland-run
      # cage
      zoom
    ])
    ++ (with pkgs-stable; [
      rssguard
    ]);

  services.flatpak = {
    enable = true;

    remotes = lib.mkOptionDefault [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      # {
      #   appId = "com.brave.Browser";
      #   origin = "flathub";
      # }
      "im.nheko.Nheko"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    uninstallUnmanaged = false;
  };

  home.file = {
    ".scripts" = {
      source = ../../dotfiles/.scripts;
      recursive = true;
    };
    ".config/navi" = {
      source = ../../dotfiles/.config/navi;
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
