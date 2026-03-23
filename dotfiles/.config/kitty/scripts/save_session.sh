#!/usr/bin/env bash
# Prompt for a name using read (runs inside a kitty window)
echo "Enter session name (no extension):"
read session_name

if [ -n "$session_name" ]; then
    # Save the current state to your sync folder
    kitten @ save-as-session "$HOME/sync/kitty-sessions/$session_name.conf"
    echo "Saved to $session_name.conf"
    sleep 1
fi
