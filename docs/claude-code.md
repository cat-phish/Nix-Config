# Claude Code

Claude Code (`claude`) is installed from nixpkgs in `modules/home/dev-environment.nix`,
through a thin local wrapper defined in the `let` block at the top of that file.

## LD_LIBRARY_PATH leak (Fedora)

The nixpkgs package wraps the binary with `--prefix LD_LIBRARY_PATH : <alsa-lib>/lib`
so Claude can load `libasound`. Every process Claude starts (Bash tool commands, hooks)
inherits that variable. On Fedora, non-Nix programs then load Nix's `libasound`, which
is built against a newer glibc than Fedora ships, and fail. Playwright's Chromium, for
example, died with:

    /lib64/libm.so.6: version `GLIBC_2.43' not found (required by .../alsa-lib-1.2.16.1/lib/libasound.so.2)

Claude itself still needs the path. Putting it in the binary's RPATH with `patchelf`
instead breaks the Bun-compiled executable (it stops responding to `--version`), so
that approach was dropped.

The fix instead: the local wrapper sets `CLAUDE_CODE_SHELL_PREFIX` (via `--set-default`,
so an explicit value still wins) to a small script, `claude-shell-prefix`. Claude runs
every Bash tool command and hook through it, passing the command as a single string.
The script:

- removes the alsa-lib entry (and only that entry) from `LD_LIBRARY_PATH`, unsetting the
  variable if nothing else is left;
- re-runs the command with `$SHELL -c` (zsh or bash; anything else falls back to bash),
  because Claude writes the command for the user's shell (it sources a zsh snapshot).

Not covered: anything Claude starts outside the shell prefix (for example MCP servers)
still sees the alsa path. If a non-Nix program launched that way breaks with a glibc
error, run it with `env -u LD_LIBRARY_PATH`.
