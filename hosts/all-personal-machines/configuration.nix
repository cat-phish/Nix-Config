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
        # theme = pkgs.stdenv.mkDerivation {
        #   pname = "bsol-grub-theme";
        #   version = "1.0";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "harishnkr";
        #     repo = "bsol";
        #     rev = "v1.0";
        #     hash = "sha256-sUvlue+AXW6VkVYy3WOUuSt548b6LoDpJmQPbgcZDQw=";
        #   };
        #   installPhase = "cp -r customize/nixos $out";
        # };
        theme = pkgs.fetchFromGitHub {
          owner = "harishnkr";
          repo = "bsol";
          rev = "v1.0"; # commit number
          sha256 = "sha256-sUvlue+AXW6VkVYy3WOUuSt548b6LoDpJmQPbgcZDQw="; # attempt build with this value empty to get the hash
        };
      };
    };
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
