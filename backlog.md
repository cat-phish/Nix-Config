# Backlog

- **[M] `ubuntu@ubuntu` HM output doesn't evaluate** — `flake.nix` imports nonexistent `hosts/all-personal-machines/home.nix` and `hosts/live-usb/ubuntu/home.nix`, which also breaks `nix flake check`. Fix the paths (the real file is `hosts/all-personal-machines-home.nix`) and add the live-USB host, or delete the output.
- **[S] `all-personal-machines-*.nix` unused** — no active output imports `hosts/all-personal-machines-home.nix` or `-configuration.nix`. Wire them back in or delete them.
- **[S] `plasma_manager_export.sh` is stale** — it matches hostnames `jordans-desktop`/`jordans-laptop` (real ones are `nixos-desktop`/`nixos-laptop`) and writes to `modules/plasma-config/{desktop,laptop}/` (real dirs are `nixos-desktop`/`nixos-laptop`). It currently exits with "Unknown hostname" on every host.
- **[XS] Wrong source for syncthingtray script** — in both `hosts/fedora-desktop-home.nix` and `hosts/fedora-laptop-home.nix`, `.config/niri/scripts/syncthingtray_startup_delay.sh` points to `focus_keepassxc.sh`.

Sizes: XS = one-line fix · S = under an hour · M = needs a decision or new config
