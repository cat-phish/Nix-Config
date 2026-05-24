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
      fcast-client
      fcast-receiver
      lsp-plugins # a collection of open source audio plugins
      mpv
      vlc
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
