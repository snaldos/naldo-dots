#!/usr/bin/env bash

set -Eeuo pipefail

NOCTALIA="${NOCTALIA:-noctalia}"
NIRI="${NIRI:-niri}"
JQ="${JQ:-jq}"
LAUNCH_TERMINAL="${LAUNCH_TERMINAL:-$HOME/.local/libexec/naldo/launch-terminal}"
TERMINAL="${NALDO_TERMINAL:-ghostty}"
TERMINAL_FLOAT_APP_ID="${NALDO_TERMINAL_FLOAT_APP_ID:-com.mitchellh.ghostty.float}"

menu_items=(
  " Terminal"
  "󰙨 Zen Browser"
  " Translator"
  "󰌌 Smassh"
)

notify() {
  local title="$1"
  local message="$2"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$message"
  else
    printf '%s: %s\n' "$title" "$message" >&2
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    notify "App launcher" "Missing command: $1"
    return 1
  }
}

spawn_app() {
  local output

  if ! output="$("$NIRI" msg action spawn -- "$@" 2>&1)"; then
    notify "App launcher" "Could not launch ${1##*/}: $output"
    return 1
  fi
}

float_new_zen_window() {
  local id="" candidate
  local -a existing_ids=()
  local -A existed=()

  mapfile -t existing_ids < <("$NIRI" msg -j windows | "$JQ" -r '.[] | select(.app_id == "zen") | .id')
  for candidate in "${existing_ids[@]}"; do
    existed["$candidate"]=1
  done

  spawn_app zen-browser || return 1

  for _ in {1..100}; do
    while IFS= read -r candidate; do
      if [[ -n "$candidate" && -z "${existed[$candidate]:-}" ]]; then
        id="$candidate"
        break 2
      fi
    done < <("$NIRI" msg -j windows | "$JQ" -r '.[] | select(.app_id == "zen") | .id')
    sleep 0.05
  done

  if [[ -z "$id" ]]; then
    id="$(
      "$NIRI" msg -j windows |
        "$JQ" -r '.[] | select(.app_id == "zen" and .is_focused == true) | .id' |
        head -n 1
    )"
  fi

  if [[ -z "$id" ]]; then
    notify "Zen Browser" "Opened Zen, but could not identify its window for floating"
    return 0
  fi

  "$NIRI" msg action move-window-to-floating --id "$id" >/dev/null
  "$NIRI" msg action set-window-width --id "$id" "1200" >/dev/null
  "$NIRI" msg action set-window-height --id "$id" "900" >/dev/null
  "$NIRI" msg action center-window --id "$id" >/dev/null
}

main() {
  local choice

  if (($# != 0)); then
    printf 'Usage: %s\n' "${0##*/}" >&2
    return 2
  fi

  require_command "$NOCTALIA" || return 1
  require_command "$NIRI" || return 1
  require_command "$JQ" || return 1
  [[ -x "$LAUNCH_TERMINAL" ]] || {
    notify "App launcher" "Missing executable: $LAUNCH_TERMINAL"
    return 1
  }

  choice="$(
    printf '%s\n' "${menu_items[@]}" |
      "$NOCTALIA" dmenu -p "Apps > " || true
  )"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  " Terminal")
    spawn_app "$LAUNCH_TERMINAL" --terminal "$TERMINAL" --app-id "$TERMINAL_FLOAT_APP_ID" --
    ;;

  "󰙨 Zen Browser")
    require_command zen-browser && float_new_zen_window
    ;;

  " Translator")
    require_command rlwrap && require_command trans &&
      spawn_app "$LAUNCH_TERMINAL" --terminal "$TERMINAL" --app-id "$TERMINAL_FLOAT_APP_ID" -- rlwrap trans
    ;;

  "󰌌 Smassh")
    require_command smassh &&
      spawn_app "$LAUNCH_TERMINAL" --terminal "$TERMINAL" --app-id "$TERMINAL_FLOAT_APP_ID" -- smassh
    ;;
  esac
}

main "$@"
