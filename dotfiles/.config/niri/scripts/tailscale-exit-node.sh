#!/usr/bin/env bash
# Toggle / pick a Tailscale exit node. Requires `tailscale set --operator=$USER` (no sudo).
# Usage: tailscale-exit-node.sh [toggle|pick]
set -uo pipefail

TS=/usr/bin/tailscale
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/tailscale-last-exit-node"

notify() { notify-send -a Tailscale -i network-vpn "Tailscale" "$1"; }

status_json() { "$TS" status --json 2>/dev/null; }

# Prints "IP<TAB>HostName" for the peer with the given stable node ID.
peer_by_id() {
    status_json | jq -r --arg id "$1" '.Peer[]? | select(.ID == $id) | "\(.TailscaleIPs[0])\t\(.HostName)"'
}

host_for_ip() {
    status_json | jq -r --arg ip "$1" '.Peer[]? | select(.TailscaleIPs | index($ip)) | .HostName' | head -n1
}

set_exit_node() {
    local ip="$1" err
    if err=$("$TS" set --exit-node="$ip" 2>&1); then
        if [[ -n "$ip" ]]; then
            echo "$ip" >"$CACHE"
            notify "Exit node: $(host_for_ip "$ip") ($ip)"
        else
            notify "Exit node disabled"
        fi
    else
        notify "Failed: $err"
        exit 1
    fi
}

current_exit_node() {
    status_json | jq -r '.Peer[]? | select(.ExitNode == true) | .TailscaleIPs[0]' | head -n1
}

pick() {
    local choices choice
    choices=$(status_json | jq -r '.Peer[]? | select(.ExitNodeOption == true)
        | "\(.HostName)\t\(.TailscaleIPs[0])\t\(if .Online then "online" else "offline" end)\(if .ExitNode then "  [active]" else "" end)"' | sort)
    if [[ -z "$choices" ]]; then
        notify "No exit nodes available"
        exit 1
    fi
    choice=$(printf 'None (disable exit node)\n%s\n' "$choices" | fuzzel --dmenu --prompt "Exit node: " --width 60) || exit 0
    [[ -z "$choice" ]] && exit 0
    if [[ "$choice" == None* ]]; then
        set_exit_node ""
    else
        set_exit_node "$(cut -f2 <<<"$choice")"
    fi
}

toggle() {
    if [[ -n "$(current_exit_node)" ]]; then
        set_exit_node ""
        return
    fi
    local ip=""
    [[ -r "$CACHE" ]] && ip=$(<"$CACHE")
    if [[ -z "$ip" ]]; then
        local prior
        prior=$("$TS" debug prefs 2>/dev/null | jq -r '.InternalExitNodePrior // empty')
        [[ -n "$prior" ]] && ip=$(peer_by_id "$prior" | cut -f1)
    fi
    if [[ -n "$ip" ]]; then
        set_exit_node "$ip"
    else
        pick
    fi
}

case "${1:-toggle}" in
    toggle) toggle ;;
    pick) pick ;;
    *) echo "usage: $0 [toggle|pick]" >&2; exit 2 ;;
esac
