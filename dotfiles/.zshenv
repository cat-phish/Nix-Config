# Read by every zsh, including the non-login shells sshd starts for remote
# commands (herdr mobile/app, `hc --on`, rsync). Those never source
# /etc/profile.d/nix.sh, so Nix-installed tools would be missing from PATH.
# On NixOS the system already sets this; the existence checks make it a no-op
# where the directories don't exist.
typeset -U path
[[ -d "$HOME/.nix-profile/bin" ]] && path=("$HOME/.nix-profile/bin" $path)
[[ -d /nix/var/nix/profiles/default/bin ]] && path+=(/nix/var/nix/profiles/default/bin)
