#!/usr/bin/env bash

set -Eeuo pipefail

if (($# != 2)); then
  printf 'Usage: %s TERMINAL TERMINAL_FLOAT_APP_ID\n' "${0##*/}" >&2
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TERMINAL_FLOAT=(
  "$SCRIPT_DIR/launch_terminal.sh"
  --terminal "$1"
  --app-id "$2"
)
SYNC_CONTROL="${SYNC_CONTROL:-$HOME/.local/bin/sync-control}"
SYNC_ALL="${SYNC_ALL:-$HOME/.local/bin/sync-all}"
SYSTEM_SYNC="${SYSTEM_SYNC:-$HOME/backups-desktop/sync.sh}"

notify() {
  local title="$1" message="$2"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$message"
  else
    printf '%s: %s\n' "$title" "$message" >&2
  fi
}

choose_menu() {
  local prompt="$1"
  shift

  printf '%s\n' "$@" |
    fuzzel --dmenu --prompt="$prompt" --lines="$#" --width=52 || true
}

run_terminal() {
  "${TERMINAL_FLOAT[@]}" --hold -- "$@" &
}

run_shell() {
  "${TERMINAL_FLOAT[@]}" --hold -- bash -lc "$1" &
}

run_control() {
  local output

  if ! output="$("$SYNC_CONTROL" "$@" 2>&1)"; then
    notify "Synchronization" "$output"
    return 1
  fi

  [[ -z "$output" ]] || printf '%s\n' "$output"
}

sync_status_value() {
  local key="$1"

  "$SYNC_CONTROL" status 2>/dev/null |
    awk -F: -v key="$key" '$1 ~ key { sub(/^[[:space:]]+/, "", $2); print $2; exit }'
}

choose_interval() {
  local current choice interval label
  local -a values=(5min 15min 30min 1h 3h 6h 12h 1d)
  local -a items=()
  local -A value_by_label=()

  current="$(sync_status_value interval)"
  for interval in "${values[@]}"; do
    label="󰔛 Every $interval"
    [[ "$interval" == "$current" ]] && label="● $label"
    items+=("$label")
    value_by_label["$label"]="$interval"
  done
  items+=("󰅐 Custom interval…")

  choice="$(choose_menu "Sync interval [$current] > " "${items[@]}")"
  [[ -z "$choice" ]] && return 0

  if [[ "$choice" == "󰅐 Custom interval…" ]]; then
    interval="$(fuzzel --dmenu --prompt-only='Interval (e.g. 45min, 6h) > ' --width=42 || true)"
    [[ -z "$interval" ]] && return 0
  else
    interval="${value_by_label[$choice]:-}"
  fi

  [[ -n "$interval" ]] || return 1
  run_control interval "$interval"
}

choose_single_sync() {
  local choice
  local -a items=(
    "󰁯 Machine snapshot"
    "󰋹 Dotfiles"
    "󰠮 Notes"
    "󰉏 Wallpapers"
  )

  choice="$(choose_menu 'Sync one repository > ' "${items[@]}")"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰁯 Machine snapshot") run_terminal "$SYNC_ALL" system ;;
  "󰋹 Dotfiles") run_terminal "$SYNC_ALL" dotfiles ;;
  "󰠮 Notes") run_terminal "$SYNC_ALL" notes ;;
  "󰉏 Wallpapers") run_terminal "$SYNC_ALL" wallpapers ;;
  esac
}

choose_sync() {
  local timer_state startup_state interval choice toggle_label startup_label
  local -a items

  timer_state="$(sync_status_value timer)"
  startup_state="$(sync_status_value startup)"
  interval="$(sync_status_value interval)"

  if [[ "$timer_state" == "active" ]]; then
    toggle_label="󰏤 Pause timer for this session"
  else
    toggle_label="󰐊 Resume timer for this session"
  fi

  if [[ "$startup_state" == "enabled" ]]; then
    startup_label="󰅖 Disable timer at login"
  else
    startup_label="󰐕 Enable timer at login"
  fi

  items=(
    "󰑐 Sync everything now"
    "󰓦 Sync one repository"
    "󰌾 Refresh machine snapshot with sudo"
    "$toggle_label"
    "$startup_label"
    "󰔛 Change interval [$interval]"
    "󰋼 Show status"
    "󰆍 Show recent logs"
  )

  choice="$(choose_menu "Sync [$timer_state · $startup_state · $interval] > " "${items[@]}")"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰑐 Sync everything now") run_control run ;;
  "󰓦 Sync one repository") choose_single_sync ;;
  "󰌾 Refresh machine snapshot with sudo") run_terminal "$SYSTEM_SYNC" --sudo ;;
  "󰏤 Pause timer for this session") run_control pause ;;
  "󰐊 Resume timer for this session") run_control resume ;;
  "󰅖 Disable timer at login") run_control disable ;;
  "󰐕 Enable timer at login") run_control enable ;;
  "󰔛 Change interval"*) choose_interval ;;
  "󰋼 Show status") run_terminal "$SYNC_CONTROL" status ;;
  "󰆍 Show recent logs") run_terminal "$SYNC_CONTROL" logs ;;
  esac
}

export_noctalia() {
  run_shell '
    set -Eeuo pipefail

    config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia"
    saved_export="$config_dir/full-config-export.toml.tmp"
    temporary="$(mktemp --tmpdir noctalia-config.XXXXXX.toml)"
    trap '\''rm -f "$temporary"'\'' EXIT

    echo "Exporting and validating the complete Noctalia config..."
    noctalia config export full >"$temporary"
    noctalia config validate "$temporary"
    mv -f "$temporary" "$saved_export"
    trap - EXIT

    echo
    echo "Saved temporary export to:"
    echo "$saved_export"
  '
}

choose_system() {
  local choice
  local -a items=(
    "󰚰 Update packages"
    "󰒗 Refresh mirrors, then update"
  )

  choice="$(choose_menu 'System maintenance > ' "${items[@]}")"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰚰 Update packages")
    run_terminal paru -Syu
    ;;
  "󰒗 Refresh mirrors, then update")
    run_shell '
      set -Eeuo pipefail
      echo "Refreshing Arch mirror list..."
      sudo reflector \
        --latest 20 \
        --protocol https \
        --sort rate \
        --connection-timeout 10 \
        --save /etc/pacman.d/mirrorlist
      echo
      echo "Updating packages..."
      paru -Syu
    '
    ;;
  esac
}

main() {
  local choice
  local -a items=(
    "󰒋 Synchronization & backup"
    "󰏖 System maintenance"
    "🌙 Export Noctalia config"
  )

  command -v fuzzel >/dev/null 2>&1 || {
    printf 'fuzzel is required\n' >&2
    return 1
  }
  [[ -x "$SYNC_CONTROL" ]] || {
    notify "Scripts" "Missing executable: $SYNC_CONTROL"
    return 1
  }

  choice="$(choose_menu 'Scripts > ' "${items[@]}")"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰒋 Synchronization & backup") choose_sync ;;
  "󰏖 System maintenance") choose_system ;;
  "🌙 Export Noctalia config") export_noctalia ;;
  esac
}

main "$@"
