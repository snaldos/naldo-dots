#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
packages=(
  ghostty fish starship herdr nvim zathura yazi fuzzel hypr lazygit noctalia pi
  desktop automation machine
)
declare -A package_names=()
for package in "${packages[@]}"; do
  package_names["$package"]=1
done

fail() {
  printf 'install: ERROR: %s\n' "$*" >&2
  exit 2
}

entry_target() {
  local entry="$1"
  local package="${entry%%/*}"
  local relative="${entry#*/}"

  [[ "$entry" == */* && -n "${package_names[$package]:-}" ]] ||
    fail "cannot map package entry: $entry"
  [[ "$relative" != /* && "$relative" != .. && "$relative" != ../* &&
    "$relative" != */../* && "$relative" != */.. ]] ||
    fail "unsafe package entry: $entry"
  printf '%s/%s' "$HOME" "$relative"
}

entries_match() {
  local source="$1"
  local target="$2"

  [[ -e "$source" || -L "$source" ]] || return 1
  [[ -e "$target" || -L "$target" ]] || return 1
  [[ "$source" -ef "$target" ]] && return 0
  [[ -f "$source" && ! -L "$source" && -f "$target" && ! -L "$target" ]] &&
    cmp -s -- "$source" "$target" && return 0
  [[ -L "$source" && -L "$target" && "$(readlink -- "$source")" == "$(readlink -- "$target")" ]]
}

git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  fail "not a Git working tree: $REPO_DIR"

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
effective_source="$profile_default_source"
[[ -z "$profile_override" ]] || effective_source="$profile_source"
grep -Fxq -- "$effective_profile" "$profile_values_source" || {
  printf 'Invalid machine profile from %s: %q\nAllowed values:\n' \
    "$effective_source" "$effective_profile" >&2
  sed 's/^/  /' "$profile_values_source" >&2
  exit 2
}

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
install -d "$runtime_dir"
exec 8>"$runtime_dir/naldo-sync-all.lock"
flock -n 8 || fail "synchronization is active; retry after sync-all finishes"

# Earlier Stow tree-folding could place ignored generated/private state inside
# package directories. Unfold every package, move such state to its deployed
# path, and restow only tracked configuration as individual symlinks.
mapfile -d '' ignored_source_entries < <(
  git -C "$REPO_DIR" ls-files --others --ignored --exclude-standard -z -- "${packages[@]}"
)
for entry in "${ignored_source_entries[@]}"; do
  source="$REPO_DIR/$entry"
  [[ ! -d "$source" || -L "$source" ]] || fail "unexpected ignored directory entry: $entry"
  target="$(entry_target "$entry")"
  if [[ -e "$target" || -L "$target" ]]; then
    entries_match "$source" "$target" || fail "conflicting local state: $target"
  fi
done

stow --dir="$REPO_DIR" --target="$HOME" --no-folding --delete "${packages[@]}"

moved_state=0
for entry in "${ignored_source_entries[@]}"; do
  source="$REPO_DIR/$entry"
  [[ -e "$source" || -L "$source" ]] || continue
  target="$(entry_target "$entry")"
  install -d "$(dirname -- "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    entries_match "$source" "$target" || fail "conflicting local state after unstow: $target"
    rm -f -- "$source"
  else
    mv -- "$source" "$target"
  fi
  ((moved_state += 1))
done

# A previously copied metadata file is not runtime configuration. Remove it
# only when it is byte-identical to the tracked package metadata.
mapfile -d '' tracked_entries < <(git -C "$REPO_DIR" ls-files -z -- "${packages[@]}")
for entry in "${tracked_entries[@]}"; do
  [[ "${entry##*/}" == .gitignore ]] || continue
  [[ "${entry#*/}" != .gitignore ]] || continue
  source="$REPO_DIR/$entry"
  target="$(entry_target "$entry")"
  target_dir="$(dirname -- "$target")"
  if git -C "$target_dir" ls-files --error-unmatch .gitignore >/dev/null 2>&1; then
    [[ -e "$target" || -L "$target" ]] || install -m 644 "$source" "$target"
    continue
  fi
  if [[ -f "$target" && ! -L "$target" ]] && cmp -s -- "$source" "$target"; then
    rm -- "$target"
  fi
done

for package in "${packages[@]}"; do
  find "$REPO_DIR/$package" -depth -type d -empty -delete
done

stow --dir="$REPO_DIR" --target="$HOME" --no-folding --stow "${packages[@]}"
((moved_state == 0)) || printf 'Moved %d generated/private files out of package directories.\n' "$moved_state"

[[ ! -e "$profile_dir" || -d "$profile_dir" ]] ||
  fail "machine profile path must be a directory: $profile_dir"
install -d -m 700 "$profile_dir"
if [[ -n "$profile_override" ]]; then
  printf '%s\n' "$profile_override" | install -m 600 /dev/stdin "$profile_file"
else
  rm -f -- "$profile_file"
fi
printf 'Machine profile: %s (%s)\n' "$effective_profile" \
  "$([[ -n "$profile_override" ]] && printf '%s' "$profile_file" || printf '%s/default' "$profile_dir")"

fish_config_dir="$HOME/.config/fish"
[[ ! -e "$fish_config_dir" || -d "$fish_config_dir" ]] ||
  fail "Fish config path must be a directory: $fish_config_dir"
install -d -m 700 "$fish_config_dir"
fish_local="$fish_config_dir/local.fish"
if [[ ! -e "$fish_local" ]]; then
  install -m 600 /dev/null "$fish_local"
  printf 'Initialized empty machine-local Fish overrides: %s\n' "$fish_local"
fi

pi_agent_dir="$HOME/.pi/agent"
install -d -m 700 "$pi_agent_dir"
pi_settings="$pi_agent_dir/settings.json"
pi_defaults="$pi_agent_dir/settings.default.json"
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
