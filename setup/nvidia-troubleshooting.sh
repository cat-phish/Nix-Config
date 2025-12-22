#!/usr/bin/env bash

echo "=========================================="
echo "  NVIDIA Driver Verification"
echo "=========================================="
echo ""

# Check if nvidia-smi works
if command -v nvidia-smi &> /dev/null; then
    echo "✓ nvidia-smi found"
    echo ""
    nvidia-smi
    echo ""
else
    echo "✗ nvidia-smi not found"
fi

# Check loaded kernel modules
echo "Loaded NVIDIA kernel modules:"
lsmod | grep nvidia
echo ""

# Check OpenGL
if command -v glxinfo &> /dev/null; then
    echo "OpenGL renderer:"
    glxinfo | grep -i "opengl renderer"
    glxinfo | grep -i "opengl version"
else
    echo "Install glx-utils to check OpenGL:  sudo dnf install glx-utils"
fi
echo ""

# Check Xorg log
if [[ -f /var/log/Xorg.0.log ]]; then
    echo "Xorg driver:"
    grep -i nvidia /var/log/Xorg.0.log | head -3
fi
