# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal Nix flake (cloned to `~/.nix`) that manages both full NixOS systems and standalone Home Manager on Fedora. There is no build/test suite; "building" means evaluating/applying the flake.

## Commands

```sh
# Apply Home Manager config (Fedora and NixOS). Output names are "<user>@<host>".
home-manager switch --flake ~/.nix#jordan@fedora-desktop
home-manager switch -b backup --flake ~/.nix#jordan@fedora-desktop   # if existing files block activation

# Apply NixOS system config (NixOS hosts only)
sudo nixos-rebuild switch --flake ~/.nix#nixos-desktop

# Check a change without activating
home-manager build --flake ~/.nix#jordan@fedora-desktop
nixos-rebuild build --flake ~/.nix#nixos-desktop
nix flake check            # evaluates all outputs; slow

# Update inputs
nix flake update [input-name]
```

Flakes only see git-tracked files: `git add` any new `.nix` module or dotfile before building, or evaluation will fail with "path does not exist".

`init.sh` is the interactive first-time bootstrap (OS/host detection, Fedora dnf/driver setup via `setup/*.sh`, Nix + Home Manager install, copying icons/themes/`.local/share`, first switch). It is not needed for day-to-day changes.

## Architecture

Fedora (niri + Dux Shell/DMS, standalone Home Manager) is the daily driver. The NixOS hosts run the same niri + DMS desktop; they're kept evaluating and building, but aren't used day to day.

**Flake outputs** (`flake.nix`), built with three helpers:
- `mkNixos "<host>"` = `configuration.nix` (shared system base: niri, DMS + dms-greeter, audio, user, sops) + `hosts/<host>-configuration.nix`, which imports `modules/nixos/*` and `modules/hardware-config/<host>-hardware.nix`.
- `mkServer "<host>"` = `server-configuration.nix` (headless base: SSH keys only, Tailscale, admin user) + `hosts/<host>-configuration.nix` + disko. Output: `agent-vm`, an isolated coding-agent VM on the Unraid server (agent tools in `modules/nixos/agent-tools.nix`). It's installed and deployed from the desktop (`nixos-anywhere`, `nixos-rebuild --target-host`); never connect to the server or VM yourself, give the user the commands.
- `mkHome { host; isNixos; }` = `home.nix` + `hosts/<host>-home.nix` + the nix-flatpak HM module. Outputs: `jordan@{fedora-desktop,fedora-laptop,nixos-desktop,nixos-laptop}`.

**Home Manager layers:**
- `home.nix`: user, stateVersion, HM nixpkgs config/overlays, repo git config; imports `modules/home/common.nix`.
- `modules/home/common.nix`: the bundles every host gets (communications, dev-environment, media, office, utilities, wine, syncthing, numen (voice control + dictation, see `docs/numen.md`), tailscale), base flatpaks, personal dotfiles (`.scripts`, `.img`, kmonad configs...), `nix.gc`, and Fedora-only bits guarded by `isNixos`.
- `modules/home/desktop-niri.nix`: niri config + scripts, portal config, DMS plugins (`dms-plugins.nix`; installed from the DMS GUI, recorded in `dotfiles/.config/dms/plugins.lock.json` by `.scripts/save-gui-plugins` and synced on switch with `--prune`, so GUI uninstalls carry over; `update-system` updates them all and commits the lockfile), the Vicinae launcher/clipboard on Mod+Space/Mod+Y (`app-vicinae.nix`: settings, theme, Raycast extensions; script commands in `dotfiles/.local/share/vicinae/scripts`; extensions are listed in `dotfiles/.config/vicinae/extensions.conf` and installed/updated/pruned by `.scripts/vicinae-extensions` from `update-system`; GUI installs/uninstalls are saved to it by `.scripts/save-gui-plugins`, see `docs/vicinae.md`), Mod+A opens the DMS AI Assistant, whose API key comes from `~/.ssh/dms.env` via a `dms.service` drop-in; KDE-apps-under-niri fixes (`niri-kde-apps.nix`), ntfy listener. Hosts set `my.niri.deviceConfig` (per-machine niri file) and optionally `my.niri.dmsSettings` (file under `dotfiles/.config/dms/`, linked out of store so the GUI can edit it).
- `hosts/<host>-home.nix`: only what's specific to that machine (extra bundles like `games.nix`/`app-beets.nix`, rclone mounts, services). Start new hosts from `hosts/_template-*.nix`, new bundles from `modules/home/_template.nix`.

