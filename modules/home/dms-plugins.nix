{
  config,
  lib,
  pkgs,
  ...
}: let
  # Dux Shell (formerly DankMaterialShell). `dms` itself comes from the duxlabs/dms
  # COPR on Fedora (desktop-niri.nix) and from the system config on NixOS; this module only syncs which
  # plugins are installed.
  # plugin_settings.json is intentionally NOT tracked: plugins can save API keys/tokens
  # and history there, and this repo is public (see backlog.md).
  lockfile = ../../dotfiles/.config/dms/plugins.lock.json;
  saveGuiPlugins = ../../dotfiles/.scripts/save-gui-plugins;
  applied = "${config.xdg.stateHome}/dms-plugins-applied.json";
in {
  # Make the installed plugins match the lockfile, including removing plugins that aren't in it
  # (--prune), so a GUI uninstall saved on one machine carries over. Runs only when the lockfile
  # differs from the last one applied here. Never fails the switch.
  # GUI installs/uninstalls/updates are saved to the lockfile by ~/.scripts/save-gui-plugins (run by
  # the rebuild/update scripts). If this machine has GUI changes that aren't saved yet, the sync is
  # skipped so they aren't undone.
  home.activation.dmsPluginsRestore = lib.hm.dag.entryAfter ["writeBoundary"] ''
    dms=""
    for c in /usr/bin/dms /run/current-system/sw/bin/dms /etc/profiles/per-user/${config.home.username}/bin/dms; do
      if [ -x "$c" ]; then dms="$c"; break; fi
    done
    if [ -n "$dms" ] && ! ${pkgs.diffutils}/bin/cmp -s ${lockfile} "${applied}"; then
      dmsPath="${lib.makeBinPath [pkgs.git pkgs.jq pkgs.coreutils pkgs.bash]}:$(dirname "$dms"):$PATH"
      pending=0
      env PATH="$dmsPath" XDG_STATE_HOME="${config.xdg.stateHome}" ${pkgs.bash}/bin/bash ${saveGuiPlugins} --dms-pending ${lockfile} || pending=$?
      if [ "$pending" = 0 ]; then
        warnEcho "DMS plugins were changed in the GUI and aren't saved; not syncing them. Run save-gui-plugins, then switch again."
      else
        prune="--prune"
        # Can't tell what changed locally: install only, never remove.
        [ "$pending" = 1 ] || prune=""
        if run env PATH="$dmsPath" "$dms" plugins restore $prune ${lockfile}; then
          if [ -z "''${DRY_RUN:-}" ] && [ "$pending" = 1 ]; then
            install -Dm644 ${lockfile} "${applied}"
          fi
        else
          warnEcho "dms plugins restore failed (offline?); will retry next switch"
        fi
      fi
    fi
  '';
}
