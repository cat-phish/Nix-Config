#!/usr/bin/env bash

# Set UUID of iPod
uuid="D5AE-9E4C"

#Mount iPod
udisksctl unmount -b /dev/disk/by-uuid/$uuid
