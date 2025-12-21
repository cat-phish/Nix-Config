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
      chirp # ham radio programmer
      deskreen # screen mirroring
      dropbox
      efibootmgr # show boot manager info
      filezilla
      gparted
      # htop
      htop-vim
      keepassxc
      lshw # list detailed hardware information
      neofetch
      noto-fonts-color-emoji
      nurl # fetching nix package options from git, maybe others
      pinta
      qdirstat
      rclone
      sqlite
      syncthing
      tlrc # man page summaries, command is tldr
      traceroute # trace packets over network
      winboat # run windows apps
      # ventoy
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
    ".scripts" = {
      source = ../../dotfiles/.scripts;
      recursive = true;
    };
  };
}
