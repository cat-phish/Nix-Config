# Backlog

## Remove the gtk2 "broken" override for OnlyOffice

- **Added:** 2026-11-02
- **Deadline:** before NixOS 27.05 (gtk2 is scheduled for removal from nixpkgs; see https://github.com/NixOS/nixpkgs/issues/410814)

`onlyoffice-desktopeditors` (`modules/home/office-suite.nix`) runs in an FHS env that still depends on gtk2, which nixpkgs-unstable now marks as broken. To keep the build working, `home.nix` downgrades that to a warning:

```nix
nixpkgs.config.problems.handlers = {
  "gtk+".broken = "warn";
};
```

Note: this has to live in `home.nix`, not the `pkgs` import in `flake.nix`. Home Manager re-imports nixpkgs with `home.nix`'s `nixpkgs.config`, so the flake-level config is ignored for HM.

**To do:**

- [ ] Check whether upstream nixpkgs has dropped gtk2 from the OnlyOffice FHS env. If so, remove the override.
- [ ] Otherwise, move OnlyOffice off nixpkgs, e.g. the `org.onlyoffice.desktopeditors` Flatpak via nix-flatpak (Fedora hosts already load it; NixOS hosts would need `services.flatpak`).
- [ ] Remove the `problems.handlers` block from `home.nix` and confirm `home-manager build` succeeds without it.
