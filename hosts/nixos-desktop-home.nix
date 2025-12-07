{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: {
  # Plasma Manager KDE Configuration
  imports = [
    ../modules/home/app-beets.nix
    ../modules/home/communications.nix
    ../modules/home/dev-environment.nix
    ../modules/home/fun-apps.nix
    ../modules/home/media-playback.nix
    ../modules/home/media-mgmt.nix
    ../modules/home/office-suite.nix
    ../modules/home/utilities.nix
    ../modules/home/app-wine.nix
    ../modules/home/app-foobar2000-wine-dependencies.nix
    ../modules/plasma-config/nixos-desktop/plasma-config.nix
    ../modules/rclone/rclone-gdrivedesk.nix
    ../modules/rclone/rclone-mediaserversmb.nix
    ../modules/rclone/rclone-hetzner.nix
    # inputs.sops-nix.homeManagerModules.sops
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
    # ".ssh/.env".text = "cat ${config.sops.secrets."env_file".path}";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
