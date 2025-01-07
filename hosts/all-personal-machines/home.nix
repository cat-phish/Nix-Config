{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  # nixpkgs.config.allowUnfree = true;
  home.packages =
    (with pkgs; [
      activate-linux
      audacity
      chirp
      deskreen

      #beets
      beets
      beetsPackages.copyartifacts
      python312Packages.discogs-client
      python312Packages.flask
      python312Packages.pyacoustid
      python312Packages.pylast
      python312Packages.requests

      hypnotix
      libreoffice-fresh
      mpv
      multiviewer-for-f1
      neofetch
      pinta
      vlc
      yt-dlp
    ])
    ++ (with pkgs-unstable; [
      google-chrome
      # wavebox
    ]);

  home.file = {
    "${config.xdg.configHome}/kmonad" = {
      source = ../../dotfiles/.config/kmonad;
      recursive = true;
    };
  };
  # Add any laptop-specific configurations here
}
