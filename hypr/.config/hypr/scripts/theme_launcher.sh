#!/usr/bin/env bash

set -Eeuo pipefail

# Hyprland-specific theme targets. Ghostty's menu is shared with Niri; Zen's
# compositor opacity remains a Hyprland-specific state and reload.
GHOSTTY_THEME_MENU="${GHOSTTY_THEME_MENU:-$HOME/.config/ghostty/ghostty-theme-menu.sh}"
NOCTALIA="${NOCTALIA:-noctalia}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
ZEN_BROWSER_THEME_STATE="${ZEN_BROWSER_THEME_STATE:-$STATE_HOME/hypr/zen-browser-theme}"

main_items=(
  "󰊠 Ghostty"
  "󰙨 Zen Browser"
)

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

notify() {
  local title="$1"
  local message="$2"

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
    "$NOCTALIA" dmenu -p "$prompt" || true
}

get_zen_browser_theme() {
  local mode="opaque"

  if [[ -r "$ZEN_BROWSER_THEME_STATE" ]]; then
    IFS= read -r mode <"$ZEN_BROWSER_THEME_STATE" || mode="opaque"
  fi

  case "$mode" in
  opaque|transparent) printf '%s\n' "$mode" ;;
  *) printf 'opaque\n' ;;
  esac
}

set_zen_browser_theme() {
  local mode="$1"
  local state_dir temporary reload_output

  case "$mode" in
  opaque|transparent) ;;
  *)
    notify "Zen Browser" "Unknown theme mode: $mode"
    return 1
    ;;
  esac

  command -v hyprctl >/dev/null 2>&1 || {
    notify "Zen Browser" "hyprctl is required"
    return 1
  }
  [[ ! -L "$ZEN_BROWSER_THEME_STATE" ]] || {
    notify "Zen Browser" "Theme state must be a machine-local file"
    return 1
  }

  state_dir="$(dirname -- "$ZEN_BROWSER_THEME_STATE")"
  if ! install -d -m 700 "$state_dir"; then
    notify "Zen Browser" "Could not create theme state directory"
    return 1
  fi

  if ! temporary="$(mktemp --tmpdir="$state_dir" '.zen-browser-theme.XXXXXX')"; then
    notify "Zen Browser" "Could not create temporary theme state"
    return 1
  fi

  if ! printf '%s\n' "$mode" >"$temporary" ||
    ! chmod 600 "$temporary" ||
    ! mv -f -- "$temporary" "$ZEN_BROWSER_THEME_STATE"; then
    rm -f -- "$temporary"
    notify "Zen Browser" "Could not save theme state"
    return 1
  fi

  if ! reload_output="$(hyprctl reload config-only 2>&1)"; then
    notify "Zen Browser" "Theme saved, but Hyprland reload failed: $reload_output"
    return 1
  fi
}

choose_zen_browser() {
  local mode choice
  local opaque_label="󰞏 Opaque + No Blur"
  local transparent_label="󰹞 Transparent + Blur"

  mode="$(get_zen_browser_theme)"
  if [[ "$mode" == "opaque" ]]; then
    opaque_label="● $opaque_label"
  else
    transparent_label="● $transparent_label"
  fi

  choice="$(choose_menu "Zen Browser > " "$opaque_label" "$transparent_label")"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "$opaque_label")
    set_zen_browser_theme opaque
    notify "Zen Browser" "Opaque, blur disabled"
    ;;

  "$transparent_label")
    set_zen_browser_theme transparent
    notify "Zen Browser" "Opacity 0.70, blur enabled"
    ;;
  esac
}

main() {
  local choice

  if (($# != 0)); then
    printf 'Usage: %s\n' "${0##*/}" >&2
    return 2
  fi

  command -v "$NOCTALIA" >/dev/null 2>&1 || fail "Noctalia is required: $NOCTALIA"
  [[ -x "$GHOSTTY_THEME_MENU" ]] || fail "Ghostty theme menu is not executable: $GHOSTTY_THEME_MENU"

  choice="$(choose_menu "Theme Target > " "${main_items[@]}")"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰊠 Ghostty") "$GHOSTTY_THEME_MENU" ;;
  "󰙨 Zen Browser") choose_zen_browser ;;
  esac
}

main "$@"
