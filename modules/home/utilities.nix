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
      chromium
      deskreen # screen mirroring
      dropbox
      efibootmgr # show boot manager info
      filezilla
      gparted
      # htop
      htop-vim
      keepassxc
      librewolf
      localsend
      lshw # list detailed hardware information
      neofetch
      noto-fonts-color-emoji
      nurl # fetching nix package options from git, maybe others
      pinta
      qdirstat
      rclone
      sqlite
      steam-run
      thunar
      tlrc # man page summaries, command is tldr
      traceroute # trace packets over network
      winboat # run windows apps
      wl-color-picker
      # ventoy
      xwayland-run
      # cage
    ])
    ++ (with pkgs-stable; [
      rssguard
    ]);

  home.file = {
    ".scripts" = {
      source = ../../dotfiles/.scripts;
      recursive = true;
    };
  };
}
