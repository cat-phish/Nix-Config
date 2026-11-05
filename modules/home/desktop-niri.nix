{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.niri;
in {
  # niri + DMS (Dux Shell) desktop layer, shared by Fedora and NixOS.
  # niri and dms themselves come from dnf/COPR on Fedora and from configuration.nix on NixOS.
  imports = [
    ./niri-kde-apps.nix
    ./dms-plugins.nix
  ];

  options.my.niri = {
    deviceConfig = lib.mkOption {
      type = lib.types.path;
      description = "Per-machine niri config (outputs, input devices), linked to ~/.config/niri/device-config.kdl.";
      example = lib.literalExpression "../dotfiles/.config/niri/laptop-config.kdl";
    };
    dmsSettings = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        File name under dotfiles/.config/dms/ to link as ~/.config/dms/settings.json.
        Linked out of the store so DMS can still edit it from the GUI. null leaves it unmanaged.
      '';
      example = "laptop-settings.json";
    };
  };

  config = {
    home.file =
      {
        ".config/niri/config.kdl".source = ../../dotfiles/.config/niri/config.kdl;
        ".config/niri/device-config.kdl".source = cfg.deviceConfig;
        ".config/niri/scripts/arrange-columns.sh" = {
          source = ../../dotfiles/.config/niri/scripts/arrange-columns.sh;
          executable = true;
        };
        ".config/niri/scripts/focus_keepassxc.sh".source = ../../dotfiles/.config/niri/scripts/focus_keepassxc.sh;
        ".config/niri/scripts/syncthingtray_startup_delay.sh".source = ../../dotfiles/.config/niri/scripts/syncthingtray_startup_delay.sh;
        "${config.xdg.configHome}/xdg-desktop-portal" = {
          source = ../../dotfiles/.config/xdg-desktop-portal;
          recursive = true;
        };
      }
      // lib.optionalAttrs (cfg.dmsSettings != null) {
        ".config/dms/settings.json".source =
          config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/.nix/dotfiles/.config/dms/${cfg.dmsSettings}";
      };

    # Desktop notifications from the media server's ntfy topic.
    # Secrets (NTFY_AUTH_TOKEN, MEDIASERVER_HOST) come from ~/.ssh/.env, outside the repo.
    systemd.user.services.ntfy-listener = {
      Unit = {
        Description = "ntfy Desktop Notifications";
        After = ["graphical-session.target"];
      };
      Install.WantedBy = ["graphical-session.target"];
      Service = {
        EnvironmentFile = "%h/.ssh/.env";
        # If the server answers a ping, hand over to ntfy (exec). Otherwise sleep 60s and exit,
        # so systemd retries: about 70s between checks when away from home.
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c ' \
            if ${pkgs.iputils}/bin/ping -c 1 -W 2 "''${MEDIASERVER_HOST}" >/dev/null 2>&1; then \
              exec ${pkgs.ntfy-sh}/bin/ntfy sub \
                --token "''${NTFY_AUTH_TOKEN}" \
                "http://''${MEDIASERVER_HOST}:3924/Tracearr" \
                "${pkgs.libnotify}/bin/notify-send \"[\$$NTFY_TOPIC] \$$NTFY_TITLE\" \"\$$NTFY_MESSAGE\""; \
            else \
              sleep 60; \
            fi \
          '
        '';
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
