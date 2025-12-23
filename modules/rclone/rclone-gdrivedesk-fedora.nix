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

  systemd. user.services = {
    rclone-gdrive-mount = {
      Unit = {
        Description = "Mounts gdrive with rclone";
        After = ["network-online.target"];
      };
      Install = {
        WantedBy = ["default.target"];
      };

      Service = let
        gdriveDir = "/home/jordan/gdrive";
        cacheDir = "/home/jordan/.cache/rclone-gdrive";
      in {
        Type = "notify";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p ${gdriveDir}"
          "${pkgs.coreutils}/bin/mkdir -p ${cacheDir}"
        ];
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount gdrivedesk:/ ${gdriveDir} \
            --config=%h/.config/rclone/rclone-gdrivedesk.conf \
            --vfs-cache-mode full \
            --vfs-cache-max-age 72h \
            --vfs-cache-max-size 10G \
            --cache-dir=${cacheDir} \
            --log-level INFO
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -u ${gdriveDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = "/home/jordan/.ssh/.env";
      };
    };
  };
}
