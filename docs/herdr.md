# herdr-app

herdr-app (the GUI for herdr, from `herdr-desktop` in `modules/home/dev-environment.nix`) keeps its keybindings in `~/.config/herdr-app/keys.json`. That file is tracked at `dotfiles/.config/herdr-app/keys.json` and linked out of store (`mkOutOfStoreSymlink`), so edits made in the app land in the repo and get committed by the update scripts.

## Keybindings

Custom bindings in the `global` section:

| Key | Action | Why |
|---|---|---|
| Ctrl+Shift+H / Ctrl+Shift+Left | `tab.prev` | Same as kitty (`kitty_mod` = ctrl+shift, `previous_tab`) |
| Ctrl+Shift+L / Ctrl+Shift+Right | `tab.next` | Same as kitty (`next_tab`) |
| Ctrl+Shift+J | `agent.next` | Agent switching on the same HJKL grid as tabs |
| Ctrl+Shift+K | `agent.prev` | |
| Ctrl+Shift+U | `space.next` | Spaces on the row above agents: U over J (next), I over K (prev) |
| Ctrl+Shift+I | `space.prev` | |
| Ctrl+Shift+Y | `layout.switch` | Moved off Ctrl+Shift+L to make room for tabs |
| Ctrl+Shift+M | `mod.open:picker` | Moved off Ctrl+Shift+K to make room for agents |

The defaults still work alongside these: Ctrl+Tab / Ctrl+Shift+Tab, Alt+[ / Alt+] and Ctrl+PageUp/PageDown for tabs, and Alt+Up/Down for agents, and Ctrl+Shift+PageUp/PageDown for spaces.

These were chosen for the following reasons:
- niri binds only Super (`Mod`) combos, plus Ctrl+Print, Alt+Print and Ctrl+Alt+Delete, so Ctrl+Shift keys never reach the compositor.
- Shift+Tab is left unbound on purpose. Claude Code uses it to cycle modes and shells use it for reverse completion.
- Ctrl+Shift+U is IBus's Unicode-entry key, but IBus isn't running under niri here. If an input method is ever added, it will swallow `space.next`.
- nvim's buffer keys (Alt+Shift+H/L, Home/End) don't overlap with these.

## Caveats

- If herdr-app ever replaces the file instead of writing through the link (for example after the `ctrl-alt-shift-escape` reset, which moves `keys.json` aside), `~/.config/herdr-app/keys.json` becomes a plain file. Check with `ls -l`. Copy any changes you want to keep into the repo copy, delete the plain file, then run `home-manager switch` to restore the link.
- An invalid file is rejected and the reason is written to `~/.config/herdr-app/keys.error`.

## Voice control

numen phrases in `dotfiles/.config/numen/phrases/environment.phrases`:

| Say | Runs |
|---|---|
| `agent up` / `agent down` | `herdr-app do agent.prev` / `agent.next` |
| `space up` / `space down` | `herdr-app do space.prev` / `space.next` |

They call `herdr-app do`, which sends the command to the open window over `~/.config/herdr-app/herdr-app.sock`, instead of pressing the keys. That way they work while another window has focus, and they can't leave a stuck modifier. "Up"/"down" match the sidebar order and avoid "next", which is already a phrase (Ctrl+N). Tabs still use the key-press phrases `tab left` / `tab right` (Ctrl+Shift+H/L), which also work in kitty.

Note that the `herdr` CLI (herdr 0.9.x, `herdr agent ...`) talks to a different server (`~/.config/herdr/herdr.sock`) and doesn't see herdr-app's agents. Use `herdr-app do` or `hc` for the app.
