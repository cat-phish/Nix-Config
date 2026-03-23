#!/usr/bin/env bash
# Restore kitty window layout using fzf

SESSIONS_DIR="$HOME/sync/kitty"
LOG_FILE="$HOME/kitty-session.log"
mkdir -p "$SESSIONS_DIR"

echo "$(date): Restore script started" >> "$LOG_FILE"

# Select a session file
session=$(find "$SESSIONS_DIR" -type f -name "*.json" | \
    sed "s|$SESSIONS_DIR/||" | \
    fzf --prompt="Restore layout: " \
        --height=40% \
        --border \
        --reverse \
        --preview="jq -C . $SESSIONS_DIR/{} 2>/dev/null || cat $SESSIONS_DIR/{}" \
        --preview-window=right:60%:wrap)

echo "$(date): Selected session: '$session'" >> "$LOG_FILE"

if [ -n "$session" ]; then
    full_path="$SESSIONS_DIR/$session"
    echo "$(date): Restoring from: $full_path" >> "$LOG_FILE"

    # Get current OS window ID
    current_window=$(kitty @ ls | jq -r '.[0].id')

    # Close all tabs in current window except the first
    kitty @ ls | jq -r '.[0].tabs[1:][].id' | while read tab_id; do
        kitty @ close-tab --match "id:$tab_id"
    done

    # Parse the saved layout and recreate it
    jq -r '.[0].tabs[] |
        "TAB:\(.title // "tab"):\(.layout):" +
        (.windows | map(.cwd) | join("|"))' "$full_path" | \
    while IFS=: read -r marker title layout cwds; do
        # Create new tab
        kitty @ new-tab --title "$title"
        kitty @ goto-layout "$layout"

        # Create windows in the tab
        first=true
        echo "$cwds" | tr '|' '\n' | while read cwd; do
            if [ "$first" = true ]; then
                kitty @ send-text "cd $cwd\nclear\n"
                first=false
            else
                kitty @ launch --type=window --cwd="$cwd"
            fi
        done
    done

    # Close the initial empty tab
    kitty @ close-tab --match "num:1"

    echo "$(date): Layout restored" >> "$LOG_FILE"
else
    echo "$(date): No session selected" >> "$LOG_FILE"
fi
