{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}:
# let
#   pname = "navibeat";
#   version = "1.0.34";
#
#   src = pkgs.fetchurl {
#     url = "https://github.com/nenadjokic/navibeat-linux/releases/download/v${version}/NaviBeat-linux-x86_64.AppImage";
#     # Get hash with: nix-prefetch-url https://github.com/nenadjokic/navibeat-linux/releases/download/v1.0.34/NaviBeat-linux-x86_64.AppImage
#     sha256 = "sha256-3b278vC/O5rG7p1xR8pG0yB/vX4l8yT+q9lK0mN1oP2="; # <-- replace with nix-prefetch-url output
#   };
#
#   appimageContents = pkgs.appimageTools.extractType2 {
#     inherit pname version src;
#     postExtract = ''
#       # Remove bundled libdbus to prevent SIGSEGV when Appearance is set to System
#       rm -f $out/vlc/libdbus-1.so*
#     '';
#   };
#
#   nixosWrapped = pkgs.appimageTools.wrapAppImage {
#     inherit pname version;
#     src = appimageContents;
#   };
#
#   navibeat-custom = pkgs.stdenv.mkDerivation {
#     inherit pname version;
#     dontUnpack = true;
#
#     installPhase = ''
#       mkdir -p $out/bin $out/share/applications$out/share/pixmaps
#
#       cat > $out/bin/navibeat <<EOF
#       #!/usr/bin/env bash
#       export _JAVA_AWT_WM_NONREPARENTING=1
#       export AWT_TOOLKIT=MToolkit
#       if [ -e /etc/NIXOS ]; then
#         exec "${nixosWrapped}/bin/navibeat" "\$@"
#       else
#         # On Fedora, run the extracted AppRun directly against host GPU/OpenGL drivers
#         exec "${appimageContents}/AppRun" "\$@"
#       fi
#       EOF
#       chmod +x $out/bin/navibeat
#
#       cp "${appimageContents}/NaviBeat.png" "$out/share/pixmaps/navibeat.png" 2>/dev/null || true
#
#       cat > $out/share/applications/navibeat.desktop <<EOF
#       [Desktop Entry]
#       Type=Application
#       Name=NaviBeat
#       Exec=$out/bin/navibeat
#       Icon=navibeat
#       Terminal=false
#       Categories=AudioVideo;Audio;Player;
#       EOF
#     '';
#   };
# in
{
  # Plasma Manager KDE Configuration
  imports = [
  ];

  # sops.secrets = {
  # };

  home.packages =
    (with pkgs; [
      fcast-client
      fcast-receiver
      feishin
      grayjay
      iptvnator
      lsp-plugins # a collection of open source audio plugins
      mpv
      plezy
      vlc
    ])
    ++ (with pkgs-stable; [
      ])
    ++ [
      inputs.navibeat.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

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
