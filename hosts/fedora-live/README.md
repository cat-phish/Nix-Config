# Fedora host — applying the Home Manager config

This folder contains a tiny helper and instructions to apply the `jordan@fedora-live` Home Manager configuration from this flake.

Prerequisites

- Nix installed on the Fedora machine. Single-user install is simplest for desktop systems.
- `nix` must have flakes enabled (see below).
- (Optional) `home-manager` available in PATH. If not, the wrapper will try to run it via `nix run`.

Quick steps

1. Install Nix (single-user recommended on Fedora):

```bash
# single-user install
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

2. Enable flakes (single-user):

```bash
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

3. Clone this repo and run the wrapper (or run the home-manager switch directly):

```bash
# clone somewhere on the Fedora machine (here we use ~/.nix to match this repo layout)
git clone https://github.com/cat-phish/Nix-Config.git ~/.nix
cd ~/.nix

# run the helper (make executable first)
chmod +x hosts/fedora-live/apply-fedora.sh
hosts/fedora-live/apply-fedora.sh

# or run directly
home-manager switch --flake .#jordan@fedora-live
```

Wrapper behaviour

- The script will detect if `nix` is present and if `home-manager` is in PATH.
- If `home-manager` is missing it will attempt to run the flake-provided `home-manager` by calling:

```
nix run github:nix-community/home-manager -c home-manager switch --flake .#jordan@fedora-live
```

Troubleshooting

- If the flake references system services or NixOS-only modules, those parts will be ignored on Fedora — Home Manager applies only user-level settings. If you see errors complaining about NixOS-only options, open an issue or comment them out for the Fedora host module.
- If you need system-wide services added on Fedora, you must create native systemd units or use your distribution's packaging; Home Manager only manages the user scope on non-NixOS systems.

Notes

- The wrapper assumes you'll clone the flake locally and run it from that repo root. If you prefer to run the flake from a remote location, use the flake URI (for example `github:cat-phish/Nix-Config#jordan@fedora-live`).
