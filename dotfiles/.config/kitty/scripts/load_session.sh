#!/usr/bin/env bash
# Use fzf to pick a file from your sync folder
selection=$(ls ~/sync/kitty-sessions/*.conf | xargs -n 1 basename | fzf --height 40% --reverse)

if [ -n "$selection" ]; then
    # Launch a new OS window using that session file
    kitten @ launch --type=os-window --session "$HOME/sync/kitty-sessions/$selection"
fi
