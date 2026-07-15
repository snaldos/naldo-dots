#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
packages=(
  ghostty fish starship herdr nvim zathura yazi fuzzel hypr lazygit noctalia pi
  desktop automation machine
)

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
profile_dir="${MACHINE_PROFILE_DIR:-$config_home/naldo/machine-profile}"
profile_file="${MACHINE_PROFILE_FILE:-$profile_dir/profile}"
profile_default_source="$REPO_DIR/machine/.config/naldo/machine-profile/default"
profile_values_source="$REPO_DIR/machine/.config/naldo/machine-profile/profiles"
profile_override="${MACHINE_PROFILE:-}"
profile_source="MACHINE_PROFILE"

if [[ -z "$profile_override" && -f "$profile_file" && -r "$profile_file" ]]; then
  read -r profile_override <"$profile_file"
  profile_source="$profile_file"
fi
profile_override="${profile_override//[[:space:]]/}"

read -r profile_default <"$profile_default_source"
profile_default="${profile_default//[[:space:]]/}"
effective_profile="${profile_override:-$profile_default}"
effective_source="${profile_default_source}"
[[ -z "$profile_override" ]] || effective_source="$profile_source"
grep -Fxq -- "$effective_profile" "$profile_values_source" || {
  printf 'Invalid machine profile from %s: %q\nAllowed values:\n' \
    "$effective_source" "$effective_profile" >&2
  sed 's/^/  /' "$profile_values_source" >&2
  exit 2
}

if [[ -e "$profile_dir" && ! -d "$profile_dir" ]]; then
  printf 'Machine profile path must be a directory: %s\n' "$profile_dir" >&2
  exit 2
fi
install -d -m 700 "$profile_dir"
if [[ -n "$profile_override" ]]; then
  printf '%s\n' "$profile_override" | install -m 600 /dev/stdin "$profile_file"
else
  rm -f -- "$profile_file"
fi

fish_config_dir="$HOME/.config/fish"
fish_source_dir="$REPO_DIR/fish/.config/fish"
fish_state_temp=""
if [[ -L "$fish_config_dir" ]]; then
  fish_link_target="$(readlink -f "$fish_config_dir")"
  fish_state_temp="$(mktemp -d)"
  for name in fish_variables local.fish; do
    [[ ! -f "$fish_config_dir/$name" ]] || cp -- "$fish_config_dir/$name" "$fish_state_temp/$name"
  done
  rm -- "$fish_config_dir"
  install -d -m 700 "$fish_config_dir"
  for name in fish_variables local.fish; do
    [[ ! -f "$fish_state_temp/$name" ]] || install -m 600 "$fish_state_temp/$name" "$fish_config_dir/$name"
  done
  rm -rf -- "$fish_state_temp"
  if [[ "$fish_link_target" == "$fish_source_dir" ]]; then
    rm -f -- "$fish_source_dir/fish_variables" "$fish_source_dir/local.fish"
  fi
elif [[ -e "$fish_config_dir" && ! -d "$fish_config_dir" ]]; then
  printf 'Fish config path must be a directory: %s\n' "$fish_config_dir" >&2
  exit 2
else
  install -d -m 700 "$fish_config_dir"
fi

fish_local="$fish_config_dir/local.fish"
if [[ ! -e "$fish_local" ]]; then
  install -m 600 /dev/null "$fish_local"
  printf 'Initialized empty machine-local Fish overrides: %s\n' "$fish_local"
fi

stow --dir="$REPO_DIR" --target="$HOME" --restow "${packages[@]}"
printf 'Machine profile: %s (%s)\n' "$effective_profile" \
  "$([[ -n "$profile_override" ]] && printf '%s' "$profile_file" || printf '%s/default' "$profile_dir")"

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
