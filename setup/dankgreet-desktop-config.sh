#!/usr/bin/env bash

# Simple script to copy niri.kdl and config.toml to /etc/greetd/
# Usage: ./simple-copy-greetd.sh

# Confirmation prompt
echo "=========================================="
echo "  Triple Monitor Desktop Setup"
echo "=========================================="
echo ""
echo "This will configure greetd for a triple monitor"
echo "desktop setup using Niri window manager."
echo ""
echo -n "Do you want to continue? [y/N]: "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "Proceeding with setup..."
echo ""

# Check if running as root, if not, re-run with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges. Requesting sudo..."
    exec sudo "$0" "$@"
fi

# Get the actual user's home directory (not root's)
if [ -n "${SUDO_USER:-}" ]; then
    ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    ACTUAL_HOME="$HOME"
fi

SOURCE_DIR="$ACTUAL_HOME/.nix/dotfiles/root_setup_files/etc/greetd"
DEST_DIR="/etc/greetd"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

# Check if source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Copy niri.kdl
if [[ -f "$SOURCE_DIR/niri.kdl" ]]; then
    if [[ -f "$DEST_DIR/niri.kdl" ]]; then
        echo "Backing up existing niri.kdl"
        cp "$DEST_DIR/niri.kdl" "$DEST_DIR/niri.kdl${BACKUP_SUFFIX}"
    fi
    echo "Copying niri.kdl to $DEST_DIR"
    cp "$SOURCE_DIR/niri.kdl" "$DEST_DIR/niri.kdl"
    chmod 644 "$DEST_DIR/niri.kdl"
else
    echo "Warning: niri.kdl not found in $SOURCE_DIR"
fi

# Copy config.toml
if [[ -f "$SOURCE_DIR/config.toml" ]]; then
    if [[ -f "$DEST_DIR/config.toml" ]]; then
        echo "Backing up existing config.toml"
        cp "$DEST_DIR/config.toml" "$DEST_DIR/config.toml${BACKUP_SUFFIX}"
    fi
    echo "Copying config.toml to $DEST_DIR"
    cp "$SOURCE_DIR/config.toml" "$DEST_DIR/config.toml"
    chmod 644 "$DEST_DIR/config.toml"
else
    echo "Warning:  config.toml not found in $SOURCE_DIR"
fi

echo "Done!"
