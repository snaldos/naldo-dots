#!/usr/bin/env bash

set -Eeuo pipefail

NIRI="${NIRI:-niri}"
JQ="${JQ:-jq}"
TERMINAL="${NALDO_TERMINAL:-ghostty}"
NOTES_EDITOR="${NALDO_NOTES_EDITOR:-nvim}"
NOTES_DIR="${NALDO_NOTES_DIR:-$HOME/Vaults/second-brain}"
NOTES_APP_ID="${NALDO_NOTES_APP_ID:-com.mitchellh.ghostty.notes}"

notify() {
  local message="$1"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Notes workspace" "$message"
  else
    printf 'Notes workspace: %s\n' "$message" >&2
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    notify "Missing command: $1"
    return 1
  }
}

main() {
  local windows_json window_id output

  if (($# != 0)); then
    printf 'Usage: %s\n' "${0##*/}" >&2
    return 2
  fi

  require_command "$NIRI" || return 1
  require_command "$JQ" || return 1
  require_command "$TERMINAL" || return 1
  require_command "$NOTES_EDITOR" || return 1
  [[ -d "$NOTES_DIR" ]] || {
    notify "Notes vault does not exist: $NOTES_DIR"
    return 1
  }

  if ! windows_json="$("$NIRI" msg -j windows 2>&1)"; then
    notify "Could not inspect Niri windows: $windows_json"
    return 1
  fi

  # $app_id is a jq variable, not a shell variable.
  # shellcheck disable=SC2016
  if ! window_id="$(
    printf '%s\n' "$windows_json" |
      "$JQ" -r --arg app_id "$NOTES_APP_ID" \
        'first(.[] | select(.app_id == $app_id) | .id) // empty'
  )"; then
    notify "Could not parse Niri's window list"
    return 1
  fi

  if [[ -n "$window_id" ]]; then
    if ! output="$("$NIRI" msg action focus-window --id "$window_id" 2>&1)"; then
      notify "Could not focus the notes window: $output"
      return 1
    fi
    return 0
  fi

  if ! output="$(
    "$NIRI" msg action spawn -- \
      "$TERMINAL" \
      "--class=$NOTES_APP_ID" \
      "--working-directory=$NOTES_DIR" \
      -e "$NOTES_EDITOR" . 2>&1
  )"; then
    notify "Could not open the notes workspace: $output"
    return 1
  fi
}

main "$@"
