#!/usr/bin/env bash
# Launch saved kitty sessions using remote control

SESSIONS_DIR="$HOME/sync/kitty"

# Auto-detect the kitty socket
SOCKET=$(ls /tmp/mykitty-* 2>/dev/null | head -n1)
if [ -z "$SOCKET" ]; then
    echo "No kitty socket found!"
    exit 1
fi

# Select a session file
session=$(find "$SESSIONS_DIR" -type f -name "*.session" | \
    sed "s|$SESSIONS_DIR/||" | \
    fzf --prompt="Select kitty session: " \
        --height=40% \
        --border \
        --reverse \
        --preview="bat $SESSIONS_DIR/{}" \
        --preview-window=right:60%:wrap)

if [ -n "$session" ]; then
    # Load the session into the current kitty instance
    kitty @ --to "unix:$SOCKET" load-config "$SESSIONS_DIR/$session"
fi
