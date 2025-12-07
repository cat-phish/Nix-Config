{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    ../modules/hardware-config/nixos-desktop-hardware.nix
    ../modules/nixos/nvidiaGPU-desktop.nix
    ../modules/nixos/printers.nix
    ../modules/nixos/utilities.nix
    inputs.sops-nix.nixosModules.sops
  ];
  options = {
    # Enable numlock on boot
    ncfg.services.numlock-on-tty = {
      enable = lib.mkEnableOption "Enable numlock";
    };
  };
  config = {
    networking.hostName = "nixos-desktop";

    sops.secrets = {
      beets_acoustid_api = {
        owner = config.users.users.jordan.name;
      };
    };

    nixpkgs.config.permittedInsecurePackages = [
    ];

    environment.systemPackages =
      (with pkgs; [
        aspell
        efibootmgr
        fuse
        gutenprint # generic printer drivers
        jq
        kmonad
        lshw
        ntfs3g
        sqlite
      ])
      ++ (with pkgs-stable; [
        # wavebox
        ventoy
      ]);

    services.xserver = {
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

    ### Services ###

    # Kmonad configuration
    # see here before enabling:
    # https://github.com/kmonad/kmonad/blob/master/doc/installation.md#configurationnix
    services.kmonad = {
      enable = true;
      keyboards = {
        kmonad_keychron_k2_pro = {
          device = "/dev/input/by-id/usb-Keychron_Keychron_K2_Pro-event-kbd";
          config = builtins.readFile ../dotfiles/.config/kmonad/kmonad_keychron_k2_pro.kbd;
        };
        kmonad_havit = {
          device = "/dev/input/by-id/usb-1ea7_USB-HID_GamingKeyBoard-event-kbd";
          config = builtins.readFile ../dotfiles/.config/kmonad/kmonad_havit.kbd;
        };
        kmonad_winry315 = {
          device = "/dev/input/by-id/usb-Winry_Winry315-event-kbd";
          config = builtins.readFile ../dotfiles/.config/kmonad/kmonad_winry315.kbd;
        };
      };
    };

    ### Filesystem Mounts ###

    boot.supportedFilesystems = ["ntfs"];

    fileSystems."/mnt/music_hdd" = {
      device = "/dev/disk/by-uuid/5E74057374054EE9";
      fsType = "ntfs-3g";
      options = ["rw" "uid=1000"];
    };

    #    fileSystems."/mnt/music_ssd" = {
    #      device = "/dev/disk/by-uuid/7652D37D52D34093";
    #      fsType = "ntfs-3g";
    #      options = ["rw" "uid=1000"];
    #    };

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
          resolution = "1440p";
        };
        configurationLimit = 20;
      };
    };
  };
}
