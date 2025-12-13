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
      pkgs.pkgsi686Linux.alsa-plugins
      pkgs.pkgsi686Linux.libpulseaudio
      pkgs.pkgsi686Linux.openal
    ]);

  home.file = {
    ".local/share/applications/foobar2000.desktop" = {
      source = ../../dotfiles/.local/share/applications/foobar2000.desktop;
    };
  };
}
