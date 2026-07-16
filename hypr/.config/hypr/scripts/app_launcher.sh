#!/usr/bin/env bash

if (( $# != 3 )); then
  printf 'Usage: %s TERMINAL TERMINAL_FLOAT_APP_ID CENTERED_FLOATING_SIZE\n' "${0##*/}" >&2
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TERMINAL_FLOAT=(
  "$SCRIPT_DIR/launch_terminal.sh"
  --terminal "$1"
  --app-id "$2"
)
CENTERED_FLOATING_SIZE="$3"
NOCTALIA="${NOCTALIA:-noctalia}"

command -v "$NOCTALIA" >/dev/null 2>&1 || {
  printf 'Noctalia is required: %s\n' "$NOCTALIA" >&2
  exit 1
}

menu_items=(
  " Terminal"
  "󰙨 Zen Browser"
  " Translator"
)

choice=$(
  printf '%s\n' "${menu_items[@]}" |
    "$NOCTALIA" dmenu -p "Apps > "
) || exit 0

[[ -z "$choice" ]] && exit 0

case "$choice" in
" Terminal")
  "${TERMINAL_FLOAT[@]}" -- &
  ;;

"󰙨 Zen Browser")
  hyprctl eval "if zr then zr:set_enabled(false) end; zr = hl.window_rule({name=\"zen-float\",match={class=\"^(zen)$\"},float=true,size=\"$CENTERED_FLOATING_SIZE\",center=true})"
  zen-browser &
  (
    sleep 2
    hyprctl eval 'if zr then zr:set_enabled(false) end'
  ) &
  ;;

" Translator")
  "${TERMINAL_FLOAT[@]}" -- rlwrap trans &
  ;;

esac
