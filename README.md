# My Dotfiles

My personal Nix flake: Home Manager on Fedora (the daily driver) plus full NixOS
configs, all with the same niri + Dux Shell (DMS) desktop, along with dotfiles,
themes, and icons.

- **Fedora:** standalone Home Manager. niri, dms and drivers come from dnf/COPR via `init.sh`.
- **NixOS:** `nixos-desktop` / `nixos-laptop`. Kept evaluating and building so switching back is
  easy, but not used day to day.
- **`archive/`:** unused code kept for reference (e.g. the old KDE Plasma setup). Nothing there is imported.

See [AGENTS.md](AGENTS.md) for the layout and everyday commands.

## Installation

Install NixOS and setup graphically or via command line, enter the OS and then
run the following command:

```sh
nix-shell -p git --run '
  git clone --recurse-submodules https://github.com/cat-phish/Nix-Config.git $HOME/.nix &&
  cd $HOME/.nix &&
  ./init.sh
'
```

## Fedora Installation

Run this command to install git, clone the repo, and start setup:

```bash
sudo dnf upgrade --refresh -y && \
  sudo dnf install -y git && \
  git clone --recurse-submodules https://github.com/cat-phish/Nix-Config.git $HOME/.nix && \
  cd $HOME/.nix && \
  bash init.sh
```

This will:

1. Update system packages
2. Install git
3. Clone your Nix config to ~/.nix
4. Run the interactive setup script

## Licensing

- The dotfiles and configurations are licensed under the MIT License. See
  [LICENSE](LICENSE) for details.
- The "Reactionary Plus" theme in the `dotfiles/.local/share/` directory are
  licensed under the GPL-3.0 License. See [COPYING.GPL-3.0](COPYING.GPL-3.0)
  for details.
- The "Hackneyed" icons in the `dotfiles/.icons/` directory are licensed under
  the GPL-2.0 License. See [COPYING.GPL-2.0](COPYING.GPL-2.0) for details.

## Attribution

- The kde themes and icons included in this repository are created by their
  respective authors and are included here in compliance with their licenses.
