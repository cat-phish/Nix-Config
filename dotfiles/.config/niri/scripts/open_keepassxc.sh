#!/bin/bash

# Get the window ID of KeePassXC
# We use 'org.keepassxc.KeePassXC' as the standard app_id
WINDOW_ID=$(niri msg --json windows | jq '.[] | select(.app_id == "org.keepassxc.KeePassXC") | .id' | head -n 1)

if [ -n "$WINDOW_ID" ]; then
    # If it exists, focus it
    niri msg action focus-window --id "$WINDOW_ID"
else
    # If it doesn't exist, launch it
    keepassxc &
fi
