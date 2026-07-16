#!/usr/bin/env bash

set -Eeuo pipefail

# =============================================================================
# Hyprland theme menu
# =============================================================================
#
# Desktop-specific frontend. Noctalia renders the menus; the UI-independent
# Ghostty backend performs all shader selection, GPU-profile injection, state
# persistence, and Ghostty reloads.
#
# Default backend path:
#   ~/.config/ghostty/ghostty-shaders.sh
#
# Override it with:
#   GHOSTTY_SHADER_SCRIPT=/path/to/ghostty-shaders.sh hypr-theme-menu.sh
#
# =============================================================================

GHOSTTY_SHADER_SCRIPT="${GHOSTTY_SHADER_SCRIPT:-$HOME/.config/ghostty/ghostty-shaders.sh}"
NOCTALIA="${NOCTALIA:-noctalia}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
ZEN_BROWSER_THEME_STATE="${ZEN_BROWSER_THEME_STATE:-$STATE_HOME/hypr/zen-browser-theme}"

main_items=(
  "󰊠 Ghostty"
  "󰙨 Zen Browser"
)

ghostty_items=(
  "󰐕 Separate shaders (cursor / background)"
  "󰒓 Combined shader (replaces both)"
  "󰾆 GPU profile"
)

separate_shader_items=(
  "󰇀 Cursor shader"
  "󰖨 Background shader"
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

choose_with_noctalia() {
  local prompt="$1"

  "$NOCTALIA" dmenu -p "$prompt"
}

choose_menu() {
  local prompt="$1"
  shift

  printf '%s\n' "$@" |
    choose_with_noctalia "$prompt" || true
}

require_frontend() {
  command -v "$NOCTALIA" >/dev/null 2>&1 || fail "Noctalia is required: $NOCTALIA"
  [[ -x "$GHOSTTY_SHADER_SCRIPT" ]] || fail "Ghostty shader backend is not executable: $GHOSTTY_SHADER_SCRIPT"
}

pretty_shader_name() {
  local filename="$1"
  local name="${filename%.glsl}"

  name="${name#cursor_}"
  name="${name//_/ }"
  name="${name//-/ }"

  printf '%s' "$name"
}

profile_display_name() {
  case "$1" in
  eco) printf 'Power saver' ;;
  balanced) printf 'Balanced' ;;
  quality) printf 'Quality' ;;
  ultra) printf 'Ultra' ;;
  *) printf '%s' "$1" ;;
  esac
}

mode_display_name() {
  case "$1" in
  separate) printf 'Separate' ;;
  combined) printf 'Combined' ;;
  none) printf 'Off' ;;
  *) printf '%s' "$1" ;;
  esac
}

run_ghostty_change() {
  local title="$1"
  shift

  local output
  if ! output="$("$GHOSTTY_SHADER_SCRIPT" "$@" 2>&1)"; then
    notify "$title" "$output"
    return 1
  fi

  notify "$title" "$output"
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

choose_ghostty_shader() {
  local kind="$1"
  local icon="$2"
  local current choice selected file label display prompt
  local none_label="󰄬 None — disable only this stage"
  local -a files=()
  local -a items=()
  local -A value_by_label=()

  case "$kind" in
  cursor) prompt="Cursor — enabling disables Combined > " ;;
  background) prompt="Background — enabling disables Combined > " ;;
  combined) prompt="Combined — enabling replaces Cursor + Background > " ;;
  *)
    notify "Ghostty" "Unknown shader kind: $kind"
    return 1
    ;;
  esac

  if ! current="$("$GHOSTTY_SHADER_SCRIPT" current "$kind" 2>&1)"; then
    notify "Ghostty" "$current"
    return 1
  fi

  if ! mapfile -t files < <("$GHOSTTY_SHADER_SCRIPT" list "$kind"); then
    notify "Ghostty" "Could not list $kind shaders"
    return 1
  fi

  label="$none_label"
  [[ "$current" == "none" ]] && label="● $label"
  items+=("$label")
  value_by_label["$label"]="none"

  for file in "${files[@]}"; do
    display="$(pretty_shader_name "$file")"
    label="$icon $display"

    [[ "$current" == "$file" ]] && label="● $label"

    items+=("$label")
    value_by_label["$label"]="$file"
  done

  choice="$(choose_menu "$prompt" "${items[@]}")"
  [[ -z "$choice" ]] && return 0

  selected="${value_by_label[$choice]:-}"
  if [[ -z "$selected" ]]; then
    notify "Ghostty" "Choose one of the listed shader options"
    return 1
  fi

  run_ghostty_change "Ghostty" set "$kind" "$selected"
}

