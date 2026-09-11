{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  # Plasma Manager KDE Configuration
  imports = [
  ];

  # sops.secrets = {
  # };

  home.packages =
    (with pkgs; [
      fcast-client
      fcast-receiver
      grayjay
      iptvnator
      lsp-plugins # a collection of open source audio plugins
      mpv
      vlc
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
  services.flatpak = {
    enable = true;

    remotes = lib.mkOptionDefault [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      # {
      #   appId = "com.brave.Browser";
      #   origin = "flathub";
      # }
      "tv.plex.PlexDesktop"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    uninstallUnmanaged = false;
  };
}
