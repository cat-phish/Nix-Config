#!/usr/bin/env bash

sudo nix flake update --flake ~/.nix mynvim

home-manager switch --flake ~/.nix
