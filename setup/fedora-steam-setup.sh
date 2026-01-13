#!/usr/bin/env bash

set -euo pipefail

# Script to install Steam on Fedora
# Usage: ./setup-steam.sh [OPTIONS]

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges. Requesting sudo..."
    exec sudo "$0" "$@"
fi

# Check for skip confirmation flag
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-confirm|-y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Install Steam on Fedora x86_64 via RPM Fusion."
            echo ""
            echo "Options:"
            echo "  -y, --yes, --skip-confirm    Skip confirmation prompt"
            echo "  -h, --help                   Show this help message"
            echo ""
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Confirmation prompt
if [[ "$SKIP_CONFIRM" != true ]]; then
    echo -e "${BOLD}${BLUE}==========================================${NC}"
    echo -e "${BOLD}${BLUE}          Steam Installation Setup        ${NC}"
    echo -e "${BOLD}${BLUE}==========================================${NC}"
    echo ""
    echo "This script will install Steam on your Fedora system."
    echo ""
    echo -e "${YELLOW}Steps to be performed:${NC}"
    echo "  • Refresh system repositories"
    echo "  • Enable RPM Fusion (Free and Nonfree)"
    echo "  • Install Steam and 32-bit dependencies"
    echo "  • Verify installation"
    echo ""
    echo -ne "${BOLD}Do you want to continue? [y/N]: ${NC}"
    read -r response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    echo ""
fi

# Step 1: Update system
print_info "Step 1: Refreshing system repositories and upgrading..."
if dnf upgrade --refresh -y; then
    print_success "System refreshed"
else
    print_error "Failed to refresh repositories"
    exit 1
fi
echo ""

# Step 2: Enable RPM Fusion
print_info "Step 2: Enabling RPM Fusion repositories..."
if dnf repolist | grep -q "rpmfusion-nonfree"; then
    print_info "RPM Fusion Nonfree already enabled"
else
    if dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm; then
        print_success "RPM Fusion repositories enabled"
    else
        print_error "Failed to install RPM Fusion"
        exit 1
    fi
fi
echo ""

# Step 3: Install Steam
print_info "Step 3: Installing Steam..."
# Note: Fedora's Steam package automatically pulls in necessary i686 (32-bit) libs
if dnf install -y steam; then
    print_success "Steam package installed"
else
    print_error "Failed to install Steam"
    exit 1
fi
echo ""

# Step 4: Verification
print_info "Step 4: Verifying installation..."
if rpm -q steam > /dev/null; then
    STEAM_VER=$(rpm -q steam)
    print_success "Verification successful: $STEAM_VER"
else
    print_error "Steam installation could not be verified"
    exit 1
fi
echo ""

# Final summary
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}       Installation Complete!             ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Summary:"
echo "  ✓ Repositories refreshed"
echo "  ✓ RPM Fusion enabled"
echo "  ✓ Steam installed"
echo ""
print_info "You can now launch Steam from your application menu"
print_info "or by typing 'steam' in the terminal."
echo ""
