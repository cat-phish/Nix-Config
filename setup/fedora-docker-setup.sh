#!/usr/bin/env bash

set -euo pipefail

# Script to setup Docker on Fedora
# Usage: ./setup-docker.sh [--skip-confirm | -y]

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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
            echo "Options:"
            echo "  -y, --yes, --skip-confirm    Skip confirmation prompt"
            echo "  -h, --help                   Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Confirmation prompt (unless skipped)
if [[ "$SKIP_CONFIRM" != true ]]; then
    echo "=========================================="
    echo "  Fedora Docker Setup"
    echo "=========================================="
    echo ""
    echo "This will configure docker for Fedora"
    echo "including everything needed for Winboat."
    echo ""
    echo -n "Do you want to continue? [y/N]: "
    read -r response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi

    echo ""
fi

echo -e "${GREEN}Proceeding with setup...${NC}"
echo ""

# Get the actual user's home directory (not root's)
if [ -n "${SUDO_USER:-}" ]; then
    ACTUAL_USER="$SUDO_USER"
    ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    ACTUAL_USER="$USER"
    ACTUAL_HOME="$HOME"
fi

# Install Docker
echo -e "${YELLOW}Installing Docker... ${NC}"
if dnf install -y docker docker-compose; then
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${RED}✗ Failed to install Docker${NC}"
    exit 1
fi

# Create docker group if it doesn't exist
if ! getent group docker > /dev/null 2>&1; then
    echo -e "${YELLOW}Creating docker group...${NC}"
    groupadd docker
    echo -e "${GREEN}✓ Docker group created${NC}"
else
    echo -e "${GREEN}✓ Docker group already exists${NC}"
fi

# Add user to docker group
echo -e "${YELLOW}Adding $ACTUAL_USER to docker group...${NC}"
usermod -aG docker "$ACTUAL_USER"
echo -e "${GREEN}✓ User added to docker group${NC}"

# Enable Docker services
echo -e "${YELLOW}Enabling Docker services...${NC}"
systemctl enable docker.service
systemctl enable containerd.service
echo -e "${GREEN}✓ Services enabled${NC}"

# Start Docker services
echo -e "${YELLOW}Starting Docker services...${NC}"
systemctl start docker.service
systemctl start containerd.service
echo -e "${GREEN}✓ Services started${NC}"

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Docker Setup Complete! ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: ${NC} Log out and log back in for group changes to take effect."
echo "Or run: ${GREEN}newgrp docker${NC}"
echo ""
