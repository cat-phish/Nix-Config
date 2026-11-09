#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Nix Run
# @vicinae.description Run a nixpkgs package without installing it (nix run nixpkgs#<pkg>)
# @vicinae.mode silent
# @vicinae.icon ❄️
# @vicinae.keywords ["nix", "nixpkgs", "run"]
# @vicinae.argument1 { "type": "text", "placeholder": "package" }

pkg="$1"
setsid -f sh -c 'nix run "nixpkgs#$1" >/dev/null 2>&1 || notify-send "Nix Run" "nix run nixpkgs#$1 failed"' _ "$pkg"
