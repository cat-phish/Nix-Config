#!/usr/bin/env bash

set -euo pipefail

# Script to install xone driver (Xbox One/Series Controller) on Fedora
# Usage: ./install-xone.sh

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Print functions
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Check for root at the start (needed for dnf and make install)
if [[ $EUID -ne 0 ]]; then
    echo "This script requires sudo privileges for installation. Requesting sudo..."
    exec sudo "$0" "$@"
fi

# Determine the actual user (so we don't clone into /root/.apps-source)
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
SOURCE_DIR="$TARGET_HOME/.apps-source/xone"

echo -e "${BOLD}${BLUE}==========================================${NC}"
echo -e "${BOLD}${BLUE}        Installing xone Driver            ${NC}"
echo -e "${BOLD}${BLUE}==========================================${NC}"

# Step 1: Install Dependencies
print_info "Step 1: Installing dependencies (bsdtar, kernel-devel, cabextract)..."
# cabextract is often needed for the firmware download part of xone
dnf install -y bsdtar kernel-devel kernel-headers cabextract git

# Step 2: Prepare Directory
print_info "Step 2: Preparing source directory..."
if [ -d "$SOURCE_DIR" ]; then
    print_warning "Directory $SOURCE_DIR already exists. Cleaning up..."
    rm -rf "$SOURCE_DIR"
fi
mkdir -p "$(dirname "$SOURCE_DIR")"

# Step 3: Clone and Build
print_info "Step 3: Cloning repository..."
# We run the clone as the actual user so the files aren't owned by root
sudo -u "$TARGET_USER" git clone https://github.com/dlundqvist/xone "$SOURCE_DIR"

print_info "Step 4: Building and installing driver..."
cd "$SOURCE_DIR"
if make install; then
    print_success "Driver compiled and installed."
else
    print_error "Failed to build xone driver. Ensure your kernel is up to date."
    exit 1
fi

# Step 5: Firmware (Crucial for Wireless Dongle)
print_info "Step 5: Downloading firmware (required for wireless dongle)..."
if ./install-firmware.sh; then
    print_success "Firmware installed."
else
    print_warning "Firmware script failed or skipped. Wireless dongle may not work."
fi

# Return to user home
cd "$TARGET_HOME"

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}        xone Installation Complete!       ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
print_info "You may need to reboot for the driver to load correctly."
echo ""
