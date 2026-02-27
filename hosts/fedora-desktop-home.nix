{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  # numen,
  ...
}: {
  # Plasma Manager KDE Configuration
  imports = [
    # ../modules/plasma-config/desktop/plasma-config.nix
    # ../../modules/plasma-config/desktop/plasma-config.nix
    ../modules/rclone/rclone-gdrivedesk.nix
    ../modules/rclone/rclone-mediaserversmb.nix
    # ../modules/rclone/rclone-hetzner.nix
    ../modules/home/app-beets.nix
    ../modules/home/communications.nix
    ../modules/home/dev-environment.nix
    ../modules/home/fun-apps.nix
    # ../modules/home/games.nix
    ../modules/home/media-playback.nix
    ../modules/home/media-mgmt.nix
    ../modules/home/office-suite.nix
    ../modules/home/utilities.nix
    ../modules/home/app-wine.nix
    ../modules/home/app-foobar2000-wine-dependencies.nix
    ../modules/home/app-syncthing.nix
    ../modules/home/app-numen.nix
    ../modules/home/app-talon.nix
    ../modules/home/app-wireguard-tray.nix
    # ../modules/home/app-tailscale.nix
    # inputs.sops-nix.homeManagerModules.sops
    # inputs.sops-nix.homeManagerModules.sops
  ];

  # sops.secrets = {
  # beets_acoustid_api = {};
  # env_file = {};
  # };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jordan";
  home.homeDirectory = "/home/jordan";

  home.packages =
    (with pkgs; [
      calibre
      dotool
      chromaprint
      kid3-kde
      python312Packages.pyacoustid
      python312Packages.discogs-client
      python312Packages.flask
      python312Packages.pylyrics
      python312Packages.pyacoustid
      python312Packages.pylast
      python312Packages.requests
      qbittorrent
      zsh
    ])
    ++ (with pkgs-stable; [
      ]);
  # ++ [
  #   numen.packages.${pkgs.stdenv.hostPlatform.system}.default
  # ];

  # Optional but recommended: Enable dotool service for Numen
  systemd.user.services.dotool = {
    Unit = {
      Description = "dotool daemon for input automation";
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.dotool}/bin/dotoold";
      Restart = "on-failure";
    };
    Install. WantedBy = ["graphical-session.target"];
  };

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
      "com.usebottles.bottles"
      "dev.deedles.Trayscale"
      "tv.kodi.Kodi"
      "net.lutris.Lutris"
      "org.winehq.Wine"
      "org.winehq.Wine.gecko"
      "org.winehq.Wine.mono"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    uninstallUnmanaged = false;
  };

  # #Enable Talon Voice Control
  # programs.talon.enable = true;
  home.file = {
    # ".ssh/.env".text = "cat ${config.sops.secrets."env_file".path}";
    ".scripts" = {
      source = ../dotfiles/.scripts;
      recursive = true;
    };
    ".python-scripts" = {
      source = ../dotfiles/.python-scripts;
      recursive = true;
    };
    ".img" = {
      source = ../dotfiles/.img;
      recursive = true;
    };
    ".config/niri/config.kdl" = {
      source = ../dotfiles/.config/niri/config.kdl;
    };
    ".config/niri/device-config.kdl" = {
      source = ../dotfiles/.config/niri/desktop-config.kdl;
    };
    ".config/niri/scripts/focus_keepassxc.sh" = {
      source = ../dotfiles/.config/niri/scripts/focus_keepassxc.sh;
    };
    "${config.xdg.configHome}/kmonad" = {
      source = ../dotfiles/.config/kmonad;
      recursive = true;
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    SHELL = "/usr/bin/zsh";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
