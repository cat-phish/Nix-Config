{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nvidiaGPU.nix
    inputs.sops-nix.nixosModules.sops
  ];
  config = {
    networking.hostName = "jordans-desktop";
    sops.secrets = {
      beets_acoustid_api = {
        owner = config.users.users.jordan.name;
      };
    };
    environment.systemPackages =
      (with pkgs; [
        ])
      ++ (with pkgs-stable; [
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

    ### Bootloader ###

    boot.loader = {
      grub = {
        darkmatter-theme = {
          resolution = "1440p";
        };
      };
    };
  };
}
