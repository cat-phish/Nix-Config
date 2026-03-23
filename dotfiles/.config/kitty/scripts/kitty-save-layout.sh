#!/usr/bin/env bash
# Save current kitty window layout

SESSIONS_DIR="$HOME/sync/kitty"
mkdir -p "$SESSIONS_DIR"

# Prompt for session name
echo -n "Session name: "
read session_name

if [ -z "$session_name" ]; then
    echo "No name provided, exiting"
    exit 1
fi

# Save current window layout
kitty @ ls > "$SESSIONS_DIR/${session_name}.json"

echo "Saved layout to $SESSIONS_DIR/${session_name}.json"
