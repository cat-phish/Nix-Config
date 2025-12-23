{
  pkgs,
  pkgs-stable,
  ...
}: {
  xdg.configFile."rclone/rclone-mediaserversmb.conf".text = ''
    [mediaserversmb]
    type = smb
  '';
  # user = media
  # host = mediaserver.local

  systemd.user.services = {
    rclone-mediaserver-mount = {
      Unit = {
        Description = "Mounts mediaserver with rclone";
        After = ["network-online.target"];
      };
      Install = {
        WantedBy = ["default.target"];
      };

      Service = let
        mediaserverDir = "/home/jordan/mediaserver";
        cacheDir = "/home/jordan/.cache/rclone-mediaserver";
      in {
        Type = "simple";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p ${mediaserverDir}"
          "${pkgs.coreutils}/bin/mkdir -p ${cacheDir}"
        ];
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount mediaserversmb:/ ${mediaserverDir} \
            --config=%h/.config/rclone/rclone-mediaserversmb.conf \
            --vfs-cache-mode full \
            --vfs-cache-max-age 72h \
            --cache-dir=${cacheDir} \
            --log-level INFO
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -u ${mediaserverDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = "/home/jordan/.ssh/.env";
      };
    };
  };
}
