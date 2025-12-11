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
confirmed_hostname=""
confirmed_username=""

os_id=$(detect_os)
machine_type=$(detect_machine_type)

echo "==== System Detection ===="
echo "Detected OS: $os_id"
echo "Detected Machine Type: $machine_type"
echo ""

# Prompt for username with confirmation loop
username_confirmed=false
while [ "$username_confirmed" = false ]; do
    read -p "Enter username for home-manager flake: " input_username
    
    if [ -z "$input_username" ]; then
        echo "⚠️  Username cannot be empty."
        continue
    fi
    
    echo ""
    echo "Username: $input_username"
    read -p "Is this correct? (y/n): " username_check
    
    if [[ "$username_check" =~ ^[Yy]$ ]]; then
        confirmed_username="$input_username"
        username_confirmed=true
    else
        echo "Let's try again."
        echo ""
    fi
done

echo ""

# Ask for confirmation if OS was detected
if [ "$os_id" = "nixos" ] || [ "$os_id" = "fedora" ]; then
    read -p "Is this a $os_id $machine_type?  (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        confirmed_os="$os_id"
        confirmed_machine="$machine_type"
        
        # Present default hostname
        default_hostname="$confirmed_os-$confirmed_machine"
        echo ""
        echo "Default hostname for flake: $default_hostname"
        read -p "Use this hostname?  (y/n): " hostname_confirm
        
        if [[ "$hostname_confirm" =~ ^[Yy]$ ]]; then
            confirmed_hostname="$default_hostname"
        else
            read -p "Enter alternate hostname: " alt_hostname
            
            if [ -n "$alt_hostname" ]; then
                confirmed_hostname="$alt_hostname"
                echo ""
                echo "⚠️  IMPORTANT: This hostname must already be configured in your Nix config."
                echo "   Flake configuration: $confirmed_hostname"
                read -p "Do you understand and confirm this hostname exists in your config? (y/n): " hostname_exists_confirm
                
                if [[ !  "$hostname_exists_confirm" =~ ^[Yy]$ ]]; then
                    echo "Cannot continue without valid hostname configuration. Exiting."
                    exit 1
                fi
            else
                echo "Hostname cannot be empty. Exiting."
                exit 1
            fi
        fi
    else
        # User disagreed with detection
        confirmed_os=""
        confirmed_machine=""
    fi
fi

# If auto-detection failed or user disagreed, show manual menu
if [ -z "$confirmed_os" ]; then
    echo ""
    echo "Please choose your system manually:"
    echo "1) NixOS Desktop"
    echo "2) NixOS Laptop"
    echo "3) Fedora Desktop"
    echo "4) Fedora Laptop"
    echo "5) Custom configuration"
    read -p "Enter the number of your choice: " choice

    case $choice in
        1)
            confirmed_os="nixos"
            confirmed_machine="desktop"
            confirmed_hostname="nixos-desktop"
            ;;
        2)
            confirmed_os="nixos"
            confirmed_machine="laptop"
            confirmed_hostname="nixos-laptop"
            ;;
        3)
            confirmed_os="fedora"
            confirmed_machine="desktop"
            confirmed_hostname="fedora-desktop"
            ;;
        4)
            confirmed_os="fedora"
            confirmed_machine="laptop"
            confirmed_hostname="fedora-laptop"
            ;;
        5)
            echo ""
            echo "=== Custom Configuration ==="
            echo ""
            
            # OS Selection
            echo "Select OS:"
            echo "1) NixOS"
            echo "2) Fedora"
            echo "3) Other (exit)"
            read -p "Enter choice (1-3): " os_choice
            
            case $os_choice in
                1)
                    confirmed_os="nixos"
                    ;;
                2)
                    confirmed_os="fedora"
                    ;;
                3)
                    echo ""
                    echo "⚠️  This script is not configured to setup other system types."
                    echo "Currently supported: NixOS and Fedora only."
                    exit 1
                    ;;
                *)
                    echo "Invalid choice. Exiting."
                    exit 1
                    ;;
            esac
            
            # Machine Type Selection
            echo ""
            echo "Select machine type:"
            echo "1) Desktop"
            echo "2) Laptop"
            echo "3) Other (exit)"
            read -p "Enter choice (1-3): " machine_choice
            
            case $machine_choice in
                1)
                    confirmed_machine="desktop"
                    ;;
                2)
                    confirmed_machine="laptop"
                    ;;
                3)
                    echo ""
                    echo "⚠️  This script is not configured to setup other machine types."
                    echo "Currently supported: Desktop and Laptop only."
                    exit 1
                    ;;
                *)
                    echo "Invalid choice. Exiting."
                    exit 1
                    ;;
            esac
            
            # Hostname Entry
            echo ""
            read -p "Enter hostname for flake: " custom_hostname
            
            if [ -z "$custom_hostname" ]; then
                echo "Hostname cannot be empty. Exiting."
                exit 1
            fi
            
            confirmed_hostname="$custom_hostname"
            
            echo ""
            echo "⚠️  IMPORTANT: This hostname must already be configured in your Nix config."
            echo "   Flake configuration: $confirmed_hostname"
            echo "   Expected OS: $confirmed_os"
            echo "   Expected Machine: $confirmed_machine"
            read -p "Do you understand and confirm this hostname exists in your config? (y/n): " hostname_exists_confirm
            
            if [[ !  "$hostname_exists_confirm" =~ ^[Yy]$ ]]; then
                echo "Cannot continue without valid hostname configuration. Exiting."
                exit 1
            fi
            ;;
        *)
            echo "Invalid choice.Exiting."
            exit 1
            ;;
    esac
