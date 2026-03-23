#!/usr/bin/env bash
echo "Enter session name:"
read session_name

if [ -n "$session_name" ]; then
    # The --do-not-open-in-editor flag stops the new window/editor popup
    kitten @ action save_as_session --do-not-open-in-editor "$HOME/sync/kitty-sessions/$session_name.conf"
    echo "Saved to $session_name.conf"
    sleep 1
fi
