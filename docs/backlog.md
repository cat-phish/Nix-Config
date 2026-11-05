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

## Audit other temporary workarounds

- **Added:** 2026-11-02

Like the gtk2 override, the config has other workarounds that were meant to be temporary and may no longer be needed. For each one, check whether it still applies, then remove it or record why it stays (ideally with an upstream issue link in a comment).

Found in a quick scan on 2026-11-02 (may be incomplete):

- [ ] `flake.nix`: overlay disabling `python312Packages.anyio` tests (`doCheck = false`)
- [ ] `home.nix`: overlay disabling `pyopenjtalk-plus` tests (Python 3.14 / pybind11 regex mismatch)
- [x] `modules/home/app-fcast-sender.nix`: `doCheck = false` (module archived; fcast comes from Flatpak)
- [ ] `permittedInsecurePackages`: `ventoy-1.1.07` (`flake.nix`, both `pkgs` and `pkgs-stable`), `electron-40.10.5` (`home.nix`), plus the lists in `configuration.nix` and `hosts/*-configuration.nix`
- [ ] Packages pinned to `pkgs-stable` (nixos-24.11, which is EOL): `calibre` (media-mgmt), `nerdfonts` (dev-environment; replaced by `nerd-fonts.*` on unstable), `audacity` and `rssguard` (utilities), `rpcs3` (games), wine packages (app-wine, app-foobar2000-wine-dependencies), `cudatoolkit` (`modules/nixos/nvidiaGPU-desktop.nix`), `ventoy` (nixos-desktop). Try each on unstable; if none remain, consider dropping the `nixpkgs-stable` input or bumping it to a current release.
- [ ] `modules/home/utilities.nix`: `winboat` disabled for a dependency issue (the commented-out flake input lines were removed in the Nov 2026 refactor)
- [ ] `modules/home/app-beets.nix`: `lyrics` and `spotify` plugins removed as "temp not working"
- [x] `flake.nix`: `# inherit system; # TODO: remove?` comments in the NixOS configs
- [ ] Search again for `TODO`, `tmp`, `temp`, `doCheck`, `broken`, `overrideAttrs`, and commented-out imports/packages

## Review and refactor the whole config

- **Added:** 2026-11-02

The config has grown piece by piece and has some dead code and inconsistencies. Review it as a whole and clean it up. Starting points:

- [x] Fix or delete the `homeConfigurations."ubuntu@ubuntu"` output, which points to missing files and breaks `nix flake check`
- [x] Decide what to do with `hosts/all-personal-machines-{home,configuration}.nix`, which no active output imports: merge the useful parts into shared modules or delete them
- [x] Reduce repetition in `flake.nix` (four near-identical `homeConfigurations` and two `nixosConfigurations`), e.g. with a `mkHome`/`mkHost` helper
- [ ] Consolidate nixpkgs config (`allowUnfree`, `permittedInsecurePackages`, overlays, `problems.handlers`), which is currently spread across `flake.nix`, `home.nix`, `configuration.nix`, and host files. Note the gotcha above: `nixpkgs.config` in `home.nix` makes HM ignore the flake-level `pkgs` config
- [ ] `home.nix` sets `nixpkgs.config.home-manager.useGlobalPkgs`, which isn't a real option in that location; check what was intended
- [ ] Either finish the sops setup (mostly commented out) or remove it; Fedora also loads `agenix`, so pick one secrets tool
- [x] Prune old dated `plasma-config` snapshots, which git history already covers (whole Plasma setup moved to `archive/plasma/`, Nov 2026)
- [ ] Review the `modules/home/*` bundles for overlap and for packages that are no longer used
- [ ] Get `nix flake check` passing (the `emacs-config` input needs SSH access) so it can be used to verify future changes
- [x] Update `CLAUDE.md` to match the refactored structure
