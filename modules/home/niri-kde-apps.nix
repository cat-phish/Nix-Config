{
  config,
  lib,
  ...
}: {
  # Make KDE/Qt apps (Dolphin, Konsole, ...) behave under niri + DankMaterialShell.

  # Use the KDE platform theme (plasma-integration, installed via dnf) so Qt apps
  # take their palette from kdeglobals, i.e. DMS's DankMatugen color scheme, and
  # pick up changes live. Without it, Qt picks a dark palette from the portal but
  # KDE apps still use kdeglobals' text colors, which gives dark-on-dark text.
  # environment.d applies to D-Bus-activated apps too (e.g. Dolphin via FileManager1).
  systemd.user.sessionVariables.QT_QPA_PLATFORMTHEME = "kde";

  # Opening a KDE app D-Bus-activates kded6. Its gtkconfig module rewrites GTK
  # settings and the color-scheme gsetting from kdeglobals, which flips the whole
  # desktop to light. The look-and-feel auto switcher can swap themes too.
  # DMS manages these itself, so keep both modules from loading.
  xdg.configFile."kded6rc".text = ''
    [Module-device_automounter]
    autoload=false

    [Module-gtkconfig]
    autoload=false

    [Module-lookandfeelautoswitcher]
    autoload=false
  '';
}
