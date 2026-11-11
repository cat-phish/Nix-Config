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

  # Fedora: the tray script (~/.python-scripts/wireguard-tray.py) runs on the system python
  # (init.sh also runs `pip install pystray pillow`).
  my.fedora.dnf.packages = ["python3-pip" "python3-gobject" "gtk3"];

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
