# Template for a new host's Home Manager config. Copy to hosts/<host>-home.nix and add a
# line to homeConfigurations in flake.nix:
#   "jordan@<host>" = mkHome { host = "<host>"; isNixos = false; };
# home.nix already imports modules/home/common.nix (shared apps, flatpaks, dotfiles, gc).
{pkgs, ...}: {
  imports = [
    ../modules/home/desktop-niri.nix
    # ../modules/home/games.nix
    # ../modules/rclone/rclone-gdrivedesk.nix
  ];

  my.niri.deviceConfig = ../dotfiles/.config/niri/laptop-config.kdl;
  # my.niri.dmsSettings = "<host>-settings.json";

  home.packages = with pkgs; [
  ];
}
