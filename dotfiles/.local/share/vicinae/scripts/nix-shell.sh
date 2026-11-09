#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Nix Shell
# @vicinae.description Open a terminal with nixpkgs packages available (nix shell)
# @vicinae.mode terminal
# @vicinae.icon ❄️
# @vicinae.keywords ["nix", "nixpkgs", "shell"]
# @vicinae.argument1 { "type": "text", "placeholder": "packages (space separated)" }

args=()
for p in $1; do args+=("nixpkgs#$p"); done
exec nix shell "${args[@]}" --command "${SHELL:-bash}"
