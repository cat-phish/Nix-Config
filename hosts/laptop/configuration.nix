{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nvidiaGPU.nix
  ];
  config = {
    networking.hostName = "jordans-laptop";

    environment.systemPackages =
      (with pkgs; [
        openrgb-with-all-plugins
      ])
      ++ (with pkgs-unstable; [
        ]);

    ### Services ###

    # Kmonad configuration
    # see here before enabling:
    # https://github.com/kmonad/kmonad/blob/master/doc/installation.md#configurationnix
    services.kmonad = {
      enable = true;
      keyboards = {
        kmonad_legion_slim_7 = {
          device = "/dev/input/by-path/pci-0000:06:00.4-usbv2-0:4:1.0-event-kbd";
          config = builtins.readFile ../../dotfiles/.config/kmonad/kmonad_legion_slim_7.kbd;
        };
      };
    };

    ### Bootloader ###

    boot.loader = {
      grub = {
        darkmatter-theme = {
          resolution = "1080p";
        };
      };
    };

    ### Graphics ###

    # Enable OpenGL
    hardware.graphics = {
      enable = true;
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };
}
