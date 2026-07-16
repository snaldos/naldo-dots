#!/usr/bin/env bash

set -Eeuo pipefail

if (($# != 2)); then
  printf 'Usage: %s NOCTALIA NOCTALIA_IPC_SUBCOMMAND\n' "${0##*/}" >&2
  exit 2
fi

NOCTALIA="$1"
NOCTALIA_IPC_SUBCOMMAND="$2"

notify() {
  local title="$1" message="$2"

  if command -v "$NOCTALIA" >/dev/null 2>&1 &&
    "$NOCTALIA" "$NOCTALIA_IPC_SUBCOMMAND" notification-show "$title" "$message" >/dev/null 2>&1; then
    return
  fi

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$message"
  else
    printf '%s: %s\n' "$title" "$message" >&2
  fi
}

fail() {
  notify "Layout selector" "$*"
  exit 1
}

for dependency in fuzzel hyprctl jq; do
  command -v "$dependency" >/dev/null 2>&1 || fail "$dependency is required"
done

if ! workspace_json="$(hyprctl -j activeworkspace 2>&1)"; then
  fail "Could not query the active workspace: $workspace_json"
fi

if ! workspace_name="$(jq -er '.name | select(type == "string" and length > 0)' <<<"$workspace_json")"; then
  fail "Hyprland returned an invalid active workspace"
fi

if ! current_layout="$(jq -er '.tiledLayout | select(type == "string" and length > 0)' <<<"$workspace_json")"; then
  fail "Hyprland returned an invalid tiled layout"
fi

if [[ "$workspace_name" == special:* ]]; then
  notify "Layout selector" "Special workspaces keep their configured layout"
  exit 0
fi

layouts=(dwindle scrolling)
declare -A display_by_layout=(
  [dwindle]="Dwindle"
  [scrolling]="Scrolling"
)
declare -A layout_by_item=()
items=()
current_item=""

for name in "${layouts[@]}"; do
  item="${display_by_layout[$name]}"
  if [[ "$name" == "$current_layout" ]]; then
    item="● $item"
    current_item="$item"
  fi

  items+=("$item")
  layout_by_item["$item"]="$name"
done

fuzzel_args=(
  --dmenu
  --prompt="Layout [$workspace_name] > "
  --lines="${#items[@]}"
  --width=32
)
[[ -z "$current_item" ]] || fuzzel_args+=(--select="$current_item")

choice="$(printf '%s\n' "${items[@]}" | fuzzel "${fuzzel_args[@]}")" || exit 0
[[ -z "$choice" ]] && exit 0

selected="${layout_by_item[$choice]:-}"
[[ -n "$selected" ]] || fail "Choose one of the listed layouts"
[[ "$selected" == "$current_layout" ]] && exit 0

lua_code="local workspace = require(\"hyprland.lib.layout\").set(\"$selected\"); assert(workspace ~= nil, \"no regular active workspace\")"
if ! result="$(hyprctl eval "$lua_code" 2>&1)"; then
  fail "Could not apply ${display_by_layout[$selected]}: $result"
fi
if [[ "$result" != "ok" ]]; then
  fail "Hyprland rejected ${display_by_layout[$selected]}: $result"
fi

notify "Layout changed" "Workspace $workspace_name: ${display_by_layout[$selected]}"
