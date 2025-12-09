#!/usr/bin/env bash

current_exit_ip=$(tailscale status --json | jq -r '.Self.ExitNodeIP // empty')

get_exit_nodes() {
    tailscale status --json | jq -r '.Peer | to_entries[] | select(.value.ExitNodeOption == true) | "\(.value.TailscaleIPs[0]) (\(.value.HostName))"'
}

if [[ -z "$current_exit_ip" ]]; then
    echo "No exit node is currently set."
    available_nodes=$(get_exit_nodes)
    
    if [[ -z "$available_nodes" ]]; then
        echo "No available exit nodes found."
        exit 1
    fi
    
    echo "Available exit nodes (Tailscale IP and Hostname):"
    echo "$available_nodes"
    
    echo "Enter the Tailscale IP of the exit node to connect (or press Enter to cancel):"
    read -r exit_node_ip
    
    if [[ -n "$exit_node_ip" ]]; then
        sudo tailscale set --exit-node="$exit_node_ip"
        echo "Connected to exit node: $exit_node_ip"
    else
        echo "No exit node selected."
    fi
else
    current_exit_host=$(tailscale status --json | jq -r '.Peer | to_entries[] | select(.value.TailscaleIPs[0] == "'"$current_exit_ip"'") | .value.HostName')
    echo "Currently using exit node: $current_exit_ip ($current_exit_host)"
    echo "Would you like to disconnect? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        sudo tailscale set --exit-node=
        echo "Disconnected from exit node."
    else
        echo "Exit node remains connected."
    fi
fi
