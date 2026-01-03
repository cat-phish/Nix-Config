{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
  ];

  home.file = {
    ".config/numen/phrases" = {
      source = ../../dotfiles/.config/numen/phrases;
      recursive = true;
    };
  };
}
