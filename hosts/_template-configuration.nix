# Template for a new NixOS host. Copy to hosts/<host>-configuration.nix, generate
# modules/hardware-config/<host>-hardware.nix with `nixos-generate-config --show-hardware-config`,
# and add `<host> = mkNixos "<host>";` to nixosConfigurations in flake.nix.
# configuration.nix already provides the shared base (niri + DMS, audio, user, nix settings).
{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../modules/hardware-config/HOST-hardware.nix
    # ../modules/nixos/nvidiaGPU-desktop.nix
    # ../modules/nixos/printers.nix
    ../modules/nixos/utilities.nix
  ];

  networking.hostName = "HOST";

  environment.systemPackages = with pkgs; [
  ];

  # services.kmonad.keyboards.<name> = {
  #   device = "/dev/input/by-id/...";
  #   config = builtins.readFile ../dotfiles/.config/kmonad/<file>.kbd;
  # };

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    devices = ["nodev"];
    useOSProber = true;
    configurationLimit = 20;
  };
}
