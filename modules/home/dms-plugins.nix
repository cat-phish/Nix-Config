{
  config,
  lib,
  pkgs,
  ...
}: let
  # Dux Shell (formerly DankMaterialShell). `dms` itself comes from the
  # avengemedia/dms COPR, not Nix; this module only syncs plugins + their settings.
  repoDir = "${config.home.homeDirectory}/.nix/dotfiles/.config/dms";
  lockfile = ../../dotfiles/.config/dms/plugins.lock.json;
in {
  # Editable: points into the git checkout, so changes made in the DMS GUI show up as repo diffs.
  xdg.configFile."dms/plugin_settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repoDir}/plugin_settings.json";

  # Install/pin plugins from the lockfile. Runs only when the lockfile hash changes; never fails the switch.
  # No --prune, so plugins installed locally but not in the lockfile are kept.
  home.activation.dmsPluginsRestore = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -x /usr/bin/dms ]; then
      stamp="${config.xdg.stateHome}/dms-plugins-lock.sha256"
      want=$(${pkgs.coreutils}/bin/sha256sum ${lockfile} | ${pkgs.coreutils}/bin/cut -d' ' -f1)
      if [ "$(cat "$stamp" 2>/dev/null)" != "$want" ]; then
        if run env PATH="${pkgs.git}/bin:/usr/bin:$PATH" /usr/bin/dms plugins restore ${lockfile}; then
          if [ -z "''${DRY_RUN:-}" ]; then
            mkdir -p "$(dirname "$stamp")"
            echo "$want" > "$stamp"
          fi
        else
          warnEcho "dms plugins restore failed (offline?); will retry next switch"
        fi
      fi
    fi
  '';

  # After installing/updating plugins on either machine: run this, then commit.
  home.packages = [
    (pkgs.writeShellScriptBin "dms-plugins-lock" ''
      exec /usr/bin/dms plugins lock -o "$HOME/.nix/dotfiles/.config/dms/plugins.lock.json"
    '')
  ];
}
