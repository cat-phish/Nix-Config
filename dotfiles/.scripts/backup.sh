#!/usr/bin/env bash

LOG_FILE="$HOME/.config/restic/backup.log"
MUSIC_DIR="/mnt/music_hdd/Library"

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

# Paths to backup files
home_paths_file="$HOME/.config/restic/home_backup_paths.txt"

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
    restic -r "$repo" backup --files-from="$paths" --tag="$tag" --verbose 2>&1 | tee -a "$LOG_FILE"
  else
    log "Starting Restic backup with tag '$tag' for paths '$paths'..."
    restic -r "$repo" backup $paths --tag="$tag" --verbose 2>&1 | tee -a "$LOG_FILE"
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
    echo "(1) Backup Home"
    echo "(2) Backup Music (Num-D)"
    echo "(3) Backup Music (E-H)"
    echo "(4) Backup Music (I-M)"
    echo "(5) Backup Music (N-S)"
    echo "(6) Backup Music (T-Z and beyond)"
    echo "(A) Backup All"
    echo "(M) Backup All Music"
    echo "(X) Exit"
    read -rp "Select a number or 'X' to Exit: " choice

    case $choice in
      1)
        perform_backup "$home_repo" "$home_paths_file" "home" true
        perform_prune "$home_repo" "home"
        ;;
      2)
        perform_backup "$music_repo" "$MUSIC_DIR/[0-9A-D]*" "num-d" false
        perform_prune "$music_repo" "num-d"
        ;;
      3)
        perform_backup "$music_repo" "$MUSIC_DIR/[E-H]*" "e-h" false
        perform_prune "$music_repo" "e-h"
        ;;
      4)
        perform_backup "$music_repo" "$MUSIC_DIR/[I-M]*" "i-m" false
        perform_prune "$music_repo" "i-m"
        ;;
      5)
        perform_backup "$music_repo" "$MUSIC_DIR/[N-S]*" "n-s" false
        perform_prune "$music_repo" "n-s"
        ;;
      6)
        perform_backup "$music_repo" "$MUSIC_DIR/[T-Z]* $MUSIC_DIR/[!0-9A-Za-z]*" "t-z-beyond" false
        perform_prune "$music_repo" "t-z-beyond"
        ;;
      A|a)
        perform_backup "$home_repo" "$home_paths_file" "home" true
        perform_backup "$music_repo" "$MUSIC_DIR/[0-9A-D]*" "num-d" false
        perform_backup "$music_repo" "$MUSIC_DIR/[E-H]*" "e-h" false
        perform_backup "$music_repo" "$MUSIC_DIR/[I-M]*" "i-m" false
        perform_backup "$music_repo" "$MUSIC_DIR/[N-S]*" "n-s" false
        perform_backup "$music_repo" "$MUSIC_DIR/[T-Z]* $MUSIC_DIR/[!0-9A-Za-z]*" "t-z-beyond" false
        perform_prune "$home_repo" "home"
        perform_prune "$music_repo" "num-d"
        perform_prune "$music_repo" "e-h"
        perform_prune "$music_repo" "i-m"
        perform_prune "$music_repo" "n-s"
        perform_prune "$music_repo" "t-z-beyond"
        ;;
      M|m)
        perform_backup "$music_repo" "$MUSIC_DIR/[0-9A-D]*" "num-d" false
        perform_backup "$music_repo" "$MUSIC_DIR/[E-H]*" "e-h" false
        perform_backup "$music_repo" "$MUSIC_DIR/[I-M]*" "i-m" false
        perform_backup "$music_repo" "$MUSIC_DIR/[N-S]*" "n-s" false
        perform_backup "$music_repo" "$MUSIC_DIR/[T-Z]* $MUSIC_DIR/[!0-9A-Za-z]*" "t-z-beyond" false
        perform_prune "$music_repo" "num-d"
        perform_prune "$music_repo" "e-h"
        perform_prune "$music_repo" "i-m"
        perform_prune "$music_repo" "n-s"
        perform_prune "$music_repo" "t-z-beyond"
        ;;
      X|x)
        log "Exiting..."
        exit 0
        ;;
      *)
        log "Invalid choice. Please select a valid option."
        ;;
    esac
  done
}

show_menu
