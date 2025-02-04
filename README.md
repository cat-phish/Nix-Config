# My Dotfiles

This repository contains my personal NixOS config including configurations for
various applications, themes, and icons.

## Installation

Install NixOS and setup graphically or via command line, enter the OS and then
run the following command:

```sh
nix-shell -p git --run '
  git clone https://github.com/your/repo.git $HOME/.nix &&
  cd $HOME/.nix &&
  ./init.sh
'
```

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
