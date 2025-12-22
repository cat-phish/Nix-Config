#!/usr/bin/env bash

echo "=========================================="
echo "  NVIDIA Troubleshooting"
echo "=========================================="
echo ""

echo "1.  Checking NVIDIA GPU:"
lspci | grep -i nvidia
echo ""

echo "2. Checking if Nouveau is loaded (should be empty):"
lsmod | grep nouveau
echo ""

echo "3. Checking if NVIDIA modules are loaded:"
lsmod | grep nvidia
echo ""

echo "4. Checking NVIDIA driver version:"
modinfo nvidia | grep ^version
echo ""

echo "5. Checking akmods status:"
systemctl status akmods --no-pager
echo ""

echo "6. Checking kernel version:"
uname -r
echo ""

echo "7. Checking if nvidia driver is in initramfs:"
sudo lsinitrd | grep nvidia
echo ""
