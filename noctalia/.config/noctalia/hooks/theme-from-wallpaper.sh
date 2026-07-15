#!/usr/bin/env bash
set -euo pipefail

# The hook provides the path that changed. Fall back to the default wallpaper
# when the script is run manually.
wall="${NOCTALIA_WALLPAPER_PATH:-$(noctalia msg wallpaper-get)}"
current_scheme="$(noctalia msg color-scheme-get)"
current_source="${current_scheme%% *}"
source="$current_source"
current_palette="${current_scheme#* }"

# A custom palette is intentionally independent of the wallpaper hierarchy.
[[ "$current_source" == "custom" ]] && exit 0

# Theme mode from the top-level wallpaper folder.
if [[ "$wall" == */light/* ]]; then
  mode="light"
else
  mode="dark"
fi

# Keep the current palette source when it has a matching family. The default
# wallpaper family uses Noctalia's canonical built-in palette.
case "$source:$wall" in
  builtin:*/catppuccin/*)  palette="Catppuccin" ;;
  builtin:*/rose-pine/*)   palette="Rosé Pine" ;;
  builtin:*/tokyo-night/*) palette="Tokyo-Night" ;;
  builtin:*/default/*)     palette="Noctalia" ;;

  community:*/catppuccin/*)  palette="Catppuccin Lavender" ;;
  community:*/rose-pine/*)   palette="Rose Pine Moon" ;;
  community:*/tokyo-night/*) palette="Tokyo Night Moon" ;;
  community:*/default/*)     source="builtin"; palette="Noctalia" ;;

  # Wallpaper palettes automatically regenerate when the default wallpaper
  # changes, so preserve the selected generator (for example m3-content).
  wallpaper:*) palette="$current_palette" ;;

  # Do not replace an unknown source or an unmatched wallpaper family.
  *) exit 0 ;;
esac

current_mode="$(noctalia msg theme-mode-get)"
changed=false

if [[ "$current_mode" != "$mode" ]]; then
  noctalia msg theme-mode-set "$mode"
  changed=true
fi

if [[ "$source" != "wallpaper" ]] &&
  [[ "$current_source" != "$source" || "$current_palette" != "$palette" ]]; then
  noctalia msg color-scheme-set "$source" "$palette"
  changed=true
fi

if [[ "$changed" == true ]]; then
  noctalia msg templates-apply
  notify-send "Noctalia theme" "$palette ($mode, $source)"
fi
