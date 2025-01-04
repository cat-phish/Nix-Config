{ config, lib, pkgs, pkgs-unstable, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];
  config = {
    networking.hostName = "jordans-laptop";
    environment.systemPackages =
      (with pkgs; [
        neofetch
      ])

      ++

      (with pkgs-unstable; [
      ])
    
    ;
  };
}