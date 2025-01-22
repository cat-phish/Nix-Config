{
  pkgs,
  pkgs-unstable,
  ...
}: {
  xdg.configFile."rclone/rclone-mediaserversmb.conf".text = ''
    [mediaserversmb]
    type = smb
    host = mediaserver.local
    user = media
  '';

  systemd.user.services = {
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
          ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-mediaserversmb.conf \
          mount mediaserversmb:/ /home/jordan/mediaserver
        '';
        ExecStop = "/run/current-system/sw/bin/fusermount -u ${mediaserverDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = "/home/jordan/.env/.env";
        Environment = ["PATH=/run/wrappers/bin/:$PATH"];
      };
    };
  };
}
