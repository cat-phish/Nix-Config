#!/usr/bin/env bash

set -euo pipefail

# Script to install proprietary NVIDIA drivers on Fedora
# Usage: ./setup-nvidia-drivers.sh [OPTIONS]

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
    echo "This script requires root privileges.  Requesting sudo..."
    exec sudo "$0" "$@"
fi

# Get actual user info
if [ -n "${SUDO_USER:-}" ]; then
    ACTUAL_USER="$SUDO_USER"
    ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    ACTUAL_USER="$USER"
    ACTUAL_HOME="$HOME"
fi

# Check for skip confirmation flag
SKIP_CONFIRM=false
SKIP_REBOOT_PROMPT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-confirm|-y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        --skip-reboot)
            SKIP_REBOOT_PROMPT=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Install proprietary NVIDIA drivers on Fedora x86_64."
            echo ""
            echo "Options:"
            echo "  -y, --yes, --skip-confirm    Skip confirmation prompt"
            echo "  --skip-reboot                 Don't prompt to reboot after installation"
            echo "  -h, --help                   Show this help message"
            echo ""
            echo "What this script does:"
            echo "  1. Checks for NVIDIA GPU"
            echo "  2. Enables RPM Fusion repositories"
            echo "  3. Installs NVIDIA proprietary drivers"
            echo "  4. Installs CUDA support (optional)"
            echo "  5. Configures system for NVIDIA"
            echo "  6. Updates initramfs"
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

# Confirmation prompt (unless skipped)
if [[ "$SKIP_CONFIRM" != true ]]; then
    echo -e "${BOLD}${BLUE}==========================================${NC}"
    echo -e "${BOLD}${BLUE}  NVIDIA Proprietary Drivers Setup${NC}"
    echo -e "${BOLD}${BLUE}==========================================${NC}"
    echo ""
    echo "This script will install NVIDIA proprietary drivers"
    echo "on your Fedora x86_64 system."
    echo ""
    echo -e "${YELLOW}What will be installed:${NC}"
    echo "  • RPM Fusion repositories (free and nonfree)"
    echo "  • NVIDIA proprietary driver (akmod-nvidia)"
    echo "  • NVIDIA X. Org configuration"
    echo "  • NVIDIA CUDA libraries (optional)"
    echo "  • Kernel modules and dependencies"
    echo ""
    echo -e "${YELLOW}Requirements:${NC}"
    echo "  • NVIDIA GPU must be present"
    echo "  • Secure Boot should be disabled (or configured)"
    echo "  • System will need to reboot after installation"
    echo ""
    echo -e "${RED}Warning: ${NC} This will replace Nouveau (open source) drivers"
    echo ""
    echo -ne "${BOLD}Do you want to continue? [y/N]: ${NC}"
    read -r response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi

    echo ""
fi

print_info "Starting NVIDIA driver installation..."
echo ""

# Step 1: Detect NVIDIA GPU
print_info "Step 1: Detecting NVIDIA GPU..."
if lspci | grep -i nvidia > /dev/null; then
    GPU_INFO=$(lspci | grep -i nvidia | head -n 1)
    print_success "NVIDIA GPU detected: $GPU_INFO"
else
    print_error "No NVIDIA GPU detected!"
    print_error "This script is only for systems with NVIDIA graphics cards."
    exit 1
fi
echo ""

# Step 2: Check Secure Boot status
print_info "Step 2: Checking Secure Boot status..."
if command -v mokutil &> /dev/null; then
    if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
        print_warning "Secure Boot is ENABLED"
        print_warning "NVIDIA drivers may not load properly with Secure Boot."
        print_warning "You may need to disable Secure Boot in BIOS or enroll MOK keys."
        echo ""
        if [[ "$SKIP_CONFIRM" != true ]]; then
            echo -n "Continue anyway? [y/N]: "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                echo "Setup cancelled."
                exit 0
            fi
        fi
    else
        print_success "Secure Boot is disabled"
    fi
else
    print_warning "Cannot determine Secure Boot status"
fi
echo ""

# Step 3: Update system
print_info "Step 3: Updating system packages..."
if dnf update -y; then
    print_success "System updated"
else
    print_error "Failed to update system"
    exit 1
fi
echo ""

# Step 4: Enable RPM Fusion repositories
print_info "Step 4: Enabling RPM Fusion repositories..."

# Check if already enabled
if dnf repolist | grep -q "rpmfusion"; then
    print_info "RPM Fusion already enabled"
else
    print_info "Installing RPM Fusion repositories..."
    if dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm; then
        print_success "RPM Fusion repositories enabled"
    else
        print_error "Failed to enable RPM Fusion repositories"
        exit 1
    fi
fi
echo ""

# Step 5: Install kernel development packages
print_info "Step 5: Installing kernel development packages..."
if dnf install -y kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig; then
    print_success "Kernel development packages installed"
else
    print_error "Failed to install kernel development packages"
    exit 1
fi
echo ""

