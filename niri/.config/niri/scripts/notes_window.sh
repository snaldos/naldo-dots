#!/usr/bin/env bash

set -Eeuo pipefail

NIRI="${NIRI:-niri}"
JQ="${JQ:-jq}"
TERMINAL="${NALDO_TERMINAL:-ghostty}"
HERDR="${NALDO_HERDR:-herdr}"
NOTES_DIR="${NALDO_NOTES_DIR:-$HOME/Vaults/state-space}"
NOTES_APP_ID="${NALDO_NOTES_APP_ID:-com.mitchellh.ghostty.notes}"
NOTES_SESSION="${NALDO_NOTES_SESSION:-notes}"

notify() {
  local message="$1"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Notes window" "$message"
  else
    printf 'Notes window: %s\n' "$message" >&2
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    notify "Missing command: $1"
    return 1
  }
}

notes_window_id_from_json() {
  local windows_json="$1"

  # $app_id is a jq variable, not a shell variable.
  # shellcheck disable=SC2016
  printf '%s\n' "$windows_json" |
    "$JQ" -r --arg app_id "$NOTES_APP_ID" \
      'first(.[] | select(.app_id == $app_id) | .id) // empty'
}

focused_notes_window_id_from_json() {
  local windows_json="$1"

  # $app_id is a jq variable, not a shell variable.
  # shellcheck disable=SC2016
  printf '%s\n' "$windows_json" |
    "$JQ" -r --arg app_id "$NOTES_APP_ID" \
      'first(.[] | select(.app_id == $app_id and .is_focused) | .id) // empty'
}

center_notes_window() {
  local window_id="$1" output

  if ! output="$("$NIRI" msg action center-window --id "$window_id" 2>&1)"; then
    notify "Could not center the notes window: $output"
    return 1
  fi
}

main() {
  local windows_json workspaces_json window_id focused_window_id empty_idx output attempt

  if (($# != 0)); then
    printf 'Usage: %s\n' "${0##*/}" >&2
    return 2
  fi

  require_command "$NIRI" || return 1
  require_command "$JQ" || return 1
  require_command "$TERMINAL" || return 1
  require_command "$HERDR" || return 1
  [[ -d "$NOTES_DIR" ]] || {
    notify "Notes vault does not exist: $NOTES_DIR"
    return 1
  }

  if ! windows_json="$("$NIRI" msg -j windows 2>&1)"; then
    notify "Could not inspect Niri windows: $windows_json"
    return 1
  fi

  if ! window_id="$(notes_window_id_from_json "$windows_json")"; then
    notify "Could not parse Niri's window list"
    return 1
  fi
  if ! focused_window_id="$(focused_notes_window_id_from_json "$windows_json")"; then
    notify "Could not parse Niri's focused window"
    return 1
  fi

  if [[ -n "$focused_window_id" ]]; then
    if ! output="$("$NIRI" msg action focus-workspace-previous 2>&1)"; then
      notify "Could not return to the previous workspace: $output"
      return 1
    fi
    return
  fi

  if [[ -n "$window_id" ]]; then
    if ! output="$("$NIRI" msg action focus-window --id "$window_id" 2>&1)"; then
      notify "Could not focus the notes window: $output"
      return 1
    fi
    center_notes_window "$window_id"
    return
  fi

  if ! workspaces_json="$("$NIRI" msg -j workspaces 2>&1)"; then
    notify "Could not inspect Niri workspaces: $workspaces_json"
    return 1
  fi

  # For initial placement only, focus the bottom empty dynamic workspace on the
  # current output. Later invocations find the movable window by its app ID.
  # $output is a jq variable, not a shell variable.
  # shellcheck disable=SC2016
  if ! empty_idx="$(
    printf '%s\n' "$workspaces_json" |
      "$JQ" -r '
        (first(.[] | select(.is_focused) | .output)) as $output
        | [.[] | select(.output == $output and .active_window_id == null)]
        | (max_by(.idx).idx // empty)
      '
  )"; then
    notify "Could not find Niri's bottom empty workspace"
    return 1
  fi
  [[ -n "$empty_idx" ]] || {
    notify "Niri has no empty workspace on the focused output"
    return 1
  }

  if ! output="$("$NIRI" msg action focus-workspace "$empty_idx" 2>&1)"; then
    notify "Could not focus empty workspace $empty_idx: $output"
    return 1
  fi

  # Starting Ghostty in the vault makes it the initial CWD when Herdr creates
  # the named session. If the session already exists, Herdr reattaches without
  # resetting its persisted panes. Ghostty closes when this Herdr client exits.
  if ! output="$(
    "$NIRI" msg action spawn -- \
      "$TERMINAL" \
      "--class=$NOTES_APP_ID" \
      "--working-directory=$NOTES_DIR" \
      -e "$HERDR" --session "$NOTES_SESSION" 2>&1
  )"; then
    notify "Could not open the notes window: $output"
    return 1
  fi

  # Spawning returns before Ghostty maps its window. Wait briefly, then center
  # the new tiled column once Niri exposes its window ID.
  for ((attempt = 0; attempt < 50; attempt++)); do
    if windows_json="$("$NIRI" msg -j windows 2>/dev/null)" &&
      window_id="$(notes_window_id_from_json "$windows_json")" &&
      [[ -n "$window_id" ]]; then
      center_notes_window "$window_id"
      return
    fi
    sleep 0.1
  done

  notify "Opened notes, but its window did not appear in time to center it"
  return 1
}

main "$@"
