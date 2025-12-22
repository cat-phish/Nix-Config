{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
  ];

  home.file = {
    ".local/bin/talon" = {
      source = ../../dotfiles/.local/bin/talon;
    };
    # ".local/share/applications/talon.desktop" = {
    #   source = ../../dotfiles/.local/share/applications/talon.desktop;
    # };
    ".local/share/applications/talon.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Talon
        Comment=Dictation Software
        Exec=${config.home.homeDirectory}/.local/bin/talon
        Icon=${config.home.homeDirectory}/.img/talon.png
        Categories=Accessibility;
        Keywords=dictation;accessibility;
        Terminal=false
        StartupNotify=false
      '';
    };
    ".talon/user" = {
      source = ../../dotfiles/.talon/user;
      recursive = true;
    };
  };
}
