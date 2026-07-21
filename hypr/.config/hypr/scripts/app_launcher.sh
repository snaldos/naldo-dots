#!/usr/bin/env bash

if (( $# != 3 )); then
  printf 'Usage: %s TERMINAL TERMINAL_FLOAT_APP_ID CENTERED_FLOATING_SIZE\n' "${0##*/}" >&2
  exit 2
fi

LAUNCH_TERMINAL="${LAUNCH_TERMINAL:-$HOME/.local/libexec/naldo/launch-terminal}"
TERMINAL_FLOAT=(
  "$LAUNCH_TERMINAL"
  --terminal "$1"
  --app-id "$2"
)
CENTERED_FLOATING_SIZE="$3"
NOCTALIA="${NOCTALIA:-noctalia}"

command -v "$NOCTALIA" >/dev/null 2>&1 || {
  printf 'Noctalia is required: %s\n' "$NOCTALIA" >&2
  exit 1
}
[[ -x "$LAUNCH_TERMINAL" ]] || {
  printf 'Terminal launcher is required: %s\n' "$LAUNCH_TERMINAL" >&2
  exit 1
}

menu_items=(
  " Terminal"
  "󰙨 Zen Browser"
  " Translator"
  "󰌌 Smassh"
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

"󰌌 Smassh")
  "${TERMINAL_FLOAT[@]}" -- smassh &
  ;;

esac
