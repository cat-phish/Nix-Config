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
    # ../../modules/plasma-config/desktop/plasma-config.nix
    ../modules/rclone/rclone-gdrivedesk.nix
    ../modules/rclone/rclone-mediaserversmb.nix
    # ../modules/rclone/rclone-hetzner.nix
    ../modules/home/communications.nix
    ../modules/home/dev-environment.nix
    ../modules/home/fun-apps.nix
    ../modules/home/media-playback.nix
    ../modules/home/media-mgmt.nix
    ../modules/home/office-suite.nix
    ../modules/home/utilities.nix
    ../modules/home/app-wine.nix
    ../modules/home/app-syncthing.nix
    ../modules/home/app-numen.nix
    ../modules/home/app-foobar2000-wine-dependencies.nix
    ../modules/home/app-wireguard-tray.nix
    # ../modules/home/app-tailscale.nix
    # inputs.sops-nix.homeManagerModules.sops
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jordan";
  home.homeDirectory = "/home/jordan";

  nixpkgs.config.allowUnfree = true;

  home.packages =
    (with pkgs; [
      # docker
      firefox
      kmonad
      sfml
    ])
    ++ (with pkgs-stable; [
      ]);

  systemd.user.services.kmonad = {
    Unit = {
      Description = "KMonad keyboard remapping";
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.kmonad}/bin/kmonad %h/.nix/dotfiles/.config/kmonad/kmonad_thinkpad_x1_carbon_gen12.kbd";
      # ExecStart = "$HOME/.nix-profile/bin/kmonad $HOME/.nix/dotfiles/.config/kmonad/kmonad_thinkpad_x1_carbon_gen12.kbd";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  systemd.user.services.ntfy-listener = {
    Unit = {
      Description = "ntfy Desktop Notifications";
      After = ["graphical-session.target"];
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };

    Service = {
      EnvironmentFile = "%h/.ssh/.env";

      # Bash checks the ping. If successful, it hands the process over to ntfy (via exec).
      # If it fails, it sleeps for 60s and exits cleanly, prompting systemd to loop it.
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c ' \
          if ${pkgs.iputils}/bin/ping -c 1 -W 2 "''${MEDIASERVER_HOST}" >/dev/null 2>&1; then \
            exec ${pkgs.ntfy-sh}/bin/ntfy sub \
              --token "''${NTFY_AUTH_TOKEN}" \
              "http://''${MEDIASERVER_HOST}:3924/Tracearr" \
              "${pkgs.libnotify}/bin/notify-send \"[\$$NTFY_TOPIC] \$$NTFY_TITLE\" \"\$$NTFY_MESSAGE\""; \
          else \
            sleep 60; \
          fi \
        '
      '';

      Restart = "always";
      # Total wait time when away: 60s sleep + 10s RestartSec = 70 seconds between checks
      RestartSec = "10";
    };
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
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    uninstallUnmanaged = false;
  };

  # services.tailscale = {
  #   enable = true;
  #   useRoutingFeatures = "client";
  # };
  #
  # #Enable Talon Voice Control
  # programs.talon.enable = true;

  home.file = {
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
      source = ../dotfiles/.config/niri/laptop-config.kdl;
    };

    ".config/niri/scripts/focus_keepassxc.sh" = {
      source = ../dotfiles/.config/niri/scripts/focus_keepassxc.sh;
    };
    ".config/niri/scripts/syncthingtray_startup_delay.sh" = {
      source = ../dotfiles/.config/niri/scripts/focus_keepassxc.sh;
    };
    "${config.xdg.configHome}/kmonad" = {
      source = ../dotfiles/.config/kmonad;
      recursive = true;
    };
    # "${config.xdg.configHome}/systemd/user/kmonad.service" = {
    #   source = ../dotfiles/.config/kmonad/setup/kmonad_thinkpad_x1_carbon.service;
    # };
    # "${config.xdg.dataHome}/applications/foobar2000.desktop".text = ''
    #   [Desktop Entry]
    #   Name=foobar2000
    #   Exec=env WINEPREFIX="$HOME/.wine-foobar2000" WINEARCH=win32 wine "$HOME/wineapps/foobar2000_2.0/foobar2000.exe"
    #   Type=Application
    #   Icon="$HOME/.img/foobar.jpg"
    #   Categories=AudioVideo;Player;
    # '';
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
