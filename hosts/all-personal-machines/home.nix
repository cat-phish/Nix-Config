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

      #beets
      beets
      python312Packages.discogs-client
      python312Packages.flask
      python312Packages.pyacoustid
      python312Packages.pylast
      python312Packages.requests

      neofetch
      mpv
      pinta
      vlc
      yt-dlp
    ])
    ++ (with pkgs-unstable; [
      google-chrome
      # wavebox
    ]);

  home.file = {
    # Add or override desktop-specific files here
    # Recursively adds dotfiles from ~/.nix/dotfiles/config/
  };
  # Add any laptop-specific configurations here
}
