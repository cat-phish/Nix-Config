{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: {
  # Plasma Manager KDE Configuration
  imports = [
    ../../modules/plasma-config/desktop/plasma-config.nix
    ../../modules/rclone/rclone-gdrivedesk.nix
    ../../modules/rclone/rclone-mediaserversmb.nix
    ../../modules/rclone/rclone-hetzner.nix
    # inputs.sops-nix.homeManagerModules.sops
  ];

  # sops.secrets = {
  #   beets_acoustid_api = {};
  #   env_file = {};
  # };

  home.packages =
    (with pkgs; [
      calibre
      chromaprint
      kid3-kde
      python312Packages.pyacoustid
      python312Packages.discogs-client
      python312Packages.flask
      python312Packages.pylyrics
      python312Packages.pyacoustid
      python312Packages.pylast
      python312Packages.requests
      qbittorrent
    ])
    ++ (with pkgs-stable; [
      ]);

  programs.beets = {
    enable = true;
    package = pkgs-stable.beets.override {
      pluginOverrides = {
        copyartifacts = {
          enable = true;
          propagatedBuildInputs = [pkgs-stable.beetsPackages.copyartifacts];
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

      # acoustid.apikey = "$(cat ${config.sops.secrets."beets_acoustid_api".path})";

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
    # ".ssh/.env".text = "cat ${config.sops.secrets."env_file".path}";
  };
}
