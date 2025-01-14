{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    # ./nvidiaGPU.nix
  ];
  config = {
    networking.hostName = "jordans-desktop";

    environment.systemPackages =
      (with pkgs; [
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
        kmonad_keychron_k2_pro = {
          device = "/dev/input/by-id/usb-Keychron_Keychron_K2_Pro-event-kbd";
          config = builtins.readFile ../../dotfiles/.config/kmonad/kmonad_keychron_k2_pro.kbd;
        };
        kmonad_havit = {
          device = "/dev/input/by-id/usb-1ea7_USB-HID_GamingKeyBoard-event-kbd";
          config = builtins.readFile ../../dotfiles/.config/kmonad/kmonad_havit.kbd;
        };
        kmonad_winry315 = {
          device = "/dev/input/by-id/usb-Winry_Winry315-event-kbd";
          config = builtins.readFile ../../dotfiles/.config/kmonad/kmonad_winry315.kbd;
        };
      };
    };

    ### Bootloader ###

    boot.loader = {
      grub = {
        darkmatter-theme = {
          resolution = "1440p";
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
