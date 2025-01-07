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

    # Kmonad configuration
    # see here before enabling:
    # https://github.com/kmonad/kmonad/blob/master/doc/installation.md#configurationnix
    services.kmonad = {
      enable = false; # TODO: enable this when off of VM
      keyboards = {
        myKMonadOutput = {
          device = "/dev/input/by-id/usb-Keychron_Keychron_K2_Pro-event-kbd";
          config = builtins.readFile "${config.xdg.configHome}/kmonad/kmonad_keychron_k2_pro.kbd";
        };
      };
    };
    # services.kmonad.enable = true;

    environment.systemPackages =
      (with pkgs; [
        ])
      ++ (with pkgs-unstable; [
        ]);
  };
}
