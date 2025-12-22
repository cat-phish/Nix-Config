#!/usr/bin/env bash

set -euo pipefail

# Script to copy niri.kdl and config. toml to /etc/greetd/
# Usage: ./setup-dankgreeter.sh [OPTIONS]

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

# Check if running as root, if not, re-run with sudo
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
            echo "Configure greetd for triple monitor desktop setup with Niri."
            echo ""
            echo "Options:"
            echo "  -y, --yes, --skip-confirm    Skip confirmation prompt"
            echo "  -h, --help                   Show this help message"
            echo ""
            echo "Files:"
            echo "  Source: ~/.nix/dotfiles/root_setup_files/etc/greetd/"
            echo "  Destination: /etc/greetd/"
            echo "  - niri.kdl"
            echo "  - config. toml"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Confirmation prompt (unless skipped)
if [[ "$SKIP_CONFIRM" != true ]]; then
    echo -e "${BOLD}${BLUE}==========================================${NC}"
    echo -e "${BOLD}${BLUE}  Triple Monitor Desktop Setup${NC}"
    echo -e "${BOLD}${BLUE}==========================================${NC}"
    echo ""
    echo "This will configure greetd for a triple monitor"
    echo "desktop setup using Niri window manager."
    echo ""
    echo -e "${YELLOW}Files that will be modified:${NC}"
    echo "  • /etc/greetd/config.toml"
    echo "  • /etc/greetd/niri.kdl"
    echo ""
    echo -e "${YELLOW}Note: ${NC} Backups will be created automatically"
    echo ""
    echo -ne "${BOLD}Do you want to continue? [y/N]: ${NC}"
    read -r response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi

    echo ""
fi

print_info "Proceeding with setup..."
echo ""

# Get the actual user's home directory (not root's)
if [ -n "${SUDO_USER:-}" ]; then
    ACTUAL_USER="$SUDO_USER"
    ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    ACTUAL_USER="$USER"
    ACTUAL_HOME="$HOME"
fi

# Configuration
SOURCE_DIR="$ACTUAL_HOME/.nix/dotfiles/root_setup_files/etc/greetd"
DEST_DIR="/etc/greetd"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"
FILES=("niri.kdl" "config.toml")

print_info "Source directory: $SOURCE_DIR"
print_info "Destination directory:  $DEST_DIR"
echo ""

# Validate source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    print_error "Source directory not found: $SOURCE_DIR"
    print_error "User:  $ACTUAL_USER"
    print_error "Home: $ACTUAL_HOME"
    exit 1
fi

# Validate destination directory exists
if [[ ! -d "$DEST_DIR" ]]; then
    print_error "Destination directory not found: $DEST_DIR"
    print_error "Is greetd installed?"
    exit 1
fi

# Process each file
SUCCESS_COUNT=0
WARNING_COUNT=0

for filename in "${FILES[@]}"; do
    source_file="$SOURCE_DIR/$filename"
    dest_file="$DEST_DIR/$filename"
    
    print_info "Processing: $filename"
    
    # Check if source file exists
    if [[ ! -f "$source_file" ]]; then
        print_warning "Source file not found: $source_file"
        ((WARNING_COUNT++))
        echo ""
        continue
    fi
    
    # Backup existing file if it exists
    if [[ -f "$dest_file" ]]; then
        backup_file="${dest_file}${BACKUP_SUFFIX}"
        print_info "Backing up existing $filename to ${filename}${BACKUP_SUFFIX}"
        
        if cp -p "$dest_file" "$backup_file"; then
            print_success "Backup created: $backup_file"
        else
            print_error "Failed to create backup for $filename"
            exit 1
        fi
    else
        print_info "No existing $filename to backup"
    fi
    
    # Copy the file
    print_info "Copying $filename to $DEST_DIR"
    if cp "$source_file" "$dest_file"; then
        print_success "Copied $filename"
    else
        print_error "Failed to copy $filename"
        exit 1
    fi
    
    # Set permissions
    if chmod 644 "$dest_file"; then
        print_success "Set permissions (644) on $filename"
    else
        print_warning "Failed to set permissions on $filename"
    fi
    
    ((SUCCESS_COUNT++))
    echo ""
done

# Final summary
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Setup Complete! ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Summary:"
echo "  ✓ Successfully processed: $SUCCESS_COUNT file(s)"
if [[ $WARNING_COUNT -gt 0 ]]; then
    echo "  ⚠ Warnings: $WARNING_COUNT"
fi
echo ""
if [[ $SUCCESS_COUNT -gt 0 ]]; then
    print_info "Backups stored with suffix: $BACKUP_SUFFIX"
    echo ""
    print_info "You may need to restart greetd for changes to take effect:"
    echo "  sudo systemctl restart greetd"
fi
echo ""
