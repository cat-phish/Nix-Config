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
    ./app-vicinae.nix
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
    # Fedora: niri (Fedora repo), dms + greeter + calendar from the Dux Labs COPR. duxlabs/dms
    # pulls in duxlabs/dux-repo (greeter, calendar, quickshell) as a COPR dependency.
    # On NixOS these come from configuration.nix and this is ignored.
    my.fedora.dnf = {
      coprs = ["duxlabs/dms"];
      packages = [
        "niri"
        "dms"
        "dux-greeter"
        "dux-calendar"
        "qt6-qtwebsockets-devel" # QtWebSockets QML module for the DMS Home Assistant plugin (must match system Qt)
        "gnome-keyring-pam" # lets greetd unlock the login keyring with your password
      ];
      # Old avengemedia names. dux-calendar doesn't obsolete dankcalendar-git (both ship /usr/bin/dcal).
      swaps = {
        "dankcalendar-git" = "dux-calendar";
        "dms-greeter" = "dux-greeter";
      };
    };

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

    # Secrets for DMS plugins (e.g. OPENAI_API_KEY for the AI Assistant, Mod+A) come from
    # ~/.ssh/dms.env, outside the repo. A dedicated file on purpose: every DMS plugin runs in the
    # shell process and can read its environment, so keep only plugin keys here (not ~/.ssh/.env).
    # The leading "-" makes a missing file fine. Fedora's dms.service comes from the COPR rpm.
    xdg.configFile."systemd/user/dms.service.d/secrets.conf".text = ''
      [Service]
      EnvironmentFile=-%h/.ssh/dms.env
    '';

    # Launcher entries (Vicinae, fuzzel...) for DMS Settings. DMS ships none: its own .desktop
    # files are NoDisplay. To add a page, put `<tab> = "<Title>";` in `pages`; list the tab IDs
    # with `dms ipc call settings tabs`.
    xdg.desktopEntries = let
      mkEntry = name: exec: {
        inherit name exec;
        icon = "dev.duxlabs.shell";
        categories = ["Settings"];
        terminal = false;
      };
      pages = {
        # plugins = "Plugins";
      };
    in
      {dms-settings = mkEntry "DMS Settings" "dms ipc call settings focusOrToggle";}
      // lib.mapAttrs' (tab: title:
        lib.nameValuePair "dms-settings-${tab}"
        (mkEntry "DMS Settings: ${title}" "dms ipc call settings openWith ${tab}"))
      pages;

    # Desktop notifications from the media server's ntfy topic.
    # Secrets (MEDIASERVER_HOST, MEDIASERVER_NTFY_SERVER, MEDIASERVER_NTFY_AUTH_TOKEN)
    # come from ~/.ssh/.env, outside the repo.
    systemd.user.services.ntfy-listener = let
      # Own script so title/message stay quoted (ntfy runs the command through sh -c).
      notify = pkgs.writeShellScript "ntfy-notify" ''
        exec ${pkgs.libnotify}/bin/notify-send "[$NTFY_TOPIC] $NTFY_TITLE" "$NTFY_MESSAGE"
      '';
      # If the server answers a ping, hand over to ntfy (exec). Otherwise sleep 60s and exit,
      # so systemd retries: about 70s between checks when away from home.
      # The token goes through $NTFY_TOKEN, not --token, so it never shows up in ps.
      listener = pkgs.writeShellScript "ntfy-listener" ''
        if ${pkgs.iputils}/bin/ping -c 1 -W 2 "$MEDIASERVER_HOST" >/dev/null 2>&1; then
          export NTFY_TOKEN="$MEDIASERVER_NTFY_AUTH_TOKEN"
          exec ${pkgs.ntfy-sh}/bin/ntfy sub "$MEDIASERVER_NTFY_SERVER/Tracearr" ${notify}
        fi
        sleep 60
      '';
    in {
      Unit = {
        Description = "ntfy Desktop Notifications";
        After = ["graphical-session.target"];
      };
      Install.WantedBy = ["graphical-session.target"];
      Service = {
        EnvironmentFile = "%h/.ssh/.env";
        ExecStart = "${listener}";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
