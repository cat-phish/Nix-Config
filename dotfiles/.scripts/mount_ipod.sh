#!/usr/bin/env bash

# Set UUID of iPod
uuid="D5AE-9E4C"

#Mount iPod
mount_point=$(udisksctl mount -b /dev/disk/by-uuid/$uuid | cut -d" " -f 4 | tr -d '\n')

echo "Mounted at $mount_point"
