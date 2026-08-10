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
      steam
      zenity
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
