#!/usr/bin/env bash

nix flake update --flake ~/.nix

sudo nixos-rebuild switch --flake ~/.nix

home-manager switch --flake ~/.nix
