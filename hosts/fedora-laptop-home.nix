{pkgs, ...}: {
  imports = [
    ../modules/home/desktop-niri.nix
    ../modules/rclone/rclone-gdrivedesk.nix
    ../modules/rclone/rclone-mediaserversmb.nix
    # ../modules/rclone/rclone-hetzner.nix
    # ../modules/home/c-sharp-dev.nix
  ];

  my.niri.deviceConfig = ../dotfiles/.config/niri/laptop-config.kdl;
  my.niri.dmsSettings = "laptop-settings.json";

  # The X1's mic DSP compressor (Dmic0 Capture DRC) lifts room noise to peaks
  # of -28 to -20 dBFS, above the default -38, so dictation never auto-stopped.
  # See docs/dictation.md.
  my.dictation.speechThresholdDbfs = -15.0;

  # Fingerprint sudo (init.sh adds pam_fprintd to /etc/pam.d/sudo)
  my.fedora.dnf.packages = ["fprintd" "fprintd-pam"];

  home.packages = with pkgs; [
    firefox
    kmonad
    sfml
  ];

  # On Fedora kmonad runs as a user service (NixOS uses services.kmonad instead).
  systemd.user.services.kmonad = {
    Unit = {
      Description = "KMonad keyboard remapping";
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.kmonad}/bin/kmonad %h/.nix/dotfiles/.config/kmonad/kmonad_thinkpad_x1_carbon_gen12.kbd";
      Restart = "on-failure";
    };
    Install.WantedBy = ["default.target"];
  };
}
