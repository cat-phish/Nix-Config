#!/usr/bin/env bash


current_exit=$(tailscale status --json | jq -r '.Self.ExitNodeID // empty')

get_exit_nodes() {
    tailscale status --json | jq -r '.Peer | to_entries[] | select(.value.ExitNodeOption == true) | "\(.key) (\(.value.HostName))"'
}

if [[ -z "$current_exit" ]]; then
    echo "No exit node is currently set."
    available_nodes=$(get_exit_nodes)
    
    if [[ -z "$available_nodes" ]]; then
        echo "No available exit nodes found."
        exit 1
    fi
    
    echo "Available exit nodes:"
    echo "$available_nodes"
    
    echo "Enter the exit node ID to connect (or press Enter to cancel):"
    read -r exit_node_id
    
    if [[ -n "$exit_node_id" ]]; then
        sudo tailscale set --exit-node="$exit_node_id"
        echo "Connected to exit node: $exit_node_id"
    else
        echo "No exit node selected."
    fi
else
    echo "Currently using exit node: $current_exit"
    echo "Would you like to disconnect? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        sudo tailscale set --exit-node=
        echo "Disconnected from exit node."
    else
        echo "Exit node remains connected."
    fi
fi

