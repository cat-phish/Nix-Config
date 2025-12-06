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
    ../modules/rclone/rclone-hetzner.nix
    ../modules/communications.nix
    ../modules/dev-environment.nix
    ../modules/fun-apps.nix
    ../modules/media-playback.nix
    ../modules/media-mgmgt.nix
    ../modules/utilities.nix
    # inputs.sops-nix.homeManagerModules.sops
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jordan";
  home.homeDirectory = "/home/jordan";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
  ];

  home.packages =
    (with pkgs; [
      # docker
      firefox
      kmonad
      onlyoffice-desktopeditors

    ])
    ++ (with pkgs-stable; [
      ]);


  };

  # services.flatpak = {
  #   remotes = lib.mkOptionDefault [
  #     {
  #       name = "flathub";
  #       location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  #     }
  #   ];
  #   packages = [
  #     # {
  #     #   appId = "com.brave.Browser";
  #     #   origin = "flathub";
  #     # }
  #     "com.usebottles.bottles"
  #     "dev.deedles.Trayscale"
  #   ];
  #   update.auto.enable = false;
  #   uninstallUnmanaged = false;
  # };
  #
  # services.tailscale = {
  #   enable = true;
  #   useRoutingFeatures = "client";
  # };
  #
  # #Enable Talon Voice Control
  # programs.talon.enable = true;

  home.file = {
    ".scripts" = {
      source = ../../dotfiles/.scripts;
      recursive = true;
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
  home.sessionVariables = {
    EDITOR = "vim";
    SHELL = pkgs.zsh;
  };
}
