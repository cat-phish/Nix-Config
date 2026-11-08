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
- `modules/home/common.nix`: the bundles every host gets (communications, dev-environment, media, office, utilities, wine, syncthing, numen, tailscale), base flatpaks, personal dotfiles (`.scripts`, `.img`, kmonad configs...), `nix.gc`, and Fedora-only bits guarded by `isNixos`.
- `modules/home/desktop-niri.nix`: niri config + scripts, portal config, DMS plugins (`dms-plugins.nix`), KDE-apps-under-niri fixes (`niri-kde-apps.nix`), ntfy listener. Hosts set `my.niri.deviceConfig` (per-machine niri file) and optionally `my.niri.dmsSettings` (file under `dotfiles/.config/dms/`, linked out of store so the GUI can edit it).
- `hosts/<host>-home.nix`: only what's specific to that machine (extra bundles like `games.nix`/`app-beets.nix`, rclone mounts, services). Start new hosts from `hosts/_template-*.nix`, new bundles from `modules/home/_template.nix`.

To add a package everywhere, put it in a bundle imported by `common.nix`; for one machine, import the bundle (or add the package) in that host file.

**Special args available to modules:** `inputs`, `pkgs-stable` (nixos-24.11, for pinning packages that break on unstable), `nvim-config`, `emacs-config`, `talon-nix`, and `isNixos` (bool, HM only). `pkgs` is unstable with `allowUnfree`. Use `lib.mkIf isNixos` / `lib.mkIf (!isNixos)` for anything that only works on one OS. On Fedora, niri, dms and some system packages come from dnf/COPR (`init.sh`), not Nix.

**Dotfiles:** `dotfiles/` mirrors `$HOME`. Files are linked selectively via `home.file` entries (in `common.nix`, `desktop-niri.nix` or host files), not wholesale. Large assets (`.icons`, `.themes`, `.local/share`) are copied by `init.sh` rather than managed by HM. `dotfiles/.talon/user/community` is a git submodule.

**Archive:** `archive/` holds code that isn't imported anywhere but is kept for reference: `archive/plasma/` (the old KDE Plasma + plasma-manager setup, with restore notes in `nixos-plasma.nix`) and `archive/legacy/` (old scripts, unused hosts/modules, the removed `ubuntu@ubuntu` output). Don't import from it; `git mv` a file back out to revive it.

**Secrets:** `secrets.yaml` is sops-encrypted (keys in `.sops.yaml`); managed with sops-nix (HM module in `home.nix`, NixOS module in `configuration.nix`), which defines no secrets yet. Never decrypt or print it.

## Known breakage / gotchas

- `emacs-config` is a `git+ssh` input; evaluating the flake requires GitHub SSH access.
- The repo is public. `.githooks/pre-commit` runs `gitleaks` on staged changes and blocks commits containing secrets; `home.nix` activation sets `core.hooksPath = .githooks` (and `rebase.autoStash`) in `~/.nix` on every switch. DMS `plugin_settings.json` is gitignored for this reason.
- Insecure packages must be allow-listed in `permittedInsecurePackages` (in `configuration.nix` for NixOS, in `home.nix` for HM). `nixpkgs.config` in `home.nix` makes HM re-import nixpkgs, so the flake-level `pkgs` config doesn't apply to HM.
- Nix GUI apps on Fedora need Nix GPU drivers (`targets.genericLinux.gpu` in `common.nix`). If one fails with "Failed to create surface" or similar, run `nix-gpu-setup` (sudo; `update-system`/`update-home` do it automatically, `nix-rebuild-home` only warns).
- `home-manager build` has no `-o`; to keep a build for comparison use `nix build '.#homeConfigurations."jordan@<host>".activationPackage' -o <link>`.
