{pkgs, ...}: {
  imports = [
    ../modules/home/desktop-niri.nix
    ../modules/home/app-beets.nix
    ../modules/home/games.nix
    ../modules/rclone/rclone-gdrivedesk.nix
    ../modules/rclone/rclone-mediaserversmb.nix
    ../modules/rclone/rclone-hetzner.nix
  ];

  my.niri.deviceConfig = ../dotfiles/.config/niri/desktop-config.kdl;

  home.packages = with pkgs; [
    kitty
  ];
}
