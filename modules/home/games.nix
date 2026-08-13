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

  home.file = {
  };
}
