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

# Set the Rclone config file
# export RCLONE_CONFIG="$HOME/.config/rclone/rclone-hetzner.conf"

# Restic repos
home_repo="$RESTIC_HOST/home/backup/linux-desktop"
music_repo_base="$RESTIC_HOST/home/backup/music"
music_repo_numbers_d="$music_repo_base/num-d"
music_repo_e_h="$music_repo_base/e-h"
music_repo_i_m="$music_repo_base/i-m"
music_repo_n_s="$music_repo_base/n-s"
music_repo_t_z_beyond="$music_repo_base/t-z-beyond"

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
    restic -r "$repo" backup --files-from="$paths" --tag="$tag" 2>&1 | tee -a "$LOG_FILE"
  else
    log "Starting Restic backup with tag '$tag' for paths '$paths'..."
    restic -r "$repo" backup $paths --tag="$tag" 2>&1 | tee -a "$LOG_FILE"
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
        perform_backup "$music_repo_numbers_d" "$MUSIC_DIR/[0-9A-D]*" "music-num-d" false
        perform_prune "$music_repo_numbers_d" "music-num-d"
        ;;
      3)
        perform_backup "$music_repo_e_h" "$MUSIC_DIR/[E-H]*" "music-e-h" false
        perform_prune "$music_repo_e_h" "music-e-h"
        ;;
      4)
        perform_backup "$music_repo_i_m" "$MUSIC_DIR/[I-M]*" "music-i-m" false
        perform_prune "$music_repo_i_m" "music-i-m"
        ;;
      5)
        perform_backup "$music_repo_n_s" "$MUSIC_DIR/[N-S]*" "music-n-s" false
        perform_prune "$music_repo_n_s" "music-n-s"
        ;;
      6)
        perform_backup "$music_repo_t_z_beyond" "$MUSIC_DIR/[T-Z]* $MUSIC_DIR/[!0-9A-Za-z]*" "music-t-z-beyond" false
        perform_prune "$music_repo_t_z_beyond" "music-t-z-beyond"
        ;;
      A|a)
        perform_backup "$home_repo" "$home_paths_file" "home" true
        perform_backup "$music_repo_numbers_d" "$MUSIC_DIR/[0-9A-D]*" "music-num-d" false
        perform_backup "$music_repo_e_h" "$MUSIC_DIR/[E-H]*" "music-e-h" false
        perform_backup "$music_repo_i_m" "$MUSIC_DIR/[I-M]*" "music-i-m" false
        perform_backup "$music_repo_n_s" "$MUSIC_DIR/[N-S]*" "music-n-s" false
        perform_backup "$music_repo_t_z_beyond" "$MUSIC_DIR/[T-Z]* $MUSIC_DIR/[!0-9A-Za-z]*" "music-t-z-beyond" false
        perform_prune "$home_repo" "home"
        perform_prune "$music_repo_numbers_d" "music-num-d"
        perform_prune "$music_repo_e_h" "music-e-h"
        perform_prune "$music_repo_i_m" "music-i-m"
        perform_prune "$music_repo_n_s" "music-n-s"
        perform_prune "$music_repo_t_z_beyond" "music-t-z-beyond"
        ;;
      M|m)
        perform_backup "$music_repo_numbers_d" "$MUSIC_DIR/[0-9A-D]*" "music-num-d" false
        perform_backup "$music_repo_e_h" "$MUSIC_DIR/[E-H]*" "music-e-h" false
        perform_backup "$music_repo_i_m" "$MUSIC_DIR/[I-M]*" "music-i-m" false
        perform_backup "$music_repo_n_s" "$MUSIC_DIR/[N-S]*" "music-n-s" false
        perform_backup "$music_repo_t_z_beyond" "$MUSIC_DIR/[T-Z]* $MUSIC_DIR/[!0-9A-Za-z]*" "music-t-z-beyond" false
        perform_prune "$music_repo_numbers_d" "music-num-d"
        perform_prune "$music_repo_e_h" "music-e-h"
        perform_prune "$music_repo_i_m" "music-i-m"
        perform_prune "$music_repo_n_s" "music-n-s"
        perform_prune "$music_repo_t_z_beyond" "music-t-z-beyond"
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
