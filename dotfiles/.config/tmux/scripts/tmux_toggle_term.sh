#!/usr/bin/env bash

# Tmux Toggle Term
# TODO: decide if we want to force primary term name, or be able to set it according to the current command
# TODO: figure out best way to clean up state files. At Tmux startup?

CURRENT_SHELL=$(which zsh)

TERMINAL_PANE_NAME="Toggle-Term"
PRIMARY_PANE_NAME="Primary-Term"

TOGGLETERM_COMMAND=${1:-bottom}
SPLIT_SIZE=${2:-30}

SESSION_ID=$(tmux display-message -p "#{session_id}")
WINDOW_ID=$(tmux display-message -p "#{window_id}")

STATE_DIR="/tmp/tmux_toggle_term"
mkdir -p "$STATE_DIR"

STATE_FILE="${STATE_DIR}/toggle_term_state_${SESSION_ID}_${WINDOW_ID}"

TOGGLETERM_COUNT=$(tmux list-panes -F "#{pane_title}" | grep -c "^$TERMINAL_PANE_NAME$")
NON_TOGGLETERM_COUNT=$(tmux list-panes -F "#{pane_title}" | grep -vc "^$TERMINAL_PANE_NAME$")

CURRENT_PANE=$(tmux display-message -p "#{pane_id}")


create_toggle_term_pane() {
  local direction=$1
  tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
  if [[ "$direction" == "bottom" ]]; then
    PANE_ID=$(tmux split-window -v -p "$SPLIT_SIZE" -P -F "#{pane_id}" -t "$CURRENT_PANE" "$CURRENT_SHELL")
    tmux select-pane -T "$TERMINAL_PANE_NAME" -t "$PANE_ID"
  elif [[ "$direction" == "right" ]]; then
    PANE_ID=$(tmux split-window -h -p "$SPLIT_SIZE" -P -F "#{pane_id}" -t "$CURRENT_PANE" "$CURRENT_SHELL")
    tmux select-pane -T "$TERMINAL_PANE_NAME" -t "$PANE_ID"
  fi
}

set_primary_pane() {
  tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
  tmux list-panes -F "#{pane_id}" | while read -r pane_id; do
    if [[ "$pane_id" != "$CURRENT_PANE" ]]; then
      tmux select-pane -T "$TERMINAL_PANE_NAME" -t "$pane_id"
    fi
  done
  echo "$CURRENT_PANE" > "$STATE_FILE"
  tmux resize-pane -Z -t "$CURRENT_PANE"
}

if [[ "$TOGGLETERM_COMMAND" == "primary" ]]; then
  set_primary_pane
