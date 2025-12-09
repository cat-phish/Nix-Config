#!/usr/bin/env bash

LOG_FILE="$HOME/.config/restic/backup.log"

log() {
  echo ""
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

if [ -z "$RESTIC_PASSWORD" ]; then
  log "Please set the RESTIC_PASSWORD environment variable."
  exit 1
fi

if [ -z "$RESTIC_HOST" ]; then
  log "Please set the RESTIC_HOST environment variable."
  exit 1
fi

if ! command -v restic &> /dev/null; then
  log "Restic is not installed. Please install Restic first."
  exit 1
fi

if ! command -v rclone &> /dev/null; then
  log "Rclone is not installed. Please install Rclone first."
  exit 1
fi

# Restic repos
home_repo="$RESTIC_HOST/home/backup/linux-desktop"
music_repo="$RESTIC_HOST/home/backup/music"
xbox_repo="$RESTIC_HOST/home/backup/xbox"

# Paths to backup files
home_paths_file="$HOME/.config/restic/home_backup_paths.txt"
music_dir="/mnt/music_hdd/Library"
xbox_paths_file="$HOME/.config/restic/xbox_backup_paths.txt"

perform_backup() {
  local repo=$1
  local paths=$2
  local tag=$3
  local is_file=$4

  if [ "$is_file" = true ]; then
    if [ ! -f "$paths" ]; then
      log "The specified paths file '$paths' does not exist."
      return
    fi
    log "Starting Restic backup with tag '$tag' using paths from file '$paths'..."
    restic -r "$repo" backup --files-from="$paths" --tag="$tag" --verbose
    # restic -r "$repo" backup --files-from="$paths" --tag="$tag" --verbose 2>&1 | tee -a "$LOG_FILE"
  else
    log "Starting Restic backup with tag '$tag' for paths '$paths'..."
    restic -r "$repo" backup "$paths" --tag="$tag" --verbose
    # restic -r "$repo" backup $paths --tag="$tag" --verbose 2>&1 | tee -a "$LOG_FILE"
  fi

  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "Restic backup failed for tag '$tag'."
  else
    log "Restic backup completed for tag '$tag'."
  fi
}

perform_prune() {
  local repo="$1"
  local tag="$2"

  log "Pruning snapshots with tag '$tag'..."
  restic -r "$repo" forget --tag="$tag" --keep-last 1 --keep-daily 1 --keep-weekly 1 --keep-monthly 3 --prune 2>&1 | tee -a "$LOG_FILE"
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "Restic prune failed for tag '$tag'."
  else
    log "Restic prune completed for tag '$tag'."
  fi
}

show_menu() {
  while true; do
    clear
    echo "Backup Linux Desktop"
    echo "--------------------------------------"
    echo "(H) Backup Home"
    echo "(M) Backup Music"
    echo "(G) Backup Games"
    echo "(X) Backup Xbox"
    echo "(A) Backup All"
    echo "(Q) Quit"
    read -rp "Select a number or 'Q' to Quit: " choice

    case $choice in
      H|h)
        perform_backup "$home_repo" "$home_paths_file" "home" true
        perform_prune "$home_repo" "home"
        exit 0
        ;;
      M|m)
        perform_backup "$music_repo" "$music_dir" "library" false
        perform_prune "$music_repo" "library"
        exit 0
        ;;
      G|g)
        echo "games backup not set up yet"
        exit 0
        ;;
      X|x)
        perform_backup "$xbox_repo" "$xbox_paths_file" "xbox" true
        # perform_prune "$xbox_repo" "xbox"
        exit 0
        ;;
      A|a)
        perform_backup "$home_repo" "$home_paths_file" "home" true
        perform_backup "$music_repo" "$music_dir" "library" false
        perform_backup "$xbox_repo" "$xbox_paths_file" "xbox" true
        perform_prune "$home_repo" "home"
        perform_prune "$music_repo" "library"
        perform_prune "$xbox_repo" "xbox"
        exit 0
        ;;
      Q|q)
        log "Quitting..."
        exit 0
        ;;
      *)
        log "Invalid choice. Please select a valid option."
        ;;
    esac
  done
}

show_menu