fi

echo ""
echo "==== Configuration ===="
echo "Username: $confirmed_username"
echo "OS: $confirmed_os"
echo "Machine: $confirmed_machine"
echo "Hostname: $confirmed_hostname"
echo ""

# ==== SETUP CONFIGURATION ===========================================

# Build flake references using the confirmed hostname and username
if [ "$confirmed_os" = "nixos" ]; then
    nixos_flake="$confirmed_hostname"
    home_manager_flake="$confirmed_username@$confirmed_hostname"
elif [ "$confirmed_os" = "fedora" ]; then
    home_manager_flake="$confirmed_username@$confirmed_hostname"
    # Set system hostname to match flake hostname
    hostname="$confirmed_hostname"
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
    ## UPDATE THIS WHEN ADDING/REMOVING STEPS ##
    local TOTAL_STEPS=13
    local STEP=0

    echo "==== Starting Fedora Setup ===="
    echo ""

    # TODO: setup talon
    # TODO: setup tailscale

    # Prompt for KDE Plasma management
    read -p "Would you like to manage KDE Plasma with Nix? (y/n): " manage_plasma
    if [[ "$manage_plasma" =~ ^[Yy]$ ]]; then
        use_plasma=true
        TOTAL_STEPS=$((TOTAL_STEPS + 1))
        echo "[✓] KDE Plasma management will be configured."
    else
        use_plasma=false
        echo "[✓] Skipping KDE Plasma management."
    fi
    echo ""

    # Prompt for Niri installation
    read -p "Would you like to install Niri? (y/n): " install_niri
    if [[ "$install_niri" =~ ^[Yy]$ ]]; then
        use_niri=true
        TOTAL_STEPS=$((TOTAL_STEPS + 1))
        echo "[✓] Niri will be installed."
    else
        use_niri=false
        echo "[✓] Skipping Niri installation."
    fi
    echo ""

    # Prompt for fingerprint setup
    read -p "Would you like to enable fingerprint authentication for sudo? (y/n): " setup_fingerprint
    if [[ "$setup_fingerprint" =~ ^[Yy]$ ]]; then
        use_fingerprint=true
        TOTAL_STEPS=$((TOTAL_STEPS + 1))
        echo "[✓] Fingerprint management will be configured."
    else
        use_fingerprint=false
        echo "[✓] Skipping fingerprint management."
    fi
    echo ""

    # Prompt for Tailscale setup
    read -p "Would you configure Tailscale? (y/n): " setup_tailscale
    if [[ "$setup_tailscale" =~ ^[Yy]$ ]]; then
        use_tailscale=true
        TOTAL_STEPS=$((TOTAL_STEPS + 1))
        echo "[✓] Tailscale will be configured."
    else
        use_tailscale=false
        echo "[✓] Skipping configuration."
    fi
    echo ""

    # TODO: fix the total steps math here, move the confirmation to above
    # Setup fingerprint authentication
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Configuring fingerprint authentication..."

    read -p "Would you like to enable fingerprint authentication for sudo? (y/n): " setup_fingerprint

    if [ "$use_fingerprint" = true ]; then
        # Check if fprintd is installed
        if ! command -v fprintd-enroll &> /dev/null; then
            echo "Installing fprintd..."
            sudo dnf install -y fprintd fprintd-pam
        fi

        PAM_FILE="/etc/pam.d/sudo"

        # Check if already configured
        if grep -q "pam_fprintd.so" "$PAM_FILE"; then
            echo "[✓] Fingerprint authentication already configured"
        else
            # Backup and configure
            sudo cp "$PAM_FILE" "${PAM_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
            sudo sed -i '/#%PAM-1.0/a auth       sufficient   pam_fprintd.so' "$PAM_FILE"
            echo "[✓] Fingerprint authentication configured"
        fi
        
        # Prompt to enroll fingerprint
        read -p "Enroll fingerprint now? (y/n): " enroll_now
        if [[ "$enroll_now" =~ ^[Yy]$ ]]; then
            fprintd-enroll
            echo "[✓] Fingerprint enrolled"
        else
            echo "You can enroll later with: fprintd-enroll"
        fi
    else
        echo "[✓] Skipping fingerprint authentication setup"
    fi
    echo ""

    # Setup Tailscale
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Setting up Tailscale..."

    if [ "$use_tailscale" = true ]; then
        # Check if Tailscale is already installed
        if !  command -v tailscale &> /dev/null; then
            echo "Installing Tailscale..."
            
            # Add Tailscale repository
            sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
            
            # Install Tailscale
            sudo dnf install -y tailscale
            
            echo "[✓] Tailscale installed"
        else
            echo "[✓] Tailscale already installed"
        fi
        
        # Enable and start Tailscale service
        sudo systemctl enable --now tailscaled
        echo "[✓] Tailscale service enabled and started"
        
        # Check if already authenticated
        if sudo tailscale status &> /dev/null && sudo tailscale status | grep -q "Logged in"; then
            echo "[✓] Tailscale already authenticated"
            echo ""
            echo "Current Tailscale status:"
            sudo tailscale status
        else
            echo ""
            echo "Tailscale needs to be authenticated..."
            read -p "Authenticate Tailscale now? (y/n): " auth_now
            
            if [[ "$auth_now" =~ ^[Yy]$ ]]; then
                # Ask about additional options
                echo ""
                echo "Tailscale authentication options:"
                read -p "Accept routes from other devices? (y/n): " accept_routes
                read -p "Advertise this machine as an exit node? (y/n): " exit_node
                read -p "Enable SSH access via Tailscale? (y/n): " tailscale_ssh
                
                # Build tailscale up command
                TAILSCALE_CMD="sudo tailscale up"
                
                [[ "$accept_routes" =~ ^[Yy]$ ]] && TAILSCALE_CMD="$TAILSCALE_CMD --accept-routes"
                [[ "$exit_node" =~ ^[Yy]$ ]] && TAILSCALE_CMD="$TAILSCALE_CMD --advertise-exit-node"
                [[ "$tailscale_ssh" =~ ^[Yy]$ ]] && TAILSCALE_CMD="$TAILSCALE_CMD --ssh"
                
                echo ""
                echo "Running: $TAILSCALE_CMD"
                echo "This will open a browser window for authentication..."
                
                eval $TAILSCALE_CMD
                
                echo ""
                echo "[✓] Tailscale configured"
                echo ""
                echo "Tailscale status:"
                sudo tailscale status
            else
                echo "You can authenticate later with: sudo tailscale up"
            fi
        fi
        
        echo ""
        echo "Useful Tailscale commands:"
        echo "  sudo tailscale status      - Show connection status"
        echo "  sudo tailscale ip          - Show your Tailscale IP"
        echo "  sudo tailscale ping <host> - Ping another device"
        echo "  sudo tailscale down        - Disconnect"
    else
        echo "[✓] Skipping Tailscale setup"
    fi
    echo ""

    # Install Niri (conditional)
    if [ "$use_niri" = true ]; then
        STEP=$((STEP + 1))
        echo "[$STEP/$TOTAL_STEPS] Installing Niri..."
        sudo dnf copr enable -y avengemedia/dms
        sudo dnf install -y niri dms
        systemctl --user add-wants niri.service dms
        # TODO: add prompt above for dankgreet default
        # Enable dankgreet
        sudo dnf copr enable avengemedia/danklinux
        sudo dnf install -y dms-greeter
        dms greeter enable
        dms greeter sync
        dms greeter status
        sudo systemctl enable greetd
        sudo systemctl start greetd
        echo ""
    fi

    # Install Kitty
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Installing Kitty..."
    sudo dnf copr enable -y gagbo/kitty-latest
    sudo dnf --refresh install -y kitty
    echo ""

    # Install Nix
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Installing Nix..."
    sudo dnf copr enable -y petersen/nix
    sudo dnf install -y nix
    sudo systemctl enable --now nix-daemon
    echo ""

    # Setup Nix channels and home-manager
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Setting up Nix channels and home-manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    echo ""

    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Installing home-manager..."
    nix-shell '<home-manager>' -A install
    echo ""

    # Source home-manager session variables
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Sourcing home-manager session variables..."
    if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi
    echo ""

    # Set hostname
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Setting hostname to $hostname..."
    sudo hostnamectl set-hostname "$hostname"
    echo ""

    # Clone Nix config if not already present
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Setting up Nix configuration..."
    if [ ! -d "$HOME/.nix" ]; then
        git clone https://github.com/cat-phish/Nix-Config.git "$HOME/.nix"
    else
        echo "~/.nix already exists, skipping clone."
    fi
    cd "$HOME/.nix" || exit 1
    echo ""

    # Copy dotfiles
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Copying dotfiles..."
    mkdir -p ~/.icons
    if [ -d "./dotfiles/.icons" ]; then
        cp -rf ./dotfiles/.icons/* ~/.icons/
    fi

    mkdir -p ~/.themes
    if [ -d "./dotfiles/.themes" ]; then
        cp -rf ./dotfiles/.themes/* ~/.themes/
    fi
    echo ""

    # Setup KDE Plasma management (conditional)
    if [ "$use_plasma" = true ]; then
      STEP=$((STEP + 1))
      echo "[$STEP/$TOTAL_STEPS] Setting up KDE Plasma management..."
      if [ -f "$HOME/.nix/dotfiles/.scripts/nix-plasma-update" ]; then
        bash "$HOME/.nix/dotfiles/.scripts/nix-plasma-update"
        echo "[✓] KDE Plasma management configured."
      else
        echo "⚠️  nix-plasma-update script not found at ~/.nix/dotfiles/.scripts/nix-plasma-update"
        echo "[!] Skipping KDE Plasma setup."
      fi
      echo ""
    fi

    # Apply home-manager configuration
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Applying home-manager configuration..."
    home-manager switch --flake ".#$home_manager_flake" || \
        home-manager switch -b backup --flake ".#$home_manager_flake"
    echo ""

    # Setup kmonad
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Setting up kmonad..."
    if [ -f "$HOME/.nix/setup/fedora-kmonad-setup.sh" ]; then
        bash "$HOME/.nix/setup/fedora-kmonad-setup.sh" setup
    else
        echo "⚠️  fedora-kmonad-setup.sh not found at ~/.nix/setup/fedora-kmonad-setup.sh"
        read -p "Skip kmonad setup? (y/n): " skip_kmonad
        if [[ !  "$skip_kmonad" =~ ^[Yy]$ ]]; then
            echo "Please run kmonad setup manually later."
        fi
    fi
    echo ""

    # Change git remote to SSH
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Changing git remote to SSH..."
    cd "$HOME/.nix" || exit 1
    git remote set-url origin git@github.com:cat-phish/NixOS-Config.git
    echo "[✓] Git remote set to: git@github.com:cat-phish/NixOS-Config.git"
    echo ""

    # Prompt for manual session variables
    echo "==== Manual Steps Required ===="
    echo "Please add the following to your shell configuration (~/.bashrc or ~/.zshrc):"
    echo ""
    echo "  source \$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
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
    ## UPDATE THIS WHEN ADDING/REMOVING STEPS ##
    local TOTAL_STEPS=5
    local STEP=0

    echo "==== Starting NixOS Setup ===="
    echo ""

    # Change to .nix directory
    if [ !  -d "$HOME/.nix" ]; then
        echo "~/.nix does not exist."
        read -p "Would you like to clone the Nix config?   (y/n): " clone_choice
        if [[ "$clone_choice" =~ ^[Yy]$ ]]; then
            git clone https://github.com/cat-phish/Nix-Config.git "$HOME/.nix"
        else
            echo "Cannot continue without Nix config. Exiting."
            exit 1
        fi
    fi

    cd "$HOME/.nix" || exit 1

    # Copy hardware configuration
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Copying hardware configuration..."

    HW_CONFIG_SOURCE="/etc/nixos/hardware-configuration.nix"
    HW_CONFIG_DEST="$HOME/.nix/modules/hardware-config/$confirmed_hostname-hardware.nix"

    # Ensure destination directory exists
    mkdir -p "$(dirname "$HW_CONFIG_DEST")"

    # Check if destination exists and ask for confirmation
    if [ -f "$HW_CONFIG_DEST" ]; then
        echo "⚠️  Hardware configuration already exists at:"
        echo "   $HW_CONFIG_DEST"
        read -p "Overwrite?  (y/n): " overwrite_choice
        
        if [[ "$overwrite_choice" =~ ^[Yy]$ ]]; then
            cp -f "$HW_CONFIG_SOURCE" "$HW_CONFIG_DEST"
            echo "[✓] Hardware configuration copied."
        else
            read -p "Enter an alternate filename (or press Enter to skip): " alt_name
            
            if [ -n "$alt_name" ]; then
                # Use alternate name in the same directory
                ALT_DEST="$(dirname "$HW_CONFIG_DEST")/$alt_name"
                
                if cp "$HW_CONFIG_SOURCE" "$ALT_DEST"; then
                    echo "[✓] Hardware configuration saved as: $alt_name"
                else
                    echo "[! ] Failed to copy to alternate location. Skipping."
                fi
            else
                echo "[! ] Skipping hardware configuration copy."
            fi
        fi
    else
        # File doesn't exist, just copy
        if cp "$HW_CONFIG_SOURCE" "$HW_CONFIG_DEST"; then
            echo "[✓] Hardware configuration copied."
        else
            echo "[!] Failed to copy hardware configuration."
            read -p "Would you like to enter an alternate name?  (y/n): " alt_choice
            
            if [[ "$alt_choice" =~ ^[Yy]$ ]]; then
                read -p "Enter alternate filename: " alt_name
                
                if [ -n "$alt_name" ]; then
                    ALT_DEST="$(dirname "$HW_CONFIG_DEST")/$alt_name"
                    
                    if cp "$HW_CONFIG_SOURCE" "$ALT_DEST"; then
                        echo "[✓] Hardware configuration saved as: $alt_name"
                    else
                        echo "[!] Failed to copy. Continuing anyway..."
                    fi
                fi
            fi
        fi
    fi

    echo ""

    # Copy local share files
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Copying local share files..."
    mkdir -p ~/.local/share
    if [ -d "./dotfiles/.local/share" ]; then
        cp -rf ./dotfiles/.local/share/* ~/.local/share/
    fi
    echo ""

    # Copy icons and themes
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Copying icons and themes..."
    mkdir -p ~/.icons
    if [ -d "./dotfiles/.icons" ]; then
        cp -rf ./dotfiles/.icons/* ~/.icons/
    fi

    mkdir -p ~/.themes
    if [ -d "./dotfiles/.themes" ]; then
        cp -rf ./dotfiles/.themes/* ~/.themes/
    fi
    echo ""

    # Rebuild NixOS
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Rebuilding NixOS..."
    sudo nixos-rebuild switch --flake ".#$nixos_flake"
    echo ""

    # Apply home-manager
    echo "Applying home-manager configuration..."
    home-manager switch --flake ".#$home_manager_flake"
    echo ""

    # Change git remote to SSH
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL_STEPS] Changing git remote to SSH..."
    cd "$HOME/.nix" || exit 1
    git remote set-url origin git@github.com:cat-phish/NixOS-Config.git
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