else
  if [[ "$TOGGLETERM_COUNT" -eq 0 ]]; then
    rm -f "$STATE_FILE"
    if [[ "$NON_TOGGLETERM_COUNT" -eq 1 ]]; then
      if [[ "$TOGGLETERM_COMMAND" == "bottom" ]]; then
        create_toggle_term_pane "bottom"
      elif [[ "$TOGGLETERM_COMMAND" == "right" ]]; then
        create_toggle_term_pane "right"
      fi
    elif [[ "$NON_TOGGLETERM_COUNT" -gt 1 ]]; then
      tmux list-panes -F "#{pane_id}" | while read -r pane_id; do
        if [[ "$pane_id" != "$CURRENT_PANE" ]]; then
          tmux select-pane -T "$TERMINAL_PANE_NAME" -t "$pane_id"
        fi
      done
      tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
      tmux resize-pane -Z -t "$CURRENT_PANE"
    fi
  else
    if [[ "$NON_TOGGLETERM_COUNT" -eq 1 ]]; then
      # PRIMARY_PANE=$(tmux list-panes -F "#{pane_title},#{pane_id}" | grep -v "^$TERMINAL_PANE_NAME," | cut -d',' -f2)
      # if [[ "$CURRENT_PANE" != "$PRIMARY_PANE" ]]; then
      #   echo "$CURRENT_PANE" > "$STATE_FILE"
      #   tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$PRIMARY_PANE"
      #   tmux resize-pane -Z -t "$PRIMARY_PANE"
      # else
      #   # DONE: in this current pane == primary pane branch, consider if we want the trigger
      #   # to first detect if the primary pane is zoomed, and if it is not we could zoom it
      #   # to hide the toggle term
      #   if [[ -f "$STATE_FILE" ]]; then
      #     LAST_PANE=$(cat "$STATE_FILE")
      #     if [[ "$LAST_PANE" == "$CURRENT_PANE" ]]; then
      #       tmux select-pane -t :.+
      #     elif tmux list-panes -F "#{pane_id}" | grep -q "$LAST_PANE"; then
      #       tmux select-pane -t "$LAST_PANE"
      #     else
      #       tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
      #       tmux select-pane -t :.+
      #     fi
      #   else
      #     tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
      #     tmux select-pane -t :.+
      #   fi
      # fi
      PRIMARY_PANE=$(tmux list-panes -F "#{pane_title},#{pane_id}" | grep -v "^$TERMINAL_PANE_NAME," | cut -d',' -f2)
      if [[ "$CURRENT_PANE" != "$PRIMARY_PANE" ]]; then
        echo "$CURRENT_PANE" > "$STATE_FILE"
        tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$PRIMARY_PANE"
        tmux resize-pane -Z -t "$PRIMARY_PANE"
      else
        IS_ZOOMED=$(tmux display-message -p "#{window_zoomed_flag}")
        if [[ "$IS_ZOOMED" -eq 0 ]]; then
          tmux resize-pane -Z -t "$CURRENT_PANE"
        else
          if [[ -f "$STATE_FILE" ]]; then
            LAST_PANE=$(cat "$STATE_FILE")
            if [[ "$LAST_PANE" == "$CURRENT_PANE" ]]; then
              tmux select-pane -t :.+
            elif tmux list-panes -F "#{pane_id}" | grep -q "$LAST_PANE"; then
              tmux select-pane -t "$LAST_PANE"
            else
              tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
              tmux select-pane -t :.+
            fi
          else
            tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
            tmux select-pane -t :.+
          fi
        fi
      fi
    elif [[ "$NON_TOGGLETERM_COUNT" -gt 1 ]]; then
      PRIMARY_PANES=$(tmux list-panes -F "#{pane_title},#{pane_id}" | grep "^$PRIMARY_PANE_NAME,")
      PRIMARY_PANE_COUNT=$(echo "$PRIMARY_PANES" | wc -l)

      if [[ "$PRIMARY_PANE_COUNT" -ge 1 ]]; then
        if [[ "$PRIMARY_PANE_COUNT" -gt 1 ]]; then
          tmux display-message "Multiple primary panes detected, using the first one."
        fi
        PRIMARY_PANE=$(echo "$PRIMARY_PANES" | head -n 1 | cut -d',' -f2)
        tmux list-panes -F "#{pane_id}" | while read -r pane_id; do
          if [[ "$pane_id" != "$PRIMARY_PANE" ]]; then
            tmux select-pane -T "$TERMINAL_PANE_NAME" -t "$pane_id"
          fi
        done
        echo "$CURRENT_PANE" > "$STATE_FILE"
        tmux resize-pane -Z -t "$PRIMARY_PANE"
      else
        tmux list-panes -F "#{pane_id}" | while read -r pane_id; do
          if [[ "$pane_id" != "$CURRENT_PANE" ]]; then
            tmux select-pane -T "$TERMINAL_PANE_NAME" -t "$pane_id"
          fi
        done
        tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
        tmux resize-pane -Z -t "$CURRENT_PANE"
      fi
    elif [[ "$NON_TOGGLETERM_COUNT" -eq 0 ]]; then
      tmux select-pane -T "$PRIMARY_PANE_NAME" -t "$CURRENT_PANE"
      tmux resize-pane -Z -t "$CURRENT_PANE"
    fi
  fi
fi
