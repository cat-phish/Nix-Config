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
      syncthing
      syncthingtray
    ])
    ++ (with pkgs-stable; [
      ]);

  services.syncthing.enable = true;

  home.file = {
  };
}
