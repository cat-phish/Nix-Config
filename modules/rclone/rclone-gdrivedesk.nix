{
  pkgs,
  pkgs-stable,
  ...
}: {
  xdg.configFile."rclone/rclone-gdrivedesk.conf".text = ''
    [gdrivedesk]
    type = drive
    scope = drive
    team =
  '';

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
          ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-gdrivedesk.conf \
            --vfs-cache-mode full \
          mount gdrivedesk:/ /home/jordan/gdrive
        '';
        ExecStop = "/run/current-system/sw/bin/fusermount -u ${gdriveDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = "/home/jordan/.ssh/.env";
        Environment = ["PATH=/run/wrappers/bin/:$PATH"];
      };
    };
  };
}
