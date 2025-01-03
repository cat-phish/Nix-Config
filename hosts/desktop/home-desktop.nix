{ config, pkgs, pkgs-unstable, ... }:

{
  home.packages = (with pkgs; [
    # Add desktop-specific packages here
  ]) ++ (with pkgs-unstable; [
    # Add unstable packages here
  ]);

  home.file = {
    # Add or override desktop-specific files here
    # Recursively adds dotfiles from ~/.nix/dotfiles/config/
    "${config.xdg.configHome}" = {
      source = ../../dotfiles/.config;
      recursive = true;
    };
  };
  # Add any desktop-specific configurations here
}
