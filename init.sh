#!/usr/bin/env bash

cd ~/.nix || echo "~/.nix does not exist. Exiting" && exit 1

echo "Please choose the host type:"
echo "1) Desktop"
echo "2) Laptop"
read -p "Enter the number of your choice: " choice

case $choice in
    1)
        host_type="desktop"
        nixos_flake="jordans-desktop"
        home_manager_flake="jordan@jordans-desktop"
        ;;
    2)
        host_type="laptop"
        nixos_flake="jordans-laptop"
        home_manager_flake="jordan@jordans-laptop"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

cp /etc/nixos/hardware-configuration.nix ~/.nix/hosts/$host_type/hardware-configuration.nix

mkdir -p ~/.local/share
cp -r ~/.nix/dotfiles/.local/share/* ~/.local/share/

mkdir -p ~/.icons
cp -r ~/.nix/dotfiles/.icons/* ~/.icons/

mkdir -p ~/.themes
cp -r ~/.nix/dotfiles/.themes/* ~/.themes/

sudo nixos-rebuild switch --flake .#$nixos_flake
# sudo nixos-rebuild switch --flake .

home-manager switch --flake .#$home_manager_flake
# home-manager switch --flake .
