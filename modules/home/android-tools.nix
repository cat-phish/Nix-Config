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
      android-tools
      android-sdk
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
