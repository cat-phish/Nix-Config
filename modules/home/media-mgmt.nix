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
      calibre
      kid3-kde
      qbittorrent
      yt-dlp
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
