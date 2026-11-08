#!/usr/bin/env bash

set -euo pipefail

# Enroll the local module-signing keys (akmods for NVIDIA, DKMS for xone) into
# MOK so their kernel modules load with Secure Boot enabled.
# Each install generates new keys, so run this again after a reinstall.
# Usage: ./fedora-secureboot-mok-setup.sh [-y|--yes]

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges. Requesting sudo..."
    exec sudo "$0" "$@"
fi

ASSUME_YES=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes) ASSUME_YES=true; shift ;;
        -h|--help)
            echo "Usage: $0 [-y|--yes]"
            echo ""
            echo "Queue the akmods (NVIDIA) and DKMS (xone) signing keys for MOK enrollment."
            echo "  -y, --yes    Don't ask before queueing the keys"
            exit 0
            ;;
        *) print_error "Unknown option: $1"; exit 1 ;;
    esac
done

echo -e "${BOLD}${BLUE}==========================================${NC}"
echo -e "${BOLD}${BLUE}   Secure Boot: enroll module signing keys${NC}"
echo -e "${BOLD}${BLUE}==========================================${NC}"
echo ""

if ! command -v mokutil &> /dev/null; then
    print_info "Installing mokutil..."
    dnf install -y mokutil
fi

CANDIDATES=(
    "/etc/pki/akmods/certs/public_key.der"   # akmods (NVIDIA)
    "/var/lib/dkms/mok.pub"                  # DKMS (xone)
)

TO_IMPORT=()
for key in "${CANDIDATES[@]}"; do
    if [[ ! -f "$key" ]]; then
        print_info "Not found (driver not built yet?): $key"
        continue
    fi
    # --test-key output says whether the key is enrolled or already queued
    result=$(mokutil --test-key "$key" 2>&1 || true)
    if grep -qiE 'already enrolled' <<< "$result"; then
        print_success "Already enrolled: $key"
    elif grep -qiE 'already in the enrollment request' <<< "$result"; then
        print_success "Already queued (finish enrollment on next reboot): $key"
    else
        TO_IMPORT+=("$key")
        print_info "Not enrolled: $key"
    fi
done
echo ""

if [[ ${#TO_IMPORT[@]} -eq 0 ]]; then
    print_success "Nothing to enroll."
    exit 0
fi

if [[ "$ASSUME_YES" != true ]]; then
    echo "Enrolling these keys lets the NVIDIA/xone drivers load with Secure Boot on."
    echo "You'll set a one-time password now, then confirm it on a blue"
    echo "'MOK management' screen at next reboot (Enroll MOK > Continue > Yes)."
    echo "Use a throwaway password, not your login password."
    echo ""
    echo -ne "${BOLD}Enroll the keys now? [y/N]: ${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Skipped. Run this script later to enroll: $0"
        exit 0
    fi
fi

if mokutil --import "${TO_IMPORT[@]}"; then
    print_success "Keys queued for enrollment."
    echo ""
    print_warning "Next steps:"
    echo "  1. Reboot and complete the blue MOK screen (Enroll MOK > Continue > Yes > password)."
    echo "  2. Enable Secure Boot in BIOS (MSI: Del > Settings > Security > Secure Boot)."
    echo "  3. Verify: mokutil --sb-state; lsmod | grep -E 'nvidia|xone'"
else
    print_error "mokutil --import failed."
    exit 1
fi
