{
  config,
  lib,
  pkgs,
  isNixos ? false,
  ...
}: {
  # Tailscale on non-NixOS hosts (Fedora).
  # The daemon (tailscaled) is installed and run system-wide via dnf, because it
  # needs root for the TUN device/routes; Home Manager only adds the user-level
  # pieces. One-time prerequisite: `sudo tailscale set --operator=$USER`.
  config = lib.mkIf (!isNixos) {
    # Tray icon, started with the graphical (niri) session.
    systemd.user.services.tailscale-systray = {
      Unit = {
        Description = "Tailscale system tray";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target" "dms.service"];
      };
      Service = {
        ExecStart = "/usr/bin/tailscale systray";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # Exit-node toggle/picker used by niri keybinds (Mod+X / Mod+Shift+X).
    home.file.".config/niri/scripts/tailscale-exit-node.sh" = {
      source = ../../dotfiles/.config/niri/scripts/tailscale-exit-node.sh;
      executable = true;
    };
  };
}
