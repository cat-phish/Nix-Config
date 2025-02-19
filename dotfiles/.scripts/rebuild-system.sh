#!/usr/bin/env bash

sudo nixos-rebuild switch --flake ~/.nix

home-manager switch --flake ~/.nix
