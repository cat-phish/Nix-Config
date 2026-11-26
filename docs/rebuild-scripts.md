# Rebuild and deploy scripts

The scripts in `dotfiles/.scripts/` that switch a Nix configuration all take `--rollback`, and
each one has the exact rollback command in a comment at the top of the file, so a bad switch can
be undone without looking anything up.

| Script | What it switches | `--rollback` runs |
|---|---|---|
| `nix-rebuild-home` | Home Manager on this machine | the previous generation's `activate` script |
| `nix-rebuild-system` | NixOS on this machine | `sudo nixos-rebuild switch --rollback` |
| `nix-rebuild-full` | both | both of the above, system first |
| `nix-deploy-code` | the agent VM (see `code-vm.md`) | `ssh -t code-admin sudo nixos-rebuild switch --rollback` |

Home Manager has no `--rollback` of its own. The previous generation is the second line of
`home-manager generations` (the first is the current one), and running its `activate` switches
back to it:

```sh
"$(home-manager generations | sed -n 2p | awk '{print $NF}')/activate"
```

`--rollback` skips everything else the script does (git sync, commits, builds), so it works
offline and never touches the repo. Rolling back doesn't change the repo either: the next
rebuild switches forward to whatever is committed again.
