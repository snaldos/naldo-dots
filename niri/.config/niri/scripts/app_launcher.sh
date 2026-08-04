#!/usr/bin/env bash

set -Eeuo pipefail

NOCTALIA="${NOCTALIA:-noctalia}"
NIRI="${NIRI:-niri}"
LAUNCH_TERMINAL="${LAUNCH_TERMINAL:-$HOME/.local/libexec/naldo/launch-terminal}"
ZEN_FLATPAK_ID="app.zen_browser.zen"
TERMINAL="${NALDO_TERMINAL:-ghostty}"
TERMINAL_FLOAT_APP_ID="${NALDO_TERMINAL_FLOAT_APP_ID:-com.mitchellh.ghostty.float}"

menu_items=(
  " Terminal"
  "󰙨 Zen Browser"
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

main() {
  local choice

  if (($# != 0)); then
    printf 'Usage: %s\n' "${0##*/}" >&2
    return 2
  fi

  require_command "$NOCTALIA" || return 1
  require_command "$NIRI" || return 1
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
    require_command flatpak || return 1
    flatpak info "$ZEN_FLATPAK_ID" >/dev/null 2>&1 || {
      notify "Zen Browser" "Missing required Flatpak: $ZEN_FLATPAK_ID"
      return 1
    }
    spawn_app flatpak run "$ZEN_FLATPAK_ID"
    ;;
  esac
}

main "$@"
