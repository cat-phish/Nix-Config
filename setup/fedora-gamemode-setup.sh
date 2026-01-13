#!/usr/bin/env bash

set -euo pipefail

# Script to install Feral GameMode on Fedora
# Usage: ./install-gamemode.sh [OPTIONS]

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Print functions
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Requesting sudo privileges..."
    exec sudo "$0" "$@"
fi

# Header
echo -e "${BOLD}${BLUE}==========================================${NC}"
echo -e "${BOLD}${BLUE}       Installing Feral GameMode          ${NC}"
echo -e "${BOLD}${BLUE}==========================================${NC}"
echo ""

# Step 1: Install Package
print_info "Installing gamemode package..."
if dnf install -y gamemode; then
    print_success "GameMode installed successfully."
else
    echo -e "${BOLD}Error: Failed to install GameMode.${NC}"
    exit 1
fi

# Step 2: Verification
print_info "Verifying installation..."
if rpm -q gamemode > /dev/null; then
    VERSION=$(rpm -q --qf '%{VERSION}' gamemode)
    print_success "GameMode version $VERSION is now active."
fi

echo ""
echo -e "${GREEN}Complete!${NC}"
print_info "To use GameMode in Steam, add this to a game's Launch Options:"
echo -e "   ${BOLD}gamemoderun %command%${NC}"
echo ""
