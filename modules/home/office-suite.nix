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
      libreoffice-fresh
      onlyoffice-desktopeditors
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
