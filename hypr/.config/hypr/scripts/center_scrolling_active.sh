#!/usr/bin/env bash
set -euo pipefail

active="$(hyprctl -j activewindow)"
monitors="$(hyprctl -j monitors)"

delta="$(
  jq -n \
    --argjson w "$active" \
    --argjson ms "$monitors" '
      ($ms[] | select(.id == $w.monitor)) as $m |
      (($w.at[0] + ($w.size[0] / 2)) - ($m.x + ($m.width / 2))) | round
    '
)"

# Invert the movement numerically, not by string-prefixing "-"
move="$((-delta))"

# Hyprland scrolling "move" wants signed offsets like +500 or -500.
if ((move > 0)); then
  offset="+${move}"
else
  offset="${move}"
fi

hyprctl dispatch "hl.dsp.layout(\"move ${offset}\")"
