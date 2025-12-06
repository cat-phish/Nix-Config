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
      discord
      kdePackages.konversation
      zoom
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
