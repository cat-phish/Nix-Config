#!/usr/bin/env bash

#!/usr/bin/env bash

nix flake update --flake ~/coding/nixCats

nix build ~/coding/nixCats

# Navigate to the nixCats directory and perform git operations
cd ~/coding/nixCats
git add .
git commit -m "nvim auto update [$(date +'%Y-%m-%d %H:%M:%S')]"
git push
cd -

nix flake update --flake ~/.nix mynvim

home-manager switch --flake ~/.nix
