#!/usr/bin/env bash

SOURCE="/mnt/music_hdd/Library/"
DEST="$MEDIASERVER_SSH_USER@mediaserver:/mnt/user/music/library/"
LOGFILE="/tmp/rsync_dry_run.log"

# Run dry-run rsync and capture output
echo "Running dry-run rsync..."
rsync -azvh --delete --progress --dry-run "$SOURCE" "$DEST" > "$LOGFILE" 2>&1

# Extract files marked for deletion
DELETED_FILES=$(grep '^deleting ' "$LOGFILE" | sed 's/^deleting //')

# Check if there are files to be deleted
if [ -n "$DELETED_FILES" ]; then
    echo "Warning! The following files will be deleted from the destination:"
    echo "---------------------------------------------------------------"
    echo "$DELETED_FILES" | less  # Paginate output if long
    echo "---------------------------------------------------------------"
    
    read -p "Do you want to proceed with the sync? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Syncing..."
        rsync -azvh --delete --progress "$SOURCE" "$DEST"
    else
        echo "Sync canceled."
    fi
else
    echo "No files will be deleted. Running sync..."
    read -p "Do you want to proceed with the sync? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Syncing..."
        rsync -azvh --delete --progress "$SOURCE" "$DEST"
    else
        echo "Sync canceled."
    fi
fi
