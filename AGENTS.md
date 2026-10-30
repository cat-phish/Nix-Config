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
nix flake check            # evaluates all outputs; slow, and see "Known breakage" below

# Update inputs
nix flake update [input-name]
```

Flakes only see git-tracked files: `git add` any new `.nix` module or dotfile before building, or evaluation will fail with "path does not exist".

`init.sh` is the interactive first-time bootstrap (OS/host detection, Fedora dnf/driver setup via `setup/*.sh`, Nix + Home Manager install, copying icons/themes/`.local/share`, first switch). It is not needed for day-to-day changes.

## Architecture

**Flake outputs** (`flake.nix`):
- `nixosConfigurations.{nixos-desktop,nixos-laptop}` = `configuration.nix` (shared system base) + `hosts/<host>-configuration.nix`, which imports `modules/nixos/*` and `modules/hardware-config/<host>-hardware.nix`.
- `homeConfigurations."jordan@{nixos-desktop,nixos-laptop,fedora-desktop,fedora-laptop}"` = `home.nix` (shared HM base, mostly empty scaffolding + sops import) + `hosts/<host>-home.nix`.
- Fedora HM configs additionally load `nix-flatpak` and `agenix` HM modules; NixOS HM configs use `plasma-manager`.

**Composition is by explicit imports in the host file.** Each `hosts/*-home.nix` lists which `modules/home/*.nix` feature bundles it wants (e.g. `dev-environment.nix`, `media-playback.nix`, `app-*.nix`), plus `modules/rclone/*` mounts and `modules/plasma-config/<host>/plasma-config.nix`. To add a package/feature to a machine: put it in the appropriate `modules/home/*` bundle (or create one from `modules/home/_template.nix`) and import it from each host file that should get it. `hosts/_template-*.nix` are scaffolds for new hosts.

**Special args available to modules:** `inputs`, `pkgs-stable` (nixos-24.11, for pinning packages that break on unstable), `nvim-config`, `emacs-config`, `plasma-manager`, `talon-nix`, and `isNixos` (bool, HM only). `pkgs` is unstable with `allowUnfree`. Modules conventionally write `home.packages = (with pkgs; [...]) ++ (with pkgs-stable; [...]);`. Use `lib.mkIf isNixos` for anything that only works on NixOS.

**Dotfiles:** `dotfiles/` mirrors `$HOME`. Files are linked selectively via `home.file` entries in host files (paths like `../dotfiles/.config/kmonad`), not wholesale. Large assets (`.icons`, `.themes`, `.local/share`) are copied by `init.sh` rather than managed by HM. `dotfiles/.talon/user/community` is a git submodule.

**KDE Plasma:** `modules/plasma-config/<host>/plasma-config.nix` is generated from the live desktop by `plasma_manager_export.sh` (rc2nix); dated siblings are previous snapshots kept as backups, not imported.

**Secrets:** `secrets.yaml` is sops-encrypted (keys in `.sops.yaml`); sops wiring is currently mostly commented out. Never decrypt or print it.

## Known breakage / gotchas

- `homeConfigurations."ubuntu@ubuntu"` references `hosts/all-personal-machines/home.nix` and `hosts/live-usb/...`, which don't exist, so it (and `nix flake check`) fails to evaluate. The existing file is `hosts/all-personal-machines-home.nix` (and `-configuration.nix`), which is currently not imported by any active output.
- `emacs-config` is a `git+ssh` input; evaluating the flake requires GitHub SSH access.
- Insecure packages must be allow-listed in `permittedInsecurePackages` (in `flake.nix` for system `pkgs`, in `home.nix` for HM).
