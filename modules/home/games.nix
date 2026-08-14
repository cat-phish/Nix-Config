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
      steam
      zenity

      # Standalone Emulators
      dolphin-emu
      pcsx2
      rpcs3

      # RetroArch with specific libretro cores baked in
      (retroarch.override {
        cores = with libretro; [
          snes9x
          mupen64plus
          nestopia
          pcsx-rearmed
          genesis-plus-gx
        ];
      })
    ])
    ++ (with pkgs-stable; [
      ]);

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
      "net.lutris.Lutris"
      "com.steamgriddb.steam-rom-manager"
      # "org.winehq.Wine"
      # "org.winehq.Wine.gecko"
      # "org.winehq.Wine.mono"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    uninstallUnmanaged = false;
  };

  home.file = {
  };
}