To add a package everywhere, put it in a bundle imported by `common.nix`; for one machine, import the bundle (or add the package) in that host file.

**Special args available to modules:** `inputs`, `pkgs-stable` (nixos-24.11, for pinning packages that break on unstable), `nvim-config`, `emacs-config`, `talon-nix`, `isNixos` (bool, HM only) and `host` (HM only, e.g. `"fedora-laptop"`). `pkgs` is unstable with `allowUnfree`. Use `lib.mkIf isNixos` / `lib.mkIf (!isNixos)` for anything that only works on one OS. On Fedora, niri, dms and other system packages come from dnf/COPR, declared in Nix with `my.fedora.dnf` (see below).

**Fedora dnf packages:** declared with `my.fedora.dnf.{packages,coprs,repoFiles,ignore,swaps}` (`modules/home/fedora-dnf.nix`) in any bundle/host file, merged like Nix lists, plus `setup/dnf-saved.json` (manual installs saved by the capture step). `dotfiles/.scripts/dnf-sync` reads them with `nix eval`: `--save` (run by `update-system` before committing) offers manual `dnf install`s to save as common/host/ignore; `.scripts/fedora-install <pkg>...` runs `sudo dnf install` and then `dnf-sync --save <names>` for just those packages; `--apply` (run by `update-system` after `dnf upgrade` and by `init.sh` after the first switch) enables repos, installs missing packages and removes ones dropped since the last apply (snapshot in `~/.local/state/dnf-sync-applied.json`), each confirmed at a terminal prompt. See `docs/dnf.md`.

**Dotfiles:** `dotfiles/` mirrors `$HOME`. Files are linked selectively via `home.file` entries (in `common.nix`, `desktop-niri.nix` or host files), not wholesale. Large assets (`.icons`, `.themes`, `.local/share`) are copied by `init.sh` rather than managed by HM. `dotfiles/.talon/user/community` is a git submodule.

**Archive:** `archive/` holds code that isn't imported anywhere but is kept for reference: `archive/plasma/` (the old KDE Plasma + plasma-manager setup, with restore notes in `nixos-plasma.nix`) and `archive/legacy/` (old scripts, unused hosts/modules, the removed `ubuntu@ubuntu` output). Don't import from it; `git mv` a file back out to revive it.

**Secrets:** `secrets.yaml` is sops-encrypted (keys in `.sops.yaml`); managed with sops-nix (HM module in `home.nix`, NixOS module in `configuration.nix`), which defines no secrets yet. Never decrypt or print it.

## GUI-installed plugins

Some apps install plugins/extensions from their own GUI (today: DMS plugins, Vicinae extensions). Whenever we start managing another one, wire it up the same way so a GUI change on one machine reaches the others:

- Record the plugin list (with pinned versions where the app supports it) in a tracked file under `dotfiles/`.
- Add a save step to `dotfiles/.scripts/save-gui-plugins` (the rebuild/update scripts already run it). It merges this machine's GUI installs, updates **and uninstalls** into that file without undoing changes the other machine made.
- Tell the two apart with a "last applied" snapshot in `~/.local/state/<app>-...applied...`, written after each successful sync. Gone since the snapshot means uninstalled here. New and in neither file means installed here. In the file but not in the snapshot means added elsewhere: install it, don't drop it.
- Sync on switch or update, including removing what's no longer listed. If there are unsaved GUI changes, skip the sync so they aren't lost; never fail the switch.
- Document it in `docs/` and in the Architecture section above.

## Known breakage / gotchas

- The repo is public. `.githooks/pre-commit` runs `gitleaks` on staged changes and blocks commits containing secrets; `home.nix` activation sets `core.hooksPath = .githooks` (and `rebase.autoStash`) in `~/.nix` on every switch. DMS `plugin_settings.json` is gitignored for this reason.
- Insecure packages must be allow-listed in `permittedInsecurePackages` (in `configuration.nix` for NixOS, in `home.nix` for HM). `nixpkgs.config` in `home.nix` makes HM re-import nixpkgs, so the flake-level `pkgs` config doesn't apply to HM.
- Nix GUI apps on Fedora need Nix GPU drivers (`targets.genericLinux.gpu` in `common.nix`). If one fails with "Failed to create surface" or similar, run `nix-gpu-setup` (sudo; `update-system`/`update-home` do it automatically, `nix-rebuild-home` only warns).
- `home-manager build` has no `-o`; to keep a build for comparison use `nix build '.#homeConfigurations."jordan@<host>".activationPackage' -o <link>`.
