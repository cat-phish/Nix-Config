#!/usr/bin/env bash

# ==== KMONAD UDEV SETUP SCRIPT ======================================
#
# This script can be used both interactively and called from other scripts.
#
# ==== USAGE =========================================================
#
# Interactive Mode (shows menu):
#   ./kmonad-setup.sh
#
# Command-line Mode:
#   ./kmonad-setup.sh setup     # Run all setup steps (non-interactive)
#   ./kmonad-setup.sh cleanup   # Run cleanup (non-interactive)
#   ./kmonad-setup.sh groups    # Just create system groups & add user
#   ./kmonad-setup.sh udev      # Just copy udev rules
#   ./kmonad-setup. sh module    # Just setup uinput module
#   ./kmonad-setup.sh reload    # Just reload udev rules
#   ./kmonad-setup.sh verify    # Just verify permissions
#   ./kmonad-setup. sh service   # Just start systemd service
#
# Calling from Another Script:
#
#   Method 1: Execute with arguments
#     /path/to/kmonad-setup.sh setup
#
#   Method 2: Source and call functions
#     source /path/to/kmonad-setup. sh
#     create_and_assign_groups
#     copy_udev_rules
#     setup_uinput_module
#     reload_udev_rules
#     verify_permissions
#     start_systemd_service
#
#   Method 3: Source and run all steps non-interactively
#     source /path/to/kmonad-setup.sh
#     run_all_steps_silent
#
#   Method 4: Source and run cleanup non-interactively
#     source /path/to/kmonad-setup.sh
#     run_cleanup_silent
#
# Environment Variables:
#   TARGET_USER - Override the user to add to groups (default: $USER)
#
#   Example:
#     TARGET_USER=jordan /path/to/kmonad-setup.sh setup
#
# ====================================================================

# ==== CONFIG ============================================================
UDEV_RULES_FILE="/etc/udev/rules.d/90-uinput.rules"
UDEV_CONTENT='KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"'
MODULES_LOAD_FILE="/etc/modules-load. d/uinput.conf"
SYSTEMD_SERVICE="kmonad.service"
TARGET_USER="${TARGET_USER:-$USER}"
# =======================================================================


# ==== FUNCTIONS: OPERATIONS ============================================

create_and_assign_groups() {
    echo "[+] Ensuring 'uinput' system group exists (GID < 1000)..."
    
    # Check if group exists
    if getent group uinput >/dev/null 2>&1; then
        current_gid=$(getent group uinput | cut -d: -f3)
        if [[ $current_gid -ge 1000 ]]; then
            echo "[!] uinput group exists but is not a system group (GID=$current_gid)"
            echo "[+] Removing and recreating as system group..."
            sudo groupdel uinput
            sudo groupadd -r uinput
            echo "[✓] uinput system group recreated."
        else
            echo "[✓] uinput system group already exists (GID=$current_gid)."
        fi
    else
        sudo groupadd -r uinput
        echo "[✓] uinput system group created."
    fi

    echo "[+] Adding user '$TARGET_USER' to 'input' and 'uinput' groups..."
    sudo usermod -aG input,uinput "$TARGET_USER"

    if [[ $?  -eq 0 ]]; then
        echo "[✓] User '$TARGET_USER' added to groups: input, uinput"
        echo "⚠️  You MUST log out/in or reboot for this to take effect."
    else
        echo "[! ] Failed to modify user groups."
    fi
    echo
}

copy_udev_rules() {
    echo "[+] Copying KMonad udev rule to $UDEV_RULES_FILE ..."
    echo "$UDEV_CONTENT" | sudo tee "$UDEV_RULES_FILE" >/dev/null
    echo "[✓] Udev rule copied."
    echo
}

setup_uinput_module() {
    echo "[+] Configuring uinput module to load at boot..."
    echo "uinput" | sudo tee "$MODULES_LOAD_FILE" >/dev/null
    echo "[✓] uinput module will load at boot."
    
    echo "[+] Loading uinput module now..."
    if lsmod | grep -q uinput; then
        echo "[+] uinput module already loaded, reloading..."
        sudo rmmod uinput 2>/dev/null
    fi
    sudo modprobe uinput
    echo "[✓] uinput module loaded."
    echo
}

reload_udev_rules() {
    echo "[+] Reloading udev rules..."
    sudo udevadm control --reload-rules
    sudo udevadm trigger --name-match=uinput
    echo "[✓] Udev rules reloaded and triggered."
    echo
}

