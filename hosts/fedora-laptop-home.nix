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
    # ../modules/rclone/rclone-gdrivedesk.nix
    # ../modules/rclone/rclone-mediaserversmb.nix
    # ../modules/rclone/rclone-hetzner.nix
    ../modules/home/communications.nix
    ../modules/home/dev-environment.nix
    ../modules/home/fun-apps.nix
    ../modules/home/media-playback.nix
    ../modules/home/media-mgmt.nix
    ../modules/home/office-suite.nix
    ../modules/home/utilities.nix
    ../modules/home/app-wine.nix
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
    ".config/niri/config.kdl" = {
      source = ../dotfiles/.config/niri/config.kdl;
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
