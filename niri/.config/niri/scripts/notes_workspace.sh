#!/usr/bin/env bash

set -Eeuo pipefail

NIRI="${NIRI:-niri}"
JQ="${JQ:-jq}"
TERMINAL="${NALDO_TERMINAL:-ghostty}"
NOTES_EDITOR="${NALDO_NOTES_EDITOR:-nvim}"
NOTES_DIR="${NALDO_NOTES_DIR:-$HOME/Vaults/second-brain}"
NOTES_APP_ID="${NALDO_NOTES_APP_ID:-com.mitchellh.ghostty.notes}"
NOTES_WORKSPACE="${NALDO_NOTES_WORKSPACE:-notes}"

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
  local windows_json workspaces_json window_id workspace_idx empty_idx output

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

  if ! workspaces_json="$("$NIRI" msg -j workspaces 2>&1)"; then
    notify "Could not inspect Niri workspaces: $workspaces_json"
    return 1
  fi

  # $workspace is a jq variable, not a shell variable.
  # shellcheck disable=SC2016
  if ! workspace_idx="$(
    printf '%s\n' "$workspaces_json" |
      "$JQ" -r --arg workspace "$NOTES_WORKSPACE" \
        'first(.[] | select(.name == $workspace) | .idx) // empty'
  )"; then
    notify "Could not parse Niri's workspace list"
    return 1
  fi

  if [[ -n "$workspace_idx" ]]; then
    if ! output="$("$NIRI" msg action focus-workspace "$NOTES_WORKSPACE" 2>&1)"; then
      notify "Could not focus the notes workspace: $output"
      return 1
    fi
  else
    # Name the bottom empty workspace on the focused output. This appends notes
    # without inserting it before or renumbering any existing workspace.
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
    if ! output="$("$NIRI" msg action set-workspace-name "$NOTES_WORKSPACE" 2>&1)"; then
      notify "Could not name the notes workspace: $output"
      return 1
    fi
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
