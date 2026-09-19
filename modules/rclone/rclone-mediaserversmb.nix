{
  pkgs,
  pkgs-stable,
  ...
}: {
  # SFTP config for large transfers
  xdg.configFile."rclone/rclone-mediaserver-sftp.conf".text = ''
    [mediaserver-sftp]
    type = sftp
    host = mediaserver
    key_file = ~/.ssh/id_ed25519
    use_insecure_cipher = false
  '';

  # SMB config for mounting
  xdg.configFile."rclone/rclone-mediaserver-smb.conf".text = ''
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
            --config=%h/.config/rclone/rclone-mediaserver-smb.conf \
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
