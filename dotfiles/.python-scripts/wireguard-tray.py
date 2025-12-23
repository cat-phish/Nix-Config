#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path

import pystray
from PIL import Image, ImageDraw
from pystray import MenuItem as item

WG_CONFIG_DIR = "/etc/wireguard"


# def get_configs():
#     """Get list of available WireGuard config files."""
#     config_path = Path(WG_CONFIG_DIR)
#     if config_path.exists():
#         return [f.stem for f in config_path.glob("*.conf")]
#     return []
def get_configs():
    """Get list of available WireGuard config files using sudo."""
    try:
        # Use sudo to list the directory
        result = subprocess.run(
            ["sudo", "ls", WG_CONFIG_DIR], capture_output=True, text=True, check=False
        )

        if result.returncode != 0:
            print(f"Error listing configs: {result.stderr}")
            return []

        # Filter for . conf files and remove extension
        configs = [
            f.replace(".conf", "")
            for f in result.stdout.strip().split("\n")
            if f.endswith(". conf")
        ]
        return configs
    except Exception as e:
        print(f"Exception getting configs: {e}")
        return []


def get_active_interfaces():
    """Get list of currently active WireGuard interfaces."""
    try:
        result = subprocess.run(
            ["wg", "show", "interfaces"], capture_output=True, text=True
        )
        return result.stdout.strip().split()
    except:
        return []


def is_connected(config_name):
    """Check if a specific config is currently connected."""
    return config_name in get_active_interfaces()


def connect(config_name):
    """Connect to a WireGuard config."""

    def action(icon, item):
        subprocess.run(["pkexec", "wg-quick", "up", config_name])
        icon.menu = build_menu()
        update_icon(icon)

    return action


def disconnect(config_name):
    """Disconnect from a WireGuard config."""

    def action(icon, item):
        subprocess.run(["pkexec", "wg-quick", "down", config_name])
        icon.menu = build_menu()
        update_icon(icon)

    return action


def disconnect_all(icon, item):
    """Disconnect all active WireGuard interfaces."""
    for iface in get_active_interfaces():
        subprocess.run(["pkexec", "wg-quick", "down", iface])
    icon.menu = build_menu()
    update_icon(icon)


def create_icon(connected=False):
    """Create a simple tray icon."""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Green if connected, gray if not
    color = (46, 204, 113) if connected else (149, 165, 166)

    # Draw a simple shield shape
    draw.ellipse([8, 8, size - 8, size - 8], fill=color)

    # Draw "W" for WireGuard
    draw.text((size // 2 - 10, size // 2 - 12), "W", fill="white")

    return img


def update_icon(icon):
    """Update the icon based on connection status."""
    connected = len(get_active_interfaces()) > 0
    icon.icon = create_icon(connected)


def build_menu():
    """Build the dynamic menu."""
    configs = get_configs()
    active = get_active_interfaces()

    menu_items = []

    # Status
    if active:
        status = f"Connected:  {', '.join(active)}"
    else:
        status = "Disconnected"
    menu_items.append(item(status, None, enabled=False))
    menu_items.append(item("─────────────", None, enabled=False))

    # Config entries
    for config in configs:
        if config in active:
            menu_items.append(item(f"✓ {config} (Disconnect)", disconnect(config)))
        else:
            menu_items.append(item(f"  {config} (Connect)", connect(config)))

    if not configs:
        menu_items.append(item("No configs found", None, enabled=False))

    menu_items.append(item("─────────────", None, enabled=False))

    # Disconnect all (only if something is connected)
    if active:
        menu_items.append(item("Disconnect All", disconnect_all))

    menu_items.append(item("Quit", lambda icon, item: icon.stop()))

    return pystray.Menu(*menu_items)


def main():
    connected = len(get_active_interfaces()) > 0
    icon = pystray.Icon(
        "wireguard-tray", create_icon(connected), "WireGuard", menu=build_menu()
    )
    icon.run()


if __name__ == "__main__":
    main()
