#!/usr/bin/env bash

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

cp /etc/nixos/hardware-configuration.nix hosts/$host_type/hardware-configuration.nix

sudo nixos-rebuild switch --flake .#$nixos_flake

home-manager switch --flake .#$home_manager_flake
