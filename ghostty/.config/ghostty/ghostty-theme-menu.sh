#!/usr/bin/env bash

set -Eeuo pipefail

# Compositor-independent Noctalia frontend for the Ghostty shader backend.
GHOSTTY_SHADER_SCRIPT="${GHOSTTY_SHADER_SCRIPT:-$HOME/.config/ghostty/ghostty-shaders.sh}"
NOCTALIA="${NOCTALIA:-noctalia}"

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

choose_menu() {
  local prompt="$1"
  shift

  printf '%s\n' "$@" |
    "$NOCTALIA" dmenu -p "$prompt" || true
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
  if (($# != 0)); then
    printf 'Usage: %s\n' "${0##*/}" >&2
    return 2
  fi

  command -v "$NOCTALIA" >/dev/null 2>&1 || fail "Noctalia is required: $NOCTALIA"
  [[ -x "$GHOSTTY_SHADER_SCRIPT" ]] || fail "Ghostty shader backend is not executable: $GHOSTTY_SHADER_SCRIPT"

  choose_ghostty
}

main "$@"
