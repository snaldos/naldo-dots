#!/usr/bin/env bash

set -Eeuo pipefail

NIRI="${NIRI:-niri}"
JQ="${JQ:-jq}"
NOTES_APP_ID="${NALDO_NOTES_APP_ID:-com.mitchellh.ghostty.notes}"

main() {
  local output focused_json window_id app_id

  if (($# != 0)); then
    printf 'Usage: %s\n' "${0##*/}" >&2
    return 2
  fi

  command -v "$NIRI" >/dev/null 2>&1 || {
    printf 'Missing command: %s\n' "$NIRI" >&2
    return 1
  }
  command -v "$JQ" >/dev/null 2>&1 || {
    printf 'Missing command: %s\n' "$JQ" >&2
    return 1
  }

  if ! output="$("$NIRI" msg action maximize-column 2>&1)"; then
    printf 'Could not toggle the maximized column: %s\n' "$output" >&2
    return 1
  fi

  if ! focused_json="$("$NIRI" msg -j focused-window 2>&1)"; then
    printf 'Could not inspect the focused window: %s\n' "$focused_json" >&2
    return 1
  fi
  if ! window_id="$(printf '%s\n' "$focused_json" | "$JQ" -r '.id // empty')" ||
    ! app_id="$(printf '%s\n' "$focused_json" | "$JQ" -r '.app_id // empty')"; then
    printf "Could not parse Niri's focused window\n" >&2
    return 1
  fi

  [[ "$app_id" == "$NOTES_APP_ID" && -n "$window_id" ]] || return 0

  if ! output="$("$NIRI" msg action center-window --id "$window_id" 2>&1)"; then
    printf 'Could not recenter the notes window: %s\n' "$output" >&2
    return 1
  fi
}

main "$@"
