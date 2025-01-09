{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  # Plasma Manager KDE Configuration
  imports = [./plasma-config.nix];

  home.packages =
    (with pkgs; [
      # Add desktop-specific packages here
    ])
    ++ (with pkgs-unstable; [
      # Add unstable packages here
    ]);

  home.file = {
    # "${config.xdg.configHome}/kmonad/kmonad_keychron_k2_pro.kbd" = {
    #   source = ../../dotfiles/.config/kmonad/kmonad_keychron_k2_pro.kbd;
    # };
    # "${config.xdg.configHome}/kmonad/kmonad_havit.kbd" = {
    #   source = ../../dotfiles/.config/kmonad/kmonad_havit.kbd;
    # };
    # "${config.xdg.configHome}/kmonad/kmonad_winry315.kbd" = {
    #   source = ../../dotfiles/.config/kmonad/kmonad_winry315.kbd;
    # };
  };

  xdg.configFile."rclone/rclone-main.conf".text = ''
    [gdrivedesk]
    type = drive
    scope = drive
    team =

    [mediaserversftp]
    type = sftp
    shell_type = unix
    md5sum_command = md5sum
    sha1sum_command = sha1sum

    [mediaserver]
    type = alias
    remote = mediaserversftp:/mnt/user
  '';
  systemd.user.services.rclone-gdrive-mount = {
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
        mount gdrivedesk:/ /home/jordan/gdrive
      '';
      ExecStop = "/run/current-system/sw/bin/fusermount -u ${gdriveDir}";
      Restart = "on-failure";
      RestartSec = "10s";
      EnvironmentFile = "/home/jordan/.env";
      Environment = ["PATH=/run/wrappers/bin/:$PATH"];
    };
  };
  systemd.user.services.rclone-mediaserver-mount = {
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
        mount mediaserver:/ /home/jordan/mediaserver
      '';
      ExecStop = "/run/current-system/sw/bin/fusermount -u ${mediaserverDir}";
      Restart = "on-failure";
      RestartSec = "10s";
      EnvironmentFile = "/home/jordan/.env";
      Environment = ["PATH=/run/wrappers/bin/:$PATH"];
    };
  };
  # systemd.user.services.rclone-gdrive-mount = {
  #   Unit = {
  #     Description = "Mounting gdrive via rclone";
  #     After = ["network-online.target"];
  #   };
  #   Service = {
  #     Type = "notify";
  #     ExecStartPre = "/run/current-system/sw/bin/mkdir -p /home/jordan/gdrive"; # Creates folder if didn't exist
  #     ExecStart = ''
  #       ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-main.conf mount
  #         --config=%h/.config/rclone/rclone.conf \
  # --log-level INFO \
  # --log-file /tmp/rclone-%i.log \
  # --umask 022 \
  # --allow-other \
  # --dir-cache-time 100h \
  # --poll-interval 15s \
  # --cache-dir=/home/jordan/.cache/rclone \
  # --vfs-cache-mode full \
  # --vfs-cache-max-size 100G \
  # --vfs-cache-max-age 24h \
  # --vfs-read-chunk-size 128M \
  # --vfs-read-chunk-size-limit off \
  # --vfs-read-ahead 128M \
  #         gdrive: /home/jordan/gdrive
  #     ''; # Mounts
  #     ExecStop = "/run/current-system/sw/bin/fusermount -u /home/jordan/gdrive"; # Dismounts
  #   };
  #   Install.WantedBy = ["default.target"];
  # };
}
