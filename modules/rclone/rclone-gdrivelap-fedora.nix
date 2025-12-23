{
  pkgs,
  pkgs-stable,
  ...
}: {
  xdg.configFile."rclone/rclone-gdrivelap.conf".text = ''
    [gdrivelap]
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
      in {
        Type = "notify";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${gdriveDir}";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount gdrivelap:/ ${gdriveDir} \
            --config=%h/.config/rclone/rclone-gdrivelap.conf \
            --vfs-cache-mode full \
            --vfs-cache-max-age 72h \
            --vfs-cache-max-size 10G \
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
