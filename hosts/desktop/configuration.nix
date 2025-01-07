{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];
  config = {
    networking.hostName = "jordans-desktop";
    environment.systemPackages =
      (with pkgs; [
        ])
      ++ (with pkgs-unstable; [
        ]);
  };
}
