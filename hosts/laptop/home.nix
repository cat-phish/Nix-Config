{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages =
    (with pkgs; [
      ])
    ++ (with pkgs-unstable; [
      ]);

  home.file = {
    "${config.xdg.configHome}/OpenRGB/" = {
      source = ../../dotfiles/.config/OpenRGB/;
      recursive = true;
    };
    "${config.xdg.configHome}/touchegg/touchegg.conf" = {
      source = ../../dotfiles/.config/touchegg/touchegg.conf;
    };
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

    [hetzner]
    type = sftp
    key_file = ~/.ssh/hetzner-storage
    shell_type = unix

    [hetznercrypt]
    type = crypt
    remote = hetzner:/home/crypt
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
          ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-main.conf \
          mount hetznercrypt: ${hetznerDir}
        '';
        ExecStop = "/run/current-system/sw/bin/fusermount -u ${hetznerDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = "/home/jordan/.env";
        Environment = ["PATH=/run/wrappers/bin/:$PATH"];
      };
    };
  };
}
