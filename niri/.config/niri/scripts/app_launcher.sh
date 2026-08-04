#!/usr/bin/env bash

set -Eeuo pipefail

NOCTALIA="${NOCTALIA:-noctalia}"
NIRI="${NIRI:-niri}"
LAUNCH_TERMINAL="${LAUNCH_TERMINAL:-$HOME/.local/libexec/naldo/launch-terminal}"
ZEN_FLATPAK_ID="app.zen_browser.zen"
ZEN_APP_ID="app.zen_browser.zen"
ZEN_FLOAT_WIDTH=1080
ZEN_FLOAT_HEIGHT=920
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

niri_action() {
  local output

  if ! output="$("$NIRI" msg action "$@" 2>&1)"; then
    notify "Zen Browser" "Could not configure launcher window: $output"
    return 1
  fi
}

launch_floating_zen() {
  local before_id focused new_window_id="" attempt

  require_command jq || return 1
  focused="$("$NIRI" msg -j focused-window)" || return 1
  before_id="$(jq -r '.id // empty' <<<"$focused")"
  spawn_app flatpak run "$ZEN_FLATPAK_ID" --new-window about:newtab || return 1

  for ((attempt = 0; attempt < 100; attempt += 1)); do
    focused="$("$NIRI" msg -j focused-window)" || return 1
    new_window_id="$(jq -r --arg app_id "$ZEN_APP_ID" \
      'select(.app_id == $app_id) | .id' <<<"$focused")"
    [[ -n "$new_window_id" && "$new_window_id" != "$before_id" ]] && break
    new_window_id=""
    sleep 0.1
  done

  [[ -n "$new_window_id" ]] || {
    notify "Zen Browser" "Timed out waiting for the launcher window"
    return 1
  }
  niri_action move-window-to-floating --id "$new_window_id" &&
    niri_action set-window-width --id "$new_window_id" "$ZEN_FLOAT_WIDTH" &&
    niri_action set-window-height --id "$new_window_id" "$ZEN_FLOAT_HEIGHT" &&
    niri_action center-window --id "$new_window_id"
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
    launch_floating_zen
    ;;
  esac
}

main "$@"
