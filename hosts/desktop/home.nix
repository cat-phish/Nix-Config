{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: let
  acoustidApiKey = builtins.getEnv "BEETS_ACOUSTID_API";
in {
  # Plasma Manager KDE Configuration
  imports = [
    ../../modules/plasma-config/desktop/plasma-config.nix
    ../../modules/rclone/rclone-gdrivedesk.nix
    ../../modules/rclone/rclone-mediaserversmb.nix
    ../../modules/rclone/rclone-hetzner.nix
  ];

  home.packages =
    (with pkgs; [
      chromaprint
      python312Packages.pyacoustid
      python312Packages.discogs-client
      python312Packages.flask
      python312Packages.pylyrics
      python312Packages.pyacoustid
      python312Packages.pylast
      python312Packages.requests
    ])
    ++ (with pkgs-unstable; [
      # Add unstable packages here
    ]);

  programs.beets = {
    enable = true;
    package = pkgs.beets.override {
      pluginOverrides = {
        copyartifacts = {
          enable = true;
          propagatedBuildInputs = [pkgs.beetsPackages.copyartifacts];
        };
      };
    };
    settings = {
      directory = "/mnt/music_hdd/New/2 - Beets Sorted";
      library = "/mnt/music_hdd/New/2 - Beets Sorted/musiclibrary.blb";
      import.move = true;
      import.log = "/mnt/music_hdd/New/beets.log";

      plugins = ["lyrics" "chroma" "lastgenre" "fetchart" "discogs" "copyartifacts" "ftintitle" "fromfilename" "inline" "rewrite" "spotify" "export" "unimported"];

      paths.default = "$albumartist_sort/$album%aunique{} ($original_year) [$format]/%if{$multidisc,Disc $disc/}$track. $title";
      paths.singleton = "Non-Album/$artist/$title";
      paths.comp = "Compilations/$album%aunique{}/$track $title";
      # paths.albumtype.soundtrack = "Soundtracks/$album/$track $title";

      item_fields.multidisc = "1 if disctotal > 1 else 0";

      original_date = false;

      match.preferred = {
        countries = ["US" "GB|UK"];
        media = ["CD" "Digital Media|File"];
        original_year = true;
      };

      # replaygain = {
      #   backend = "gstreamer";
      #   auto = true;
      #   noclip = true;
      #   peak = true;
      # };

      lyrics = {
        auto = true;
        fallback = "No lyrics found";
      };

      acoustid.apikey = "$BEETS_ACOUSTID_API";

      lastgenre = {
        canonical = "";
        source = "artist";
        count = 3;
        separator = "; ";
      };

      copyartifacts.print_ignored = true;

      unimported = {
        ignore_extensions = ["jpg" "png"];
        ignore_subdirectories = ["NonMusic" "data" "temp"];
      };
    };
  };

  home.file = {
  };

  # xdg.configFile."rclone/rclone-main.conf".text = ''
  #   [gdrivedesk]
  #   type = drive
  #   scope = drive
  #   team =
  #
  #   [mediaserversmb]
  #   type = smb
  #   host = mediaserver.local
  #   user = media
  #
  #   [hetzner]
  #   type = sftp
  #   key_file = ~/.ssh/hetzner-storage
  #   shell_type = unix
  #
  #   [hetznercrypt]
  #   type = crypt
  #   remote = hetzner:/home/crypt
  # '';

  # # Systemd services TODO: fix mediasever mount
  # systemd.user.services = {
  #   rclone-gdrive-mount = {
  #     Unit = {
  #       Description = "Mounts gdrive with rclone";
  #       After = ["default.target"];
  #       Requires = ["default.target"];
  #     };
  #     Install = {
  #       WantedBy = ["default.target"];
  #     };
  #
  #     Service = let
  #       gdriveDir = "/home/jordan/gdrive";
  #     in {
  #       Type = "simple";
  #       ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${gdriveDir}";
  #       ExecStart = ''
  #         ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-main.conf \
  #           --vfs-cache-mode full \
  #         mount gdrivedesk:/ /home/jordan/gdrive
  #       '';
  #       ExecStop = "/run/current-system/sw/bin/fusermount -u ${gdriveDir}";
  #       Restart = "on-failure";
  #       RestartSec = "10s";
  #       EnvironmentFile = "/home/jordan/.env";
  #       Environment = ["PATH=/run/wrappers/bin/:$PATH"];
  #     };
  #   };
  #   rclone-mediaserver-mount = {
  #     Unit = {
  #       Description = "Mounts mediaserver with rclone";
  #       After = ["default.target"];
  #       Requires = ["default.target"];
  #     };
  #     Install = {
  #       WantedBy = ["default.target"];
  #     };
  #
  #     Service = let
  #       mediaserverDir = "/home/jordan/mediaserver";
  #     in {
  #       Type = "simple";
  #       ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${mediaserverDir}";
  #       ExecStart = ''
  #         ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-main.conf \
  #         mount mediaserversmb:/ /home/jordan/mediaserver
  #       '';
  #       ExecStop = "/run/current-system/sw/bin/fusermount -u ${mediaserverDir}";
  #       Restart = "on-failure";
  #       RestartSec = "10s";
  #       EnvironmentFile = "/home/jordan/.env";
  #       Environment = ["PATH=/run/wrappers/bin/:$PATH"];
  #     };
  #   };
  #   rclone-hetzner-mount = {
  #     Unit = {
  #       Description = "Mounts Hetzner Storage Box with rclone";
  #       After = ["default.target"];
  #       Requires = ["default.target"];
  #     };
  #     Install = {
  #       WantedBy = ["default.target"];
  #     };
  #
  #     Service = let
  #       hetznerDir = "/home/jordan/hetzner-storage";
  #     in {
  #       Type = "simple";
  #       ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${hetznerDir}";
  #       ExecStart = ''
  #         ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/rclone-main.conf \
  #         mount hetznercrypt: ${hetznerDir}
  #       '';
  #       ExecStop = "/run/current-system/sw/bin/fusermount -u ${hetznerDir}";
  #       Restart = "on-failure";
  #       RestartSec = "10s";
  #       EnvironmentFile = "/home/jordan/.env";
  #       Environment = ["PATH=/run/wrappers/bin/:$PATH"];
  #     };
  #   };
  # };
}
