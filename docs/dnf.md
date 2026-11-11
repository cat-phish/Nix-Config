# dnf packages on the Fedora hosts

dnf packages are declared in Nix like Nix packages, so the desktop and laptop stay in sync without
both getting everything. Home Manager doesn't install them. `dotfiles/.scripts/dnf-sync` reads the
merged list with `nix eval` and asks before installing or removing anything. All of this is ignored
on NixOS.

## Declaring packages

Set `my.fedora.dnf` (defined in `modules/home/fedora-dnf.nix`) in any bundle or host file. Lists
from every imported module are merged, so a host gets the dnf packages of the bundles it imports:

```nix
# modules/home/common.nix: every Fedora host
my.fedora.dnf = {
  coprs = ["gagbo/kitty-latest"];
  packages = ["zsh" "kitty" "wireguard-tools"];
};

# hosts/fedora-laptop-home.nix: this machine only
my.fedora.dnf.packages = ["fprintd" "fprintd-pam"];
```

| Option | Meaning |
|---|---|
| `packages` | Packages to keep installed (names or anything dnf can resolve, checked with `rpm -q --whatprovides`) |
| `coprs` | COPRs to enable, `"owner/project"` |
| `repoFiles` | `.repo` URLs, added with `dnf config-manager addrepo` if `/etc/yum.repos.d/<file>` is missing |
| `ignore` | Globs that `--save` never offers (setup-script packages, kernels, nix, git...) |
| `swaps` | Renamed packages, `{ old = "new"; }`: if old is installed, `dnf swap old new` instead of installing new |

Current declarations live in `common.nix`, `desktop-niri.nix` (niri, DMS from `duxlabs/dms`),
`app-tailscale.nix`, `app-wireguard-tray.nix` and `hosts/fedora-laptop-home.nix`.

Packages saved by the capture step are stored in `setup/dnf-saved.json` (`packages.common`,
`packages.<host>`, `ignore.<host>`), which the module merges in. You can move an entry from there
into a bundle by hand at any time.

## Commands

```sh
dnf-sync --status   # show what would be saved / installed / removed, change nothing
dnf-sync --save     # sort packages you installed by hand (no sudo)
dnf-sync --apply    # repos, installs, removals (sudo)
```

`update-system` runs `--save` before its commit prompt, so saved entries get committed and pushed,
and `--apply` after `dnf upgrade`. `init.sh` runs `--apply` right after the first Home Manager
switch.

All prompts are plain terminal input. Without a terminal, dnf-sync only reports.

### --save (capture manual installs)

Candidates are packages installed with reason "user" in dnf history after the OS image/installer
transactions, that are still installed and not already declared or ignored. You make one choice per
package:

```
  c  save to common (all Fedora hosts)
  h  save to fedora-laptop only
  i  ignore on fedora-laptop (never ask again)
  s  skip (ask next time; Enter does the same)
  C/H/I/S  same for this and all remaining (asks to confirm)
  r  start over from the first package
  q  stop (rest skipped)

[1/12] chromium            [c/h/i/s] c
[2/12] clang               [c/h/i/s] h
[3/12] golang              [c/h/i/s] I
```

Uppercase lists the packages it would cover and asks `Confirm? [y/N]`; answering no goes back to
the current package. After the last package you get a summary and `Save? [Y/n/r=start over]`.
Nothing is written before that, and `r` (at a package or at the Save prompt) throws away this
run's choices and starts again from the first package.

Each package can only end up in one place:
- saved to **common** → removed from every host list and every ignore list;
- saved to **this host** → removed from this host's ignore list.

`--status` (and `--save`) also warn about contradictions in `setup/dnf-saved.json` from hand edits:
a package in both `common` and a host list, or saved and ignored for the same host.

### --apply

1. Enables missing COPRs and repo files. It never removes repos.
2. **Install:** lists declared packages that aren't installed, then asks
   `Install all? [Y/n/p=pick]`. `p` asks for numbers (`1 3-4`). If a `swaps` entry's old package
   is installed, it's shown as "new (replaces old)" and swapped. Skipped packages stay declared and
   are offered again.
3. **Remove:** lists packages that were in the last applied list
   (`~/.local/state/dnf-sync-applied.json`) but aren't declared any more and are still installed,
   then asks `Remove all? [y/N/p=pick]` (default no). `dnf remove` runs without `-y`, so you see
   which dependents go with them. Removals you decline stay pending and are offered on every run
   until you confirm them or put the package back in the config. The first run (no snapshot) never
   removes anything.

## Not managed here

- `nix` (petersen/nix COPR) and `git`: `init.sh` installs them before the flake can be evaluated.
- The `setup/*.sh` scripts (nvidia, steam, docker, xone, gamemode, kmonad, secureboot) do more than
  install packages, so they stay scripts. Their packages are in the module's built-in `ignore` list.
