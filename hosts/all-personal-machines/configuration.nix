{
  config,
  lib,
  pkgs,
  pkgs-stable,
  # erosanix,
  ...
}: {
  imports = [
  ];
  options = {
    # Enable numlock on boot
    ncfg.services.numlock-on-tty = {
      enable = lib.mkEnableOption "Enable numlock";
    };
  };
  config = {
    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable IPP printer discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    hardware.printers = {
      ensurePrinters = [
        {
          name = "Brother_DCP-L2550DW_series";
          location = "Home";
          deviceUri = "dnssd://Brother%20DCP-L2550DW%20series._ipp._tcp.local/?uuid=e3248000-80ce-11db-8000-3c2af47e31d5";
          model = "drv:///sample.drv/generpcl.ppd";
          ppdOptions = {
            PageSize = "Letter";
          };
        }
      ];
      ensureDefaultPrinter = "Brother_DCP-L2550DW_series";
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than +20";
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
        };
        configurationLimit = 20;
      };
    };
    environment.systemPackages =
      (with pkgs; [
        aspell
        efibootmgr
        fd
        fuse
        gutenprint # generic printer drivers
        jq
        kmonad
        lshw
        lsp-plugins
        ntfs3g
        ripgrep
        sqlite
        traceroute
        wine
        wineasio
        winetricks
        wineWowPackages.full
        pkgs.pkgsi686Linux.alsa-plugins
        pkgs.pkgsi686Linux.libpulseaudio
        pkgs.pkgsi686Linux.openal
        # wineWowPackages.unstable
        # wineWowPackages.waylandFull
        # erosanix.packages.i686-linux.foobar2000
      ])
      ++ (with pkgs-stable; [
        ]);

    services.flatpak = {
      remotes = lib.mkOptionDefault [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      packages = [
        # {
        #   appId = "com.brave.Browser";
        #   origin = "flathub";
        # }
        "com.usebottles.bottles"
      ];
      update.auto.enable = false;
      uninstallUnmanaged = false;
    };

    # Enable numlock on boot
    systemd.services.numLockOnTty = {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        # /run/current-system/sw/bin/setleds -D +num < "$tty";
        ExecStart = lib.mkForce (pkgs.writeShellScript "numLockOnTty" ''
          for tty in /dev/tty{1..6}; do
              ${pkgs.kbd}/bin/setleds -D +num < "$tty";
          done
        '');
      };
    };
  };
}
