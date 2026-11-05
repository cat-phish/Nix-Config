{config, ...}: {
  imports = [
    ../modules/home/desktop-niri.nix
    ../modules/rclone/rclone-gdrivelap.nix
    ../modules/rclone/rclone-mediaserversmb.nix
    # ../modules/rclone/rclone-hetzner.nix
  ];

  # Written for the ThinkPad (fedora-laptop); adjust outputs for this machine if needed.
  my.niri.deviceConfig = ../dotfiles/.config/niri/laptop-config.kdl;

  home.file."${config.xdg.configHome}/OpenRGB" = {
    source = ../dotfiles/.config/OpenRGB;
    recursive = true;
  };
}
