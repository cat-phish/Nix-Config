#!/usr/bin/env bash

#cd ~/.nix || echo "~/.nix does not exist. Exiting" && exit 1

echo "Please choose the host type:"
echo "1) Desktop NixOS"
echo "2) Laptop NixOS"
echo "3) Fedora Home Manager"
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
      3)
        host_type="desktop"
        home_manager_flake="jordan@fedora-desktop"
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

if [ "$choice" = 1 ] || [ "$choice" = 2 ]; then
  cp /etc/nixos/hardware-configuration.nix ~/.nix/hosts/$host_type/hardware-configuration.nix
  mkdir -p ~/.local/share
  cp -r ./dotfiles/.local/share/* ~/.local/share/
fi


mkdir -p ~/.icons
cp -r ./dotfiles/.icons/* ~/.icons/

mkdir -p ~/.themes
cp -r ./dotfiles/.themes/* ~/.themes/

if [ "$choice" = 1 ] || [ "$choice" = 2 ]; then
  sudo nixos-rebuild switch --flake .#$nixos_flake
fi

# TODO: make i this check if nix is installed already
if [ "$choice" = 1 ] || [ "$choice" = 2 ]; then
  home-manager switch --flake .#$home_manager_flake
elif [ "$choice" = 3 ]; then
  sudo dnf copr enable petersen/nix
  sudo dnf install nix
  sudo systemctl enable --now nix-daemon
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update
  nix-shell '<home-manager>' -A install
  source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
  home-manager switch -b backup --flake .#$home_manager_flake
fi
