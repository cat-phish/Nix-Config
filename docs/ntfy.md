# ntfy desktop notifications

`ntfy-listener` (systemd user service, `modules/home/desktop-niri.nix`) subscribes to the
media server's `Tracearr` ntfy topic and shows each message with `notify-send`.

## Configuration

Values come from `~/.ssh/.env` (`EnvironmentFile`, outside the repo):

- `MEDIASERVER_HOST`: pinged before connecting.
- `MEDIASERVER_NTFY_SERVER`: base URL of the ntfy server (scheme, host and port).
- `MEDIASERVER_NTFY_AUTH_TOKEN`: access token.

## Behaviour

- When `MEDIASERVER_HOST` answers a ping, the script `exec`s `ntfy sub`. Otherwise it sleeps
  60s and exits, and systemd restarts it 10s later (about 70s between checks when away from home).
- The token is passed to ntfy as `$NTFY_TOKEN` instead of `--token`, so it doesn't appear in
  `ps` or `systemctl status`.
- Notifications go through a small `ntfy-notify` script that quotes `$NTFY_TITLE` and
  `$NTFY_MESSAGE`, so titles and messages with spaces stay intact.

## History

- 2026-11-22: fixed the listener, which had never delivered anything. It used a hard-coded port
  (`3924`, a typo for the real port) instead of `MEDIASERVER_NTFY_SERVER`, and it read
  `NTFY_AUTH_TOKEN`, which the env file doesn't define, so the token was empty. Its nested
  shell quoting inside `ExecStart` also split the `notify-send` arguments. Moved the logic
  into `writeShellScript`s so systemd no longer expands `${...}` or unescapes quotes in it.
