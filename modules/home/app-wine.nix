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
      ])
    ++ (with pkgs-stable; [
      # wine
      wineasio
      winetricks
      wineWowPackages.full
      # wineWowPackages.unstable
      # wineWowPackages.waylandFull
      # erosanix.packages.i686-linux.foobar2000
    ]);

  home.file = {
  };
}
