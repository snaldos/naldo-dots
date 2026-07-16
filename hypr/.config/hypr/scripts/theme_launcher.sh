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

HYPR_RULES="${HYPR_RULES:-$HOME/.config/hypr/hyprland/rules.lua}"
GHOSTTY_SHADER_SCRIPT="${GHOSTTY_SHADER_SCRIPT:-$HOME/.config/ghostty/ghostty-shaders.sh}"
NOCTALIA="${NOCTALIA:-noctalia}"

main_items=(
  "󰊠 Ghostty"
  "󰙨 Zen Browser"
)

zen_browser_items=(
  "󰞏 Opaque + No Blur"
  "󰹞 Transparent + Blur"
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

set_zen_browser_rule() {
  local opacity="$1"
  local no_blur="$2"

  [[ -f "$HYPR_RULES" ]] || {
    notify "Zen Browser" "Missing Hyprland rules.lua"
    return 1
  }

  command -v perl >/dev/null 2>&1 || {
    notify "Zen Browser" "Perl is required to update rules.lua"
    return 1
  }

  ZEN_OPACITY="$opacity" ZEN_NO_BLUR="$no_blur" perl -0pi -e '
    my $opacity = $ENV{ZEN_OPACITY};
    my $no_blur = $ENV{ZEN_NO_BLUR};

    my $changed = 0;
    $changed += s/local zen_browser_opacity = "[^"]*"/local zen_browser_opacity = "$opacity"/;
    $changed += s/local zen_browser_no_blur = (?:true|false)/local zen_browser_no_blur = $no_blur/;

    exit 2 if $changed != 2;
  ' "$HYPR_RULES" || {
    notify "Zen Browser" "Could not update rules.lua"
    return 1
  }

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
}

choose_zen_browser() {
  local choice

  choice="$(choose_menu "Zen Browser > " "${zen_browser_items[@]}")"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
  "󰞏 Opaque + No Blur")
    set_zen_browser_rule "1 1" "true"
    notify "Zen Browser" "Opacity 1 1, blur disabled"
    ;;

  "󰹞 Transparent + Blur")
    set_zen_browser_rule "0.70 0.70" "false"
    notify "Zen Browser" "Opacity 0.70 0.70, blur enabled"
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
