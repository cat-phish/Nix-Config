{
  pkgs,
  pkgs-stable,
  ...
}: {
  xdg.configFile."rclone/rclone-hetzner.conf".text = ''
    [hetzner]
    type = sftp
    key_file = ~/.ssh/hetzner-storage
    shell_type = unix

    [hetznercrypt]
    type = crypt
    remote = hetzner:/home/crypt
  '';

  systemd.user.services = {
    rclone-hetzner-mount = {
      Unit = {
        Description = "Mounts Hetzner Storage Box with rclone";
        After = ["default.target"];
        Requires = ["default.target"];
      };
      Install = {
        WantedBy = ["default.target"];
      };

      Service = let
        hetznerDir = "/home/jordan/hetzner-storage";
      in {
        Type = "simple";
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${hetznerDir}";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-hetzner.conf \
          mount hetznercrypt: ${hetznerDir}
        '';
        ExecStop = "/run/current-system/sw/bin/fusermount -u ${hetznerDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = "/home/jordan/.env/.env";
        Environment = ["PATH=/run/wrappers/bin/:$PATH"];
      };
    };
  };
}
