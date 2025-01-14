#!/bin/bash

# Set UUID of iPod
uuid="0934-729C"

#Mount iPod
udisksctl unmount -b /dev/disk/by-uuid/$uuid
