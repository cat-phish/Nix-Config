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
      text = ''
        [Desktop Entry]
        Type=Application
        Name=WireGuard Tray
        Comment=WireGuard VPN system tray manager
        Exec=python ${config.home.homeDirectory}/.python-scripts/wireguard-tray.py
        Icon=${config.home.homeDirectory}/.img/wireguard.png
        Categories=Network;System;
        Keywords=vpn;wireguard;network;
        Terminal=false
        StartupNotify=false
      '';
    };
  };
}
