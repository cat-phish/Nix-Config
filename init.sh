#!/usr/bin/env bash

# ==== OS DETECTION & CONFIRMATION ===================================

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

detect_machine_type() {
    # Detect if laptop or desktop based on battery presence
    if [ -d /sys/class/power_supply/BAT* ] 2>/dev/null || [ -d /sys/class/power_supply/battery ] 2>/dev/null; then
        echo "laptop"
    else
        echo "desktop"
    fi
}

confirmed_os=""
confirmed_machine=""

os_id=$(detect_os)
machine_type=$(detect_machine_type)

echo "==== System Detection ===="
echo "Detected OS: $os_id"
echo "Detected Machine Type: $machine_type"
echo ""

if [ "$os_id" = "nixos" ]; then
    read -p "Is this a NixOS $machine_type?  (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        confirmed_os="nixos"
        confirmed_machine="$machine_type"
    fi
elif [ "$os_id" = "fedora" ]; then
    read -p "Is this a Fedora $machine_type? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        confirmed_os="fedora"
        confirmed_machine="$machine_type"
    fi
fi

# If auto-detection failed or user disagreed, show manual menu
if [ -z "$confirmed_os" ]; then
    echo ""
    echo "Please choose your system manually:"
    echo "1) Desktop NixOS"
    echo "2) Laptop NixOS"
    echo "3) Fedora Desktop"
    echo "4) Fedora Laptop"
    read -p "Enter the number of your choice: " choice

    case $choice in
        1)
            confirmed_os="nixos"
            confirmed_machine="desktop"
            ;;
        2)
            confirmed_os="nixos"
            confirmed_machine="laptop"
            ;;
        3)
            confirmed_os="fedora"
            confirmed_machine="desktop"
            ;;
        4)
            confirmed_os="fedora"
            confirmed_machine="laptop"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

echo ""
echo "==== Configuration ===="
echo "OS: $confirmed_os"
echo "Machine: $confirmed_machine"
echo ""

# ==== SETUP CONFIGURATION ===========================================

if [ "$confirmed_os" = "nixos" ]; then
    if [ "$confirmed_machine" = "desktop" ]; then
        nixos_flake="jordans-desktop"
        home_manager_flake="jordan@jordans-desktop"
    else
        nixos_flake="jordans-laptop"
        home_manager_flake="jordan@jordans-laptop"
    fi
elif [ "$confirmed_os" = "fedora" ]; then
    if [ "$confirmed_machine" = "desktop" ]; then
        home_manager_flake="jordan@fedora-desktop"
        hostname="fedora-desktop"
    else
        home_manager_flake="jordan@fedora-laptop"
        hostname="fedora-laptop"
    fi
fi

# ==== CHECK IF ALREADY RUN ==========================================

MARKER_FILE="$HOME/.nix-setup-complete"
if [ -f "$MARKER_FILE" ]; then
    echo "⚠️  Setup appears to have been run before."
    read -p "Continue from where you left off? (y/n): " continue_choice
    if [[ !  "$continue_choice" =~ ^[Yy]$ ]]; then
        rm "$MARKER_FILE"
        echo "Starting from the beginning..."
    fi
fi

# ==== FEDORA SETUP ==================================================

