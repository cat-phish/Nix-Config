#!/usr/bin/env bash
# Launch saved kitty sessions using remote control

# SESSIONS_DIR="$HOME/sync/kitty"
# mkdir -p "$SESSIONS_DIR"
#
# # Auto-detect the kitty socket
# SOCKET=$(ls /tmp/mykitty-* 2>/dev/null | head -n1)
# if [ -z "$SOCKET" ]; then
#     echo "No kitty socket found!"
#     exit 1
# fi
#
# # Select a session file
# # session=$(find "$SESSIONS_DIR" -type f -name "*.session" | \
# session=$(find "$SESSIONS_DIR" -type f -name "*" | \
#     sed "s|$SESSIONS_DIR/||" | \
#     fzf --prompt="Select kitty session: " \
#         --height=40% \
#         --border \
#         --reverse \
#         --preview="bat $SESSIONS_DIR/{}" \
#         --preview-window=right:60%:wrap)
#
#     echo "$SESSIONS_DIR/$session" &
# # if [ -n "$session" ]; then
# #     # Load the session into the current kitty instance
# #     kitty @ --to "unix:$SOCKET" load-config "$SESSIONS_DIR/$session"
# # fi
# # if [ -n "$session" ]; then
# #     # Load the session (kitty @ automatically uses $KITTY_LISTEN_ON)
# #     kitty @ load-config "$SESSIONS_DIR/$session"
# # fi
# if [ -n "$session" ]; then
#     # Launch new kitty instance with the session
#     # kitty --session "$SESSIONS_DIR/$session" &
#     echo "$SESSIONS_DIR/$session" &
# fi



SESSIONS_DIR="$HOME/sync/kitty"
LOG_FILE="$HOME/kitty-session.log"
mkdir -p "$SESSIONS_DIR"

echo "$(date): Script started" >> "$LOG_FILE"

# Select a session file
session=$(find "$SESSIONS_DIR" -type f | \
    sed "s|$SESSIONS_DIR/||" | \
    fzf --prompt="Select kitty session: " \
        --height=40% \
        --border \
        --reverse \
        --preview="cat $SESSIONS_DIR/{}" \
        --preview-window=right:60%:wrap)

echo "$(date): Selected session: '$session'" >> "$LOG_FILE"

if [ -n "$session" ]; then
    full_path="$SESSIONS_DIR/$session"
    echo "$(date): Full path: $full_path" >> "$LOG_FILE"

    # Launch new kitty instance with the session
    kitty --session "$full_path" &

    echo "$(date): Kitty launched with PID $!" >> "$LOG_FILE"
else
    echo "$(date): No session selected" >> "$LOG_FILE"
fi