choose_separate_shaders() {
  local choice

  choice="$(
    choose_menu \
      "Separate — enabling a shader disables Combined > " \
      "${separate_shader_items[@]}"
  )"

  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰇀 Cursor shader")
    choose_ghostty_shader cursor "󰇀"
    ;;

  "󰖨 Background shader")
    choose_ghostty_shader background "󰖨"
    ;;

  *)
    notify "Ghostty" "Choose Cursor shader or Background shader"
    return 1
    ;;
  esac
}

choose_gpu_profile() {
  local current choice selected label profile
  local -a profiles=()
  local -a items=()
  local -A value_by_label=()

  if ! current="$("$GHOSTTY_SHADER_SCRIPT" profile 2>&1)"; then
    notify "Ghostty" "$current"
    return 1
  fi

  if ! mapfile -t profiles < <("$GHOSTTY_SHADER_SCRIPT" list profiles); then
    notify "Ghostty" "Could not list GPU profiles"
    return 1
  fi

  for profile in "${profiles[@]}"; do
    case "$profile" in
    eco) label="󰾆 Power saver" ;;
    balanced) label="󰍛 Balanced" ;;
    quality) label="󰓅 Quality" ;;
    ultra) label="󰾅 Ultra" ;;
    *) label="$profile" ;;
    esac

    [[ "$current" == "$profile" ]] && label="● $label"

    items+=("$label")
    value_by_label["$label"]="$profile"
  done

  choice="$(choose_menu "Ghostty GPU profile > " "${items[@]}")"
  [[ -z "$choice" ]] && return 0

  selected="${value_by_label[$choice]:-}"
  if [[ -z "$selected" ]]; then
    notify "Ghostty GPU profile" "Choose one of the listed profiles"
    return 1
  fi

  run_ghostty_change "Ghostty GPU profile" set-profile "$selected"
}

choose_ghostty() {
  local profile mode choice

  if ! profile="$("$GHOSTTY_SHADER_SCRIPT" profile 2>&1)"; then
    notify "Ghostty" "$profile"
    return 1
  fi

  if ! mode="$("$GHOSTTY_SHADER_SCRIPT" mode 2>&1)"; then
    notify "Ghostty" "$mode"
    return 1
  fi

  choice="$(
    choose_menu \
      "Ghostty [$(mode_display_name "$mode") · $(profile_display_name "$profile")] > " \
      "${ghostty_items[@]}"
  )"

  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰐕 Separate shaders (cursor / background)")
    choose_separate_shaders
    ;;

  "󰒓 Combined shader (replaces both)")
    choose_ghostty_shader combined "󰒓"
    ;;

  "󰾆 GPU profile")
    choose_gpu_profile
    ;;

  *)
    notify "Ghostty" "Choose Separate shaders, Combined shader, or GPU profile"
    return 1
    ;;
  esac
}

main() {
  local choice

  require_frontend

  choice="$(choose_menu "Theme Target > " "${main_items[@]}")"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰊠 Ghostty")
    choose_ghostty
    ;;

  "󰙨 Zen Browser")
    choose_zen_browser
    ;;
  esac
}

main "$@"
