{
  pkgs,
  pkgs-unstable,
  ...
}: {
  xdg.configFile."rclone/rclone-gdrivelap.conf".text = ''
    [gdrivelap]
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
          ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-gdrivelap.conf \
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
  };
}
