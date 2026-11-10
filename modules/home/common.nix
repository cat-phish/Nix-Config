{
  config,
  lib,
  isNixos,
  ...
}: {
  # Shared by every host (Fedora and NixOS). Imported from home.nix, so host files
  # only list what's specific to that machine.
  imports = [
    ./communications.nix
    ./dev-environment.nix
    ./fun-apps.nix
    ./media-playback.nix
    ./media-mgmt.nix
    ./office-suite.nix
    ./utilities.nix
    ./app-wine.nix
    ./app-foobar2000-wine-dependencies.nix
    ./app-syncthing.nix
    ./app-numen.nix
    ./app-tailscale.nix # Fedora only (guarded inside)
  ];

  # Fedora's zsh comes from dnf; on NixOS the system sets the login shell.
  home.sessionVariables.SHELL = lib.mkIf (!isNixos) "/usr/bin/zsh";

  # Non-NixOS: expose Nix mesa/GPU drivers at /run/opengl-driver so Nix GUI apps
  # (wgpu/Vulkan/GL, e.g. herdr-app) can create a window. After the first switch,
  # run once: sudo $(readlink -f ~/.nix-profile/bin/non-nixos-gpu-setup)
  targets.genericLinux.enable = lib.mkIf (!isNixos) true;
  targets.genericLinux.gpu.enable = lib.mkIf (!isNixos) true;

  # Fedora: stop imsettings from starting IBus at login. Under niri it launches
  # `ibus-daemon --xim` with GTK/QT_IM_MODULE=ibus, and IBus pops up a "should be
  # called from the desktop session in Wayland" notification. Hidden=true in a
  # user autostart entry overrides /etc/xdg/autostart/imsettings-start.desktop.
  xdg.configFile."autostart/imsettings-start.desktop" = lib.mkIf (!isNixos) {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Input Method starter
      Hidden=true
    '';
  };

  # Flatpaks via nix-flatpak. On NixOS this needs services.flatpak.enable (configuration.nix).
  services.flatpak = {
    enable = true;
    remotes = lib.mkOptionDefault [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      "com.usebottles.bottles"
      "tv.kodi.Kodi"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
    uninstallUnmanaged = false;
  };

  home.file = {
    ".apps/appimages/appimages.conf".source = ../../dotfiles/.apps/appimages/appimages.conf;
    ".scripts" = {
      source = ../../dotfiles/.scripts;
      recursive = true;
    };
    ".python-scripts" = {
      source = ../../dotfiles/.python-scripts;
      recursive = true;
    };
    ".img" = {
      source = ../../dotfiles/.img;
      recursive = true;
    };
    "${config.xdg.configHome}/kmonad" = {
      source = ../../dotfiles/.config/kmonad;
      recursive = true;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
