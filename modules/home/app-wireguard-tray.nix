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
      ]);

  home.file = {
    ".local/share/applications/wireguard-tray.desktop" = {
      source = ../../dotfiles/.local/share/applications/wireguard-tray.desktop;
    };
  };
}
