# Vicinae launcher

Vicinae is the app launcher (Mod+Space), clipboard history (Mod+Y) and emoji picker
(Mod+Semicolon). It replaced DMS Spotlight and the DMS launcher plugins.

Everything is in `modules/home/app-vicinae.nix`, imported by `modules/home/desktop-niri.nix`, so
every niri host gets it. Keybinds are in `dotfiles/.config/niri/config.kdl`.

## Contents

1. [What's declarative and what isn't](#whats-declarative-and-what-isnt)
2. [How updates work](#how-updates-work)
3. [Extensions](#extensions)
4. [Script commands](#script-commands)
5. [Troubleshooting](#troubleshooting)

---

## What's declarative and what isn't

| Thing | Where |
|---|---|
| Vicinae itself (package, user service) | `programs.vicinae` in `app-vicinae.nix` |
| Settings (theme, compact mode, layer) | `programs.vicinae.settings` |
| Theme `dms-blue` | `programs.vicinae.themes` (a static copy of the DMS blue colours) |
| Extensions | `dotfiles/.config/vicinae/extensions.conf`, installed by `~/.scripts/vicinae-extensions` |
| Script commands | `dotfiles/.local/share/vicinae/scripts/` |
| Favorites, fallbacks, shortcuts (quicklinks), snippets | Vicinae GUI only, stored in `~/.local/share/vicinae` and `~/.config/vicinae/settings.json` |

`mutableSettings = true` keeps `~/.config/vicinae/settings.json` writable (Vicinae needs that) and
loads the repo settings on top through `VICINAE_OVERRIDES`. A key set in the repo always wins over
the same key changed in the GUI, so keep GUI-managed keys (`favorites`, `fallbacks`) out of
`settings`.

Extensions you install from the in-app store are added to `extensions.conf` automatically on the
next `update-system` run (see [Extensions](#extensions)).

## How updates work

| Part | Updates when |
|---|---|
| Vicinae itself | `nix flake update` (it comes from nixpkgs), applied by `update-system` |
| Extensions | Every `update-system` run, or by hand with `vicinae-extensions` |
| Scripts, theme, settings | Only when you edit them |

## Extensions

Vicinae has two in-app stores, and `extensions.conf` can install from either:

| Store | What's in it | Line in `extensions.conf` |
|---|---|---|
| **Raycast Store** | Raycast's catalogue, run through Vicinae's Raycast compatibility layer | `raycast:<author>/<name>` |
| **Vicinae Store** | Extensions written for Vicinae (<https://github.com/vicinaehq/extensions>) | `vicinae:<author>/<name>` |

`~/.scripts/vicinae-extensions` downloads the same prebuilt zips the in-app stores use, so there's
nothing to build and no hashes. For each line it:

- checks the store for the current version (Raycast: the commit, Vicinae: the upload date);
- skips extensions that are already current;
- otherwise installs the new version into `~/.local/share/vicinae/extensions/<name>/` and writes
  the version to `.update-system-version` in that folder.

It also removes extensions that it installed but are no longer listed, and restarts the `vicinae`
service if anything changed. If a store is down or a download fails, it keeps the current version
and moves on, so it can't break `update-system`.

**Installs from the in-app store are adopted.** Vicinae never updates store extensions itself, so
before updating, the script looks for extensions with no `.update-system-version` file. It reads
their author and name from `package.json`, finds which store has them, and appends a line to
`extensions.conf` (marked `# added from the Vicinae GUI <date>`). From then on they're updated and
synced like the rest. The new line is committed through `update-system`'s "uncommitted changes"
prompt on its next run. Extensions in neither store (local or development builds) are left alone.

**Adding one:** install it from Vicinae's in-app store and it's picked up on the next
`update-system` (or `vicinae-extensions`) run. Or add it by hand:

1. Find its author and name.
   - **Raycast:** from the store URL, `https://www.raycast.com/<author>/<name>`.
   - **Vicinae:** the author's handle shown in the in-app store, or the folder in the `vicinaehq/extensions` repo.
2. Add a line to `dotfiles/.config/vicinae/extensions.conf`, e.g. `raycast:ricoberger/gitmoji`.
3. Run `vicinae-extensions` (or wait for the next `update-system`), then commit.

**Removing one:** delete its line and run `vicinae-extensions`. Uninstalling it only in the GUI
doesn't stick: the line is still in `extensions.conf`, so the next run installs it again.

**Updating:** automatic. To update right away, run `vicinae-extensions`. To force a reinstall,
delete the extension's `.update-system-version` file first.

Vicinae doesn't implement every Raycast API, so some Raycast extensions install but fail when run.
Test new ones, and remove any that don't work.

## Script commands

Scripts are plain shell scripts in `dotfiles/.local/share/vicinae/scripts/`, linked to
`~/.local/share/vicinae/scripts/`. Each one shows up in Vicinae as a command:

- `duckduckgo.sh`: **Search DuckDuckGo**. `!bangs` work. Add it as a fallback in Vicinae's settings
  so it appears when nothing matches.
- `nix-run.sh`: **Nix Run** runs `nix run nixpkgs#<pkg>`.
- `nix-shell.sh`: **Nix Shell** opens a terminal with `nix shell nixpkgs#<pkgs...>`.

To add a script, start from `vicinae script template -t "Title" -l bash -m silent`, save it there,
`chmod +x` it, then check it with `vicinae script check <file>`. `git add` it before switching,
because flakes only see tracked files. Arguments use `# @vicinae.argument1 { "type": "text",
"placeholder": "..." }`. Directives: <https://docs.vicinae.com/scripts/directives>.

## Troubleshooting

- **Service status and logs:** `systemctl --user status vicinae`, `vicinae logs`.
- **"Failed to create surface" or a similar GPU error:** run `nix-gpu-setup`.
- **The tray icon is a pink/black checkerboard:** DMS failed to find the icon. This happens right
  after Vicinae is first installed. Run `dms restart`.
- **The launcher opens behind fullscreen windows:** `launcher_window.layer_shell.layer` must be
  `"overlay"`; it's already set.
- **An app's icon is missing:** check the `Icon=` line of its `.desktop` file. AppImages from
  `update-system` use `~/.local/share/icons/<name>.png`. Then run
  `vicinae deeplink vicinae://launch/core/refresh-apps`.
- **An extension installs but errors at runtime:** it probably needs a Raycast API Vicinae doesn't
  implement. Remove it.
- **An extension isn't updating:** run `vicinae-extensions` and read its output. `[!]` lines name
  the extension and the reason.
