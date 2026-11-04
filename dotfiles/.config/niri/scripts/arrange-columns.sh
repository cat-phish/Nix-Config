#!/usr/bin/env bash
# Arrange startup windows into a fixed column order on a niri workspace,
# regardless of which app finished loading first.
#
# Usage: arrange-columns.sh <workspace-name> <app-id> [<app-id> ...]
#   app-ids are exact matches, listed left-to-right.
# Waits up to $ARRANGE_TIMEOUT seconds (default 90) for every window to appear,
# then arranges whatever is there and gives focus back to where it was.
set -uo pipefail

ws_name="$1"; shift
apps=("$@")
timeout="${ARRANGE_TIMEOUT:-90}"

ws_id() { niri msg --json workspaces | jq -r --arg n "$ws_name" '.[] | select(.name == $n) | .id'; }

# Print the window id for an app-id on the target workspace (first one found).
win_id() {
    niri msg --json windows | jq -r --arg a "$1" --argjson w "$2" \
        '[.[] | select(.app_id == $a and .workspace_id == $w)] | sort_by(.id) | .[0].id // empty'
}

deadline=$((SECONDS + timeout))
while :; do
    wid=$(ws_id)
    missing=0
    if [[ -n "$wid" ]]; then
        for a in "${apps[@]}"; do [[ -z "$(win_id "$a" "$wid")" ]] && missing=1; done
    else
        missing=1
    fi
    ((missing == 0 || SECONDS >= deadline)) && break
    sleep 1
done
[[ -z "${wid:-}" ]] && exit 0

# Let the last window finish mapping/maximizing before moving things.
sleep 1

prev_focus=$(niri msg --json focused-window | jq -r '.id // empty')

idx=1
for a in "${apps[@]}"; do
    id=$(win_id "$a" "$wid")
    [[ -z "$id" ]] && continue
    niri msg action focus-window --id "$id"
    niri msg action move-column-to-index "$idx"
    idx=$((idx + 1))
done

# Leave the workspace scrolled to its first column, then restore focus.
first=$(win_id "${apps[0]}" "$wid")
[[ -n "$first" ]] && niri msg action focus-window --id "$first"
[[ -n "$prev_focus" ]] && niri msg action focus-window --id "$prev_focus"
exit 0
