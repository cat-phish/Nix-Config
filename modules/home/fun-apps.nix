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
      activate-linux
      asciiquarium-transparent # an aquarium, duh
      cmatrix # just take the blue pill
      # vimgolf
      # Override vimgolf to handle Ruby extension
      (vimgolf.override {
        ruby = ruby.withPackages (ps: with ps; [rbs racc debug]);
      })
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
    ".config/sounds" = {
      source = ../../dotfiles/.config/sounds;
      recursive = true;
    };
  };
}
