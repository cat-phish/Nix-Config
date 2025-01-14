{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages =
    (with pkgs; [
      # Add desktop-specific packages here
    ])
    ++ (with pkgs-unstable; [
      # Add unstable packages here
    ]);

  home.file = {
    # Add or override desktop-specific files here
  };
  xdg.configFile."rclone/rclone-main.conf".text = ''
    [gdrivelap]
    type = drive
    scope = drive
    team =

    [mediaserversmb]
    type = smb
    host = mediaserver.local
    user = media
  '';

  # Systemd services TODO: fix mediasever mount
  systemd.user.services = {
    rclone-gdrive-mount = {
      Unit = {
        Description = "Mounts gdrive with rclone";
        After = ["default.target"];
        Requires = ["default.target"];
      };
      Install = {
        WantedBy = ["default.target"];
      };

      Service = let
        gdriveDir = "/home/jordan/gdrive";
      in {
        Type = "simple";
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${gdriveDir}";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-main.conf \
            --vfs-cache-mode full \
          mount gdrivelap:/ /home/jordan/gdrive
        '';
        ExecStop = "/run/current-system/sw/bin/fusermount -u ${gdriveDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = "/home/jordan/.env";
        Environment = ["PATH=/run/wrappers/bin/:$PATH"];
      };
    };
    rclone-mediaserver-mount = {
      Unit = {
        Description = "Mounts mediaserver with rclone";
        After = ["default.target"];
        Requires = ["default.target"];
      };
      Install = {
        WantedBy = ["default.target"];
      };

      Service = let
        mediaserverDir = "/home/jordan/mediaserver";
      in {
        Type = "simple";
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${mediaserverDir}";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-main.conf \
          mount mediaserversmb:/ /home/jordan/mediaserver
        '';
        ExecStop = "/run/current-system/sw/bin/fusermount -u ${mediaserverDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = "/home/jordan/.env";
        Environment = ["PATH=/run/wrappers/bin/:$PATH"];
      };
    };
  };
}
