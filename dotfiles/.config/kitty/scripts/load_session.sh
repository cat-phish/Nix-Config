#!/usr/bin/env bash
selection=$(ls ~/sync/kitty-sessions/* 2>/dev/null | xargs -n 1 basename | fzf --height 40% --reverse)

if [ -n "$selection" ]; then
    # 'goto_session' is the correct internal action for loading
    kitten @ action goto_session "$HOME/sync/kitty-sessions/$selection"
else
    echo "No session selected."
    sleep 1
fi
