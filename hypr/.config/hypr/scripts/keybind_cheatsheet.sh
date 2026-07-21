#!/usr/bin/env bash

set -Eeuo pipefail

if (( $# != 1 )); then
  printf 'Usage: %s NOCTALIA\n' "${0##*/}" >&2
  exit 2
fi

NOCTALIA="$1"

for dependency in "$NOCTALIA" hyprctl sort; do
  command -v "$dependency" >/dev/null 2>&1 || {
    printf '%s is required\n' "$dependency" >&2
    exit 1
  }
done

if ! binds="$(hyprctl binds 2>&1)"; then
  printf 'Could not query Hyprland keybinds: %s\n' "$binds" >&2
  exit 1
fi

format_binds() {
  local line mask=0 key="" description combo
  local -a parts=()

  while IFS= read -r line; do
    case "$line" in
      bind*)
        mask=0
        key=""
        ;;
      $'\tmodmask: '*)
        mask="${line#*: }"
        ;;
      $'\tkey: '*)
        key="${line#*: }"
        ;;
      $'\tdescription: '*)
        description="${line#*: }"
        [[ -n "$description" && -n "$key" && "$mask" =~ ^[0-9]+$ ]] || continue

        parts=()
        if (( mask & 64 )); then parts+=("SUPER"); fi
        if (( mask & 4 )); then parts+=("CTRL"); fi
        if (( mask & 8 )); then parts+=("ALT"); fi
        if (( mask & 1 )); then parts+=("SHIFT"); fi
        if (( mask & 2 )); then parts+=("CAPS"); fi
        if (( mask & 16 )); then parts+=("MOD2"); fi
        if (( mask & 32 )); then parts+=("MOD3"); fi
        if (( mask & 128 )); then parts+=("MOD5"); fi
        parts+=("$key")

        printf -v combo ' + %s' "${parts[@]}"
        combo="${combo# + }"
        printf '%-32s %s\n' "$combo" "$description"
        ;;
    esac
  done <<< "$binds"
}

format_binds | sort -fu | "$NOCTALIA" dmenu -p "Hyprland keybinds > " >/dev/null || exit 0
