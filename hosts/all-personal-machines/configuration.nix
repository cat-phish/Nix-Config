{
  config,
  lib,
  pkgs,
  pkgs-unstable,
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
    # Bootloader.
    #boot.loader.grub.enable = true;
    #boot.loader.grub.device = "nodev";
    #boot.loader.grub.useOSProber = true;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    # boot.loader = {
    #   timeout = 5;
    #
    #   efi = {
    #     efiSysMountPoint = "/boot";
    #     canTouchEfiVariables = true;
    #   };
    #
    #   grub = {
    #     enable = true;
    #     version = 2;
    #
    #     efiSupport = true;
    #     efiInstallAsRemovable = true; # Otherwise /boot/EFI/BOOT/BOOTX64.EFI isn't generated
    #     devices = ["nodev"];
    #     extraEntriesBeforeNixOS = true;
    #     extraEntries = ''
    #       menuentry "Reboot" {
    #         reboot
    #       }
    #       menuentry "Poweroff" {
    #         halt
    #       }
    #     '';
    #   };
    # };
    environment.systemPackages =
      (with pkgs; [
        aspell
        efibootmgr
        fd
        fuse
        kmonad
        lsp-plugins
        ripgrep
        sqlite
      ])
      ++ (with pkgs-unstable; [
        ]);

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