setup_fedora() {
    echo "==== Starting Fedora Setup ===="
    echo ""

    # Install Niri
    echo "[1/12] Installing Niri..."
    sudo dnf copr enable -y avengemedia/dms
    sudo dnf install -y niri dms
    systemctl --user add-wants niri.service dms
    echo ""

    # Install Kitty
    echo "[2/12] Installing Kitty..."
    sudo dnf copr enable -y gagbo/kitty-latest
    sudo dnf --refresh install -y kitty
    echo ""

    # Install Nix
    echo "[3/12] Installing Nix..."
    sudo dnf copr enable -y petersen/nix
    sudo dnf install -y nix
    sudo systemctl enable --now nix-daemon
    echo ""

    # Setup Nix channels and home-manager
    echo "[4/12] Setting up Nix channels and home-manager..."
    nix-channel --add https://github. com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    echo ""

    echo "[5/12] Installing home-manager..."
    nix-shell '<home-manager>' -A install
    echo ""

    # Source home-manager session variables
    echo "[6/12] Sourcing home-manager session variables..."
    if [ -f "$HOME/.nix-profile/etc/profile. d/hm-session-vars.sh" ]; then
        source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi
    echo ""

    # Set hostname
    echo "[7/12] Setting hostname to $hostname..."
    sudo hostnamectl set-hostname "$hostname"
    echo ""

    # Clone Nix config if not already present
    echo "[8/12] Setting up Nix configuration..."
    if [ ! -d "$HOME/.nix" ]; then
        git clone https://github.com/cat-phish/Nix-Config.git "$HOME/.nix"
    else
        echo "~/.nix already exists, skipping clone."
    fi
    cd "$HOME/.nix" || exit 1
    echo ""

    # Copy dotfiles
    echo "[9/12] Copying dotfiles..."
    mkdir -p ~/. icons
    if [ -d "./dotfiles/.icons" ]; then
        cp -r ./dotfiles/.icons/* ~/.icons/
    fi

    mkdir -p ~/.themes
    if [ -d "./dotfiles/. themes" ]; then
        cp -r ./dotfiles/.themes/* ~/.themes/
    fi
    echo ""

    # Apply home-manager configuration
    echo "[10/12] Applying home-manager configuration..."
    home-manager switch --flake ". #$home_manager_flake" || \
        home-manager switch -b backup --flake ". #$home_manager_flake"
    echo ""

    # Setup kmonad
    echo "[11/12] Setting up kmonad..."
    if [ -f "$HOME/.nix/scripts/kmonad-setup.sh" ]; then
        bash "$HOME/.nix/scripts/kmonad-setup.sh" setup
    else
        echo "⚠️  kmonad-setup.sh not found at ~/. nix/scripts/kmonad-setup.sh"
        read -p "Skip kmonad setup? (y/n): " skip_kmonad
        if [[ !  "$skip_kmonad" =~ ^[Yy]$ ]]; then
            echo "Please run kmonad setup manually later."
        fi
    fi
    echo ""

    # Change git remote to SSH
    echo "[12/12] Changing git remote to SSH..."
    cd "$HOME/.nix" || exit 1
    git remote set-url origin git@github.com:cat-phish/NixOS-Config.git
    echo "[✓] Git remote set to: git@github.com:cat-phish/NixOS-Config.git"
    echo ""

    # Prompt for manual session variables
    echo "==== Manual Steps Required ===="
    echo "Please add the following to your shell configuration (~/.bashrc or ~/.zshrc):"
    echo ""
    echo "  source \$HOME/. nix-profile/etc/profile.d/hm-session-vars.sh"
    echo ""
    read -p "Have you added this line? (y/n): " session_vars_confirm
    if [[ ! "$session_vars_confirm" =~ ^[Yy]$ ]]; then
        echo "⚠️  Please add this line before continuing!"
    fi
    echo ""

    # Mark setup as complete
    touch "$MARKER_FILE"

    # Prompt for reboot
    echo "==== Fedora Setup Complete ===="
    read -p "Would you like to reboot now? (y/n): " reboot_choice
    if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
        sudo reboot
    else
        echo "Please reboot your system when convenient."
    fi
}

# ==== NIXOS SETUP ===================================================

setup_nixos() {
    echo "==== Starting NixOS Setup ===="
    echo ""

    # Change to . nix directory
    if [ !  -d "$HOME/.nix" ]; then
        echo "~/.nix does not exist."
        read -p "Would you like to clone the Nix config?  (y/n): " clone_choice
        if [[ "$clone_choice" =~ ^[Yy]$ ]]; then
            git clone https://github. com/cat-phish/Nix-Config.git "$HOME/.nix"
        else
            echo "Cannot continue without Nix config.  Exiting."
            exit 1
        fi
    fi

    cd "$HOME/.nix" || exit 1

    # Copy hardware configuration
    echo "[1/5] Copying hardware configuration..."
    cp /etc/nixos/hardware-configuration.nix "$HOME/. nix/hosts/$confirmed_machine/hardware-configuration.nix"
    echo ""

    # Copy local share files
    echo "[2/5] Copying local share files..."
    mkdir -p ~/. local/share
    if [ -d "./dotfiles/.local/share" ]; then
        cp -r ./dotfiles/.local/share/* ~/.local/share/
    fi
    echo ""

    # Copy icons and themes
    echo "[3/5] Copying icons and themes..."
    mkdir -p ~/. icons
    if [ -d "./dotfiles/. icons" ]; then
        cp -r ./dotfiles/.icons/* ~/.icons/
    fi

    mkdir -p ~/.themes
    if [ -d "./dotfiles/.themes" ]; then
        cp -r ./dotfiles/.themes/* ~/. themes/
    fi
    echo ""

    # Rebuild NixOS
    echo "[4/5] Rebuilding NixOS..."
    sudo nixos-rebuild switch --flake ".#$nixos_flake"
    echo ""

    # Apply home-manager
    echo "Applying home-manager configuration..."
    home-manager switch --flake ".#$home_manager_flake"
    echo ""

    # Change git remote to SSH
    echo "[5/5] Changing git remote to SSH..."
    cd "$HOME/. nix" || exit 1
    git remote set-url origin git@github.com:cat-phish/NixOS-Config. git
    echo "[✓] Git remote set to: git@github.com:cat-phish/NixOS-Config.git"
    echo ""

    # Mark setup as complete
    touch "$MARKER_FILE"

    echo "==== NixOS Setup Complete ===="
}

# ==== MAIN EXECUTION ================================================

if [ "$confirmed_os" = "fedora" ]; then
    setup_fedora
elif [ "$confirmed_os" = "nixos" ]; then
    setup_nixos
else
    echo "Unknown OS configuration. Exiting."
    exit 1
fi

exit 0
