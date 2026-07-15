#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
packages=(
  ghostty fish starship herdr nvim zathura yazi fuzzel hypr lazygit noctalia pi
  desktop automation
)

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
profile_dir="$config_home/naldo"
profile_file="${MACHINE_PROFILE_FILE:-$profile_dir/machine-profile}"
legacy_profile_file="$config_home/hypr/machine/profile"
profile_values="$REPO_DIR/machine/profiles"
profile_default="$REPO_DIR/machine/profile.default"
profile="${MACHINE_PROFILE:-}"
profile_source="MACHINE_PROFILE"

if [[ -z "$profile" ]]; then
  for candidate in "$profile_file" "$legacy_profile_file" "$profile_default"; do
    if [[ -r "$candidate" ]]; then
      read -r profile <"$candidate"
      profile_source="$candidate"
      break
    fi
  done
fi
profile="${profile//[[:space:]]/}"
grep -Fxq -- "$profile" "$profile_values" || {
  printf 'Invalid machine profile from %s: %q\nAllowed values:\n' "$profile_source" "$profile" >&2
  sed 's/^/  /' "$profile_values" >&2
  exit 2
}

install -d -m 700 "$(dirname -- "$profile_file")"
printf '%s\n' "$profile" | install -m 600 /dev/stdin "$profile_file"
if [[ "$legacy_profile_file" != "$profile_file" ]]; then
  rm -f -- "$legacy_profile_file"
fi
printf 'Machine profile: %s (%s)\n' "$profile" "$profile_file"

stow --dir="$REPO_DIR" --target="$HOME" --restow "${packages[@]}"

pi_settings="$HOME/.pi/agent/settings.json"
pi_defaults="$HOME/.pi/agent/settings.default.json"
if [[ -L "$pi_settings" && ! -e "$pi_settings" ]]; then
  rm -- "$pi_settings"
fi
if [[ ! -e "$pi_settings" ]]; then
  install -m 600 "$pi_defaults" "$pi_settings"
  printf 'Initialized machine-local Pi settings from settings.default.json.\n'
fi

systemctl --user daemon-reload
printf 'Dotfiles installed. Enable centralized sync with:\n'
printf '  sync-control enable\n'
