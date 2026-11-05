# KDE Plasma desktop for NixOS, as used before the move to niri + DMS (Nov 2026).
# Not imported. To restore: import this from configuration.nix (and remove the niri/DMS
# block), re-add the plasma-manager input to flake.nix and pass it via specialArgs, then
# import plasma-config/<host>/plasma-config.nix from hosts/nixos-<host>-home.nix.
#
# Previous flake input:
#   plasma-manager.url = "github:mcdonc/plasma-manager/enable-look-and-feel-settings";
#   plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
#   plasma-manager.inputs.home-manager.follows = "home-manager";
#
# nixos-desktop also had snap support (dropped at the same time):
#   nix-snapd.url = "github:nix-community/nix-snapd";  # + nix-snapd.nixosModules.default
#   services.snap.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: {
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  users.users.jordan.packages = with pkgs; [
    kdePackages.kate
    kdePackages.kcalc
  ];

  # nixos-desktop only: X11 monitor layout (primary DP-1, others off)
  services.xserver = lib.mkIf (config.networking.hostName == "nixos-desktop") {
    xrandrHeads = [
      {
        output = "DP-1";
        primary = true;
      }
      {
        output = "DP-2";
        monitorConfig = ''Option "Enable" "false"'';
      }
      {
        output = "HDMI-0";
        monitorConfig = ''Option "Enable" "false"'';
      }
    ];
    exportConfiguration = true;
  };
}