# Step 6: Install NVIDIA drivers
print_info "Step 6: Installing NVIDIA proprietary drivers..."
if dnf install -y akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686; then
    print_success "NVIDIA drivers installed"
else
    print_error "Failed to install NVIDIA drivers"
    exit 1
fi
echo ""

# Step 7: Ask about CUDA support
if [[ "$SKIP_CONFIRM" != true ]]; then
    echo -n "Do you want to install CUDA support? (for ML/AI workloads) [y/N]: "
    read -r cuda_response
    if [[ "$cuda_response" =~ ^[Yy]$ ]]; then
        print_info "Installing CUDA support..."
        if dnf install -y xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs; then
            print_success "CUDA support installed"
        else
            print_warning "Failed to install CUDA support (continuing anyway)"
        fi
    fi
    echo ""
fi

# Step 8: Install additional multimedia codecs
print_info "Step 7: Installing multimedia acceleration..."
if dnf install -y nvidia-vaapi-driver libva-utils vdpauinfo; then
    print_success "Multimedia acceleration installed"
else
    print_warning "Failed to install multimedia acceleration (continuing anyway)"
fi
echo ""

# Step 9: Blacklist Nouveau driver
print_info "Step 8: Blacklisting Nouveau driver..."
BLACKLIST_FILE="/etc/modprobe.d/blacklist-nouveau.conf"
if [[ !  -f "$BLACKLIST_FILE" ]]; then
    cat > "$BLACKLIST_FILE" << 'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
    print_success "Nouveau driver blacklisted"
else
    print_info "Nouveau already blacklisted"
fi
echo ""

# Step 10: Update GRUB configuration
print_info "Step 9: Updating GRUB configuration..."
GRUB_FILE="/etc/default/grub"
if grep -q "nvidia-drm.modeset=1" "$GRUB_FILE"; then
    print_info "GRUB already configured for NVIDIA"
else
    sed -i 's/\(GRUB_CMDLINE_LINUX=".*\)"/\1 nvidia-drm.modeset=1 rd.driver.blacklist=nouveau modprobe.blacklist=nouveau"/' "$GRUB_FILE"
    if command -v grub2-mkconfig &> /dev/null; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
        print_success "GRUB configuration updated"
    else
        print_warning "Could not update GRUB (grub2-mkconfig not found)"
    fi
fi
echo ""

# Step 11: Rebuild initramfs
print_info "Step 10: Rebuilding initramfs..."
if dracut -f; then
    print_success "Initramfs rebuilt"
else
    print_warning "Failed to rebuild initramfs (may need manual rebuild)"
fi
echo ""

# Step 12: Wait for kernel modules to build
print_info "Step 11: Waiting for kernel modules to build..."
print_info "This may take several minutes..."
echo ""

# Check if akmods is running
if systemctl is-active --quiet akmods; then
    print_info "Akmods service is building kernel modules..."
    print_info "Waiting for completion..."
    
    # Wait up to 10 minutes for akmods to finish
    TIMEOUT=600
    ELAPSED=0
    while systemctl is-active --quiet akmods && [ $ELAPSED -lt $TIMEOUT ]; do
        echo -n "."
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    done
    echo ""
    
    if [ $ELAPSED -ge $TIMEOUT ]; then
        print_warning "Akmods timed out (this is usually okay)"
    else
        print_success "Kernel modules built"
    fi
else
    # Trigger akmods manually
    print_info "Triggering akmods manually..."
    if akmods --force; then
        print_success "Kernel modules built"
    else
        print_warning "Akmods returned an error (drivers may still work after reboot)"
    fi
fi
echo ""

# Step 13: Enable nvidia services
print_info "Step 12: Enabling NVIDIA services..."
systemctl enable nvidia-suspend.service
systemctl enable nvidia-hibernate.service
systemctl enable nvidia-resume.service
print_success "NVIDIA services enabled"
echo ""

# Final summary
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Installation Complete! ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Summary:"
echo "  ✓ NVIDIA GPU detected"
echo "  ✓ RPM Fusion repositories enabled"
echo "  ✓ NVIDIA drivers installed"
echo "  ✓ Nouveau driver blacklisted"
echo "  ✓ System configured for NVIDIA"
echo "  ✓ Kernel modules building/built"
echo ""
print_warning "IMPORTANT: You MUST reboot for the drivers to take effect!"
echo ""
print_info "After reboot, verify installation with:"
echo "  nvidia-smi"
echo "  glxinfo | grep NVIDIA"
echo ""

# Reboot prompt
if [[ "$SKIP_REBOOT_PROMPT" != true ]]; then
    echo -n "Do you want to reboot now? [y/N]: "
    read -r reboot_response
    if [[ "$reboot_response" =~ ^[Yy]$ ]]; then
        print_info "Rebooting in 5 seconds...  (Ctrl+C to cancel)"
        sleep 5
        reboot
    else
        print_info "Remember to reboot when ready!"
    fi
fi
echo ""
