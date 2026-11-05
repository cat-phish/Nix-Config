{pkgs, ...}: {
  imports = [
    ../modules/home/desktop-niri.nix
    ../modules/home/app-beets.nix
    ../modules/home/android-tools.nix
    ../modules/home/games.nix
    ../modules/home/app-talon.nix
    ../modules/home/app-wireguard-tray.nix
    ../modules/rclone/rclone-gdrivedesk.nix
    ../modules/rclone/rclone-mediaserversmb.nix
    # ../modules/rclone/rclone-hetzner.nix
  ];

  my.niri.deviceConfig = ../dotfiles/.config/niri/desktop-config.kdl;
  # my.niri.dmsSettings = "desktop-settings.json"; # see backlog.md

  home.packages = with pkgs; [
    dotool
    chromaprint
    kid3-kde
    python312Packages.pyacoustid
    python312Packages.discogs-client
    python312Packages.flask
    python312Packages.pylyrics
    python312Packages.pylast
    python312Packages.requests
    qbittorrent
    zsh
  ];

  services.flatpak.packages = [
    "org.fcast.Sender"
  ];

  # dotool daemon for input automation (used by numen)
  systemd.user.services.dotool = {
    Unit = {
      Description = "dotool daemon for input automation";
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.dotool}/bin/dotoold";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
