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
      libreoffice
      onlyoffice-desktopeditors
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
