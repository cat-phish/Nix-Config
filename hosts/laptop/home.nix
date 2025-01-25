{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    ../../modules/plasma-config/desktop/plasma-config.nix
    ../../modules/rclone/rclone-gdrivelap.nix
    ../../modules/rclone/rclone-mediaserversmb.nix
    ../../modules/rclone/rclone-hetzner.nix
  ];

  home.packages =
    (with pkgs; [
      ])
    ++ (with pkgs-sstable; [
      ]);

  home.file = {
    "${config.xdg.configHome}/OpenRGB/" = {
      source = ../../dotfiles/.config/OpenRGB;
      recursive = true;
    };
    "${config.xdg.configHome}/touchegg/touchegg.conf" = {
      source = ../../dotfiles/.config/touchegg/touchegg.conf;
    };
  };
}
