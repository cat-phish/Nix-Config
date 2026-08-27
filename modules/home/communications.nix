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
      teams-for-linux
      # zoom
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
