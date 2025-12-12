{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    ../modules/home/communications.nix
    ../modules/home/dev-environment.nix
    ../modules/home/fun-apps.nix
    ../modules/home/media-playback.nix
    ../modules/home/media-mgmt.nix
    ../modules/home/office-suite.nix
    ../modules/home/utilities.nix
    ../modules/home/app-wine.nix
    ../modules/home/app-foobar2000-wine-dependencies.nix
    ../modules/plasma-config/nixos-laptop/plasma-config.nix
    ../modules/rclone/rclone-gdrivelap.nix
    ../modules/rclone/rclone-mediaserversmb.nix
    ../modules/rclone/rclone-hetzner.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jordan";
  home.homeDirectory = "/home/jordan";

  # sops.secrets = {
  # };

  home.packages =
    (with pkgs; [
      ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
    "${config.xdg.configHome}/OpenRGB" = {
      source = ../../dotfiles/.config/OpenRGB;
      recursive = true;
    };
    "${config.xdg.configHome}/touchegg/touchegg.conf" = {
      source = ../../dotfiles/.config/touchegg/touchegg.conf;
    };
  };

  home.sessionVariables = {
    SHELL = pkgs.zsh;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