verify_permissions() {
    echo "[+] Verifying /dev/uinput permissions..."
    if [[ -e /dev/uinput ]]; then
        ls -l /dev/uinput
        
        # Check if permissions are correct
        perms=$(stat -c "%a" /dev/uinput 2>/dev/null)
        group=$(stat -c "%G" /dev/uinput 2>/dev/null)
        
        if [[ "$perms" == "660" ]] && [[ "$group" == "uinput" ]]; then
            echo "[✓] Permissions are correct: 660, group: uinput"
        else
            echo "[!] Permissions may be incorrect. Expected: 660, uinput"
            echo "    Current: $perms, $group"
        fi
    else
        echo "[!] /dev/uinput does not exist."
    fi
    echo
}

start_systemd_service() {
    echo "[+] Enabling & starting KMonad systemd user service: $SYSTEMD_SERVICE"
    systemctl --user enable --now "$SYSTEMD_SERVICE"
    echo "[✓] Service enabled and started."
    echo
}

# ==== CLEANUP ==========================================================

remove_udev_rules() {
    if [[ -f "$UDEV_RULES_FILE" ]]; then
        echo "[+] Removing udev rule: $UDEV_RULES_FILE"
        sudo rm -f "$UDEV_RULES_FILE"
        echo "[✓] Udev rule removed."
    else
        echo "[!] No udev rule to remove."
    fi
    echo
}

remove_module_config() {
    if [[ -f "$MODULES_LOAD_FILE" ]]; then
        echo "[+] Removing module load config: $MODULES_LOAD_FILE"
        sudo rm -f "$MODULES_LOAD_FILE"
        echo "[✓] Module load config removed."
    else
        echo "[!] No module load config to remove."
    fi
    echo
}

stop_systemd_service() {
    echo "[+] Disabling & stopping $SYSTEMD_SERVICE ..."
    systemctl --user disable --now "$SYSTEMD_SERVICE"
    echo "[✓] Service stopped & disabled."
    echo
}

# ==== HELPER: CONFIRMATION ============================================

confirm() {
    read -rp "Proceed? (y/n): " c
    [[ "$c" =~ ^[Yy]$ ]]
}

# ==== GROUPED ACTIONS ==================================================

run_all_steps() {
    echo "⚙️  Running all setup steps with confirmation..."
    echo

    echo "➡️  Step 1: Create system groups + add user"
    if confirm; then create_and_assign_groups; fi

    echo "➡️  Step 2: Copy udev rules"
    if confirm; then copy_udev_rules; fi

    echo "➡️  Step 3: Setup uinput module to load at boot"
    if confirm; then setup_uinput_module; fi

    echo "➡️  Step 4: Reload udev rules"
    if confirm; then reload_udev_rules; fi

    echo "➡️  Step 5: Verify permissions"
    if confirm; then verify_permissions; fi

    echo "➡️  Step 6: Start KMonad systemd service"
    if confirm; then start_systemd_service; fi

    echo "🎉 Setup finished.  Don't forget to log out or reboot!"
}

run_all_steps_silent() {
    echo "⚙️  Running all setup steps (non-interactive)..."
    echo
    create_and_assign_groups
    copy_udev_rules
    setup_uinput_module
    reload_udev_rules
    verify_permissions
    start_systemd_service
    echo "🎉 Setup finished. Don't forget to log out or reboot!"
}

run_cleanup() {
    echo "🧹 Cleaning up KMonad setup (confirmation per step)..."
    echo

    echo "➡️  Remove udev rules"
    if confirm; then remove_udev_rules; fi

    echo "➡️  Remove module load config"
    if confirm; then remove_module_config; fi

    echo "➡️  Reload udev rules"
    if confirm; then reload_udev_rules; fi

    echo "➡️  Stop KMonad systemd service"
    if confirm; then stop_systemd_service; fi

    echo "🪣 Cleanup complete."
}

run_cleanup_silent() {
    echo "🧹 Cleaning up KMonad setup (non-interactive)..."
    echo
    remove_udev_rules
    remove_module_config
    reload_udev_rules
    stop_systemd_service
    echo "🪣 Cleanup complete."
}

# ==== MAIN EXECUTION (only when NOT sourced) =======================

main() {
    echo "================== KMonad Setup Menu =================="
    echo "1) Do ALL setup steps (with confirmation)"
    echo "2) Just create system groups & add user"
    echo "3) Just copy udev rules"
    echo "4) Just setup uinput module"
    echo "5) Just reload udev rules"
    echo "6) Just verify permissions"
    echo "7) Just start the systemd service"
    echo "8) 🧹 Cleanup (remove rules, reload, stop service)"
    echo "========================================================="
    read -rp "Choose an option (1-8): " choice
    echo

    case "$choice" in
        1) run_all_steps ;;
        2) create_and_assign_groups ;;
        3) copy_udev_rules ;;
        4) setup_uinput_module ;;
        5) reload_udev_rules ;;
        6) verify_permissions ;;
        7) start_systemd_service ;;
        8) run_cleanup ;;
        *)
            echo "❌ Invalid option."
            exit 1 ;;
    esac
}

# Only run main menu if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
    exit 0
fi
