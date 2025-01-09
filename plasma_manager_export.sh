#!/usr/bin/env bash

current_hostname=$(hostname)

case $current_hostname in
  jordans-desktop)
    target_file="$HOME/.nix/hosts/desktop/plasma-config.nix"
    ;;
  jordans-laptop)
    target_file="$HOME/.nix/hosts/laptop/plasma-config.nix"
    ;;
  *)
    echo "Unknown hostname: $current_hostname. Exiting."
    exit 1
    ;;
esac

cat <<EOF > "$target_file"
{
  pkgs,
  plasma-manager,
  ...
}: {
  imports = [
    plasma-manager.homeManagerModules.plasma-manager
  ];
  # To update this with your current kde configuration run
  # ./plasma_manager_export.sh in the main dir of this repo
EOF

# Append all output except the first line
nix run github:mcdonc/plasma-manager/enable-look-and-feel-settings | tail -n +2 >> "$target_file"

echo "Configuration written to $target_file"



