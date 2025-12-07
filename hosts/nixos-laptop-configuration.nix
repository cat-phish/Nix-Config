{
  config,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    ../modules/hardware-config/nixos-laptop-hardware.nix
    ../modules/nixos/nvidiaGPU-laptop.nix
    ../modules/nixos/printers.nix
    ../modules/nixos/utilities.nix
  ];
  config = {
    networking.hostName = "nixos-laptop";

    services.hardware.openrgb.enable = true;

    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    services.libinput.touchpad.disableWhileTyping = true;

    nixpkgs.config.permittedInsecurePackages = [
    ];

    environment.systemPackages =
      (with pkgs; [
        openrgb-with-all-plugins
        tailscale
        tailscale-systray
        touchegg
      ])
      ++ (with pkgs-stable; [
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
          config = builtins.readFile ../dotfiles/.config/kmonad/kmonad_legion_slim_7.kbd;
        };
      };
    };

    # Disable default power profiles in order to enable tlp
    services.power-profiles-daemon.enable = false;

    # TLP for laptop power management
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        #Optional helps save long term battery health
        # START_CHARGE_THRESH_BAT0 = 40; # 40 and bellow it starts to charge
        # STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging
      };
    };

    #### Bootloader ###

    # Use the systemd-boot EFI boot loader.
    # boot.loader.systemd-boot.enable = true;
    # boot.loader.efi.canTouchEfiVariables = true;

    # Use the GRUB 2 boot loader.
    boot.loader = {
      timeout = 10;

      efi = {
        efiSysMountPoint = "/boot";
      };

      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true; # Otherwise /boot/EFI/BOOT/BOOTX64.EFI isn't generated
        devices = ["nodev"];
        useOSProber = true;
        extraEntriesBeforeNixOS = false;
        extraEntries = ''
          menuentry "Reboot" {
            reboot
          }
          menuentry "Poweroff" {
            halt
          }
        '';
        # theme = pkgs.fetchFromGitHub {
        #   enable = false;
        #   owner = "harishnkr";
        #   repo = "bsol";
        #   rev = "v1.0"; # commit number
        #   sha256 = "sha256-sUvlue+AXW6VkVYy3WOUuSt548b6LoDpJmQPbgcZDQw="; # attempt build with this value empty to get the hash
        # };
        darkmatter-theme = {
          enable = true;
          style = "nixos";
          icon = "color";
          resolution = "1080p";
        };
        configurationLimit = 20;
      };
    };

    ### Graphics ###

    # Enable OpenGL
    #   hardware.graphics = {
    #     enable = true;
    #   };
    #
    #   # Load nvidia driver for Xorg and Wayland
    #   services.xserver.videoDrivers = ["nvidia"];
    #
    #   hardware.nvidia = {
    #     # Modesetting is required.
    #     modesetting.enable = true;
    #
    #     # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    #     # Enable this if you have graphical corruption issues or application crashes after waking
    #     # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    #     # of just the bare essentials.
    #     powerManagement.enable = false;
    #
    #     # Fine-grained power management. Turns off GPU when not in use.
    #     # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    #     powerManagement.finegrained = false;
    #
    #     # Use the NVidia open source kernel module (not to be confused with the
    #     # independent third-party "nouveau" open source driver).
    #     # Support is limited to the Turing and later architectures. Full list of
    #     # supported GPUs is at:
    #     # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    #     # Only available from driver 515.43.04+
    #     # Currently alpha-quality/buggy, so false is currently the recommended setting.
    #     open = false;
    #
    #     # Enable the Nvidia settings menu,
    #     # accessible via `nvidia-settings`.
    #     nvidiaSettings = true;
    #
    #     # Optionally, you may need to select the appropriate driver version for your specific GPU.
    #     package = config.boot.kernelPackages.nvidiaPackages.beta;
    #   };
  };
}
