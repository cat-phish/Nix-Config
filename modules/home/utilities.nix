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
      appimage-run
      audacity
      fuse
      gparted
      # htop
      htop-vim
      neofetch
      noto-fonts-color-emoji
      pinta
      qdirstat
      rclone
      syncthing
      tlrc
      traceroute
      winboat
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
