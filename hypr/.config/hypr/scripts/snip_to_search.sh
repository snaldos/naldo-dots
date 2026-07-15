#!/usr/bin/env bash
set -euo pipefail

if (( $# != 2 )); then
  printf 'Usage: %s NOCTALIA NOCTALIA_IPC_SUBCOMMAND\n' "${0##*/}" >&2
  exit 2
fi

NOCTALIA_IPC=("$1" "$2")

old_hash=""

if wl-paste --list-types 2>/dev/null | grep -q '^image/png$'; then
  old_hash="$(
    wl-paste --type image/png 2>/dev/null |
      sha256sum |
      cut -d' ' -f1
  )"
fi

"${NOCTALIA_IPC[@]}" screenshot-region

new_hash=""

for _ in {1..400}; do
  if wl-paste --list-types 2>/dev/null | grep -q '^image/png$'; then
    new_hash="$(
      wl-paste --type image/png 2>/dev/null |
        sha256sum |
        cut -d' ' -f1
    )"

    if [[ -n "$new_hash" && "$new_hash" != "$old_hash" ]]; then
      break
    fi
  fi

  sleep 0.05
done

if [[ -z "$new_hash" || "$new_hash" == "$old_hash" ]]; then
  notify-send "Lens upload failed" "No new image found in clipboard"
  exit 1
fi

IMG="$(mktemp --suffix=.png)"
trap 'rm -f "$IMG"' EXIT

wl-paste --type image/png >"$IMG"

response="$(
  curl -sS \
    -F "files[]=@${IMG};filename=screenshot.png;type=image/png" \
    "https://uguu.se/upload"
)"

imageLink="$(printf '%s' "$response" | jq -r '.files[0].url // empty')"

if [[ -z "$imageLink" ]]; then
  notify-send "Lens upload failed" "$response"
  exit 1
fi

xdg-open "https://lens.google.com/uploadbyurl?url=${imageLink}"
