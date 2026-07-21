#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DEPLOY_LINKS="$REPO_DIR/deploy-links.sh"

fail() {
  printf 'install: ERROR: %s\n' "$*" >&2
  exit 2
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Deploy all dotfile packages and initialize machine-local state.

Options:
  --profile PROFILE  Select a value from machine-profile/profiles
  --non-interactive  Use the tracked default when no profile exists
  -h, --help         Show this help
EOF
}

requested_profile=""
non_interactive=0
while (($# > 0)); do
  case "$1" in
    --profile)
      (($# >= 2)) || fail "--profile requires a value"
      requested_profile="$2"
      shift 2
      ;;
    --profile=*)
      requested_profile="${1#*=}"
      [[ -n "$requested_profile" ]] || fail "--profile requires a value"
      shift
      ;;
    --non-interactive)
      non_interactive=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

for required_command in git stow flock systemctl; do
  command -v "$required_command" >/dev/null 2>&1 || fail "missing command: $required_command"
done
git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  fail "not a Git working tree: $REPO_DIR"

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
profile_dir="$config_home/naldo/machine-profile"
profile_file="$profile_dir/profile"
profile_default_source="$REPO_DIR/machine/.config/naldo/machine-profile/default"
profile_values_source="$REPO_DIR/machine/.config/naldo/machine-profile/profiles"

read -r profile_default <"$profile_default_source"
profile_default="${profile_default//[[:space:]]/}"
grep -Fxq -- "$profile_default" "$profile_values_source" ||
  fail "tracked default is not listed in $profile_values_source: $profile_default"

choose_machine_profile() {
  local answer choice_number index
  local -a choices=()
  mapfile -t choices <"$profile_values_source"

  printf 'Select this machine profile:\n' >&2
  for index in "${!choices[@]}"; do
    printf '  %d) %s%s\n' "$((index + 1))" "${choices[$index]}" \
      "$([[ "${choices[$index]}" == "$profile_default" ]] && printf ' (default)' || true)" >&2
  done
  while true; do
    printf 'Profile [%s]: ' "$profile_default" >&2
    IFS= read -r answer || fail "could not read machine profile"
    answer="${answer//[[:space:]]/}"
    if [[ -z "$answer" ]]; then
      printf '%s\n' "$profile_default"
      return
    fi
    if [[ "$answer" =~ ^[0-9]+$ ]]; then
      choice_number=$((10#$answer))
      if ((choice_number >= 1 && choice_number <= ${#choices[@]})); then
        printf '%s\n' "${choices[$((choice_number - 1))]}"
        return
      fi
    fi
    if grep -Fxq -- "$answer" "$profile_values_source"; then
      printf '%s\n' "$answer"
      return
    fi
    printf 'Choose a listed number or profile name.\n' >&2
  done
}

profile_override="$requested_profile"
profile_source="--profile"
if [[ -z "$profile_override" && -f "$profile_file" && -r "$profile_file" ]]; then
  IFS= read -r profile_override <"$profile_file" || true
  profile_override="${profile_override//[[:space:]]/}"
  [[ -n "$profile_override" ]] || fail "machine profile override is empty: $profile_file"
  profile_source="$profile_file"
elif [[ -z "$profile_override" && -r "$profile_dir/default" && -r "$profile_dir/profiles" ]]; then
  : # Existing installation intentionally uses the tracked default.
elif [[ -z "$profile_override" && "$non_interactive" == 1 ]]; then
  : # Explicitly accept the tracked default on a fresh non-interactive install.
elif [[ -z "$profile_override" && -t 0 ]]; then
  profile_override="$(choose_machine_profile)"
  profile_source="interactive selection"
elif [[ -z "$profile_override" ]]; then
  fail "fresh non-interactive install requires --profile or --non-interactive"
fi
profile_override="${profile_override//[[:space:]]/}"

effective_profile="${profile_override:-$profile_default}"
effective_source="$profile_default_source"
[[ -z "$profile_override" ]] || effective_source="$profile_source"
grep -Fxq -- "$effective_profile" "$profile_values_source" || {
  printf 'Invalid machine profile from %s: %q\nAllowed values:\n' \
    "$effective_source" "$effective_profile" >&2
  sed 's/^/  /' "$profile_values_source" >&2
  exit 2
}

# The tracked default needs no redundant machine-local override.
[[ "$profile_override" != "$profile_default" ]] || profile_override=""

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
install -d "$runtime_dir"
exec 8>"$runtime_dir/naldo-sync-all.lock"
flock -n 8 || fail "synchronization is active; retry after sync-all finishes"
exec 9>"$(git -C "$REPO_DIR" rev-parse --git-path naldo-sync.lock)"
flock -n 9 || fail "another dotfiles operation is active"

[[ -x "$DEPLOY_LINKS" ]] || fail "missing executable: $DEPLOY_LINKS"
NALDO_DOTFILES_LOCK_HELD=1 "$DEPLOY_LINKS" || fail "could not reconcile Stow links"

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

noctalia_config_dir="$config_home/noctalia"
noctalia_credentials="$noctalia_config_dir/credentials.toml"
noctalia_credentials_seed="$REPO_DIR/noctalia/.config/noctalia/credentials.toml.example"
[[ -f "$noctalia_credentials_seed" ]] ||
  fail "missing Noctalia credentials seed: $noctalia_credentials_seed"
[[ ! -L "$noctalia_config_dir" ]] ||
  fail "Noctalia config directory must be real: $noctalia_config_dir"
[[ ! -e "$noctalia_config_dir" || -d "$noctalia_config_dir" ]] ||
  fail "Noctalia config path must be a directory: $noctalia_config_dir"
install -d -m 700 "$noctalia_config_dir"
[[ ! -L "$noctalia_credentials" ]] ||
  fail "Noctalia credentials must be a real file: $noctalia_credentials"
[[ ! -e "$noctalia_credentials" || -f "$noctalia_credentials" ]] ||
  fail "Noctalia credentials path must be a regular file: $noctalia_credentials"
if [[ ! -e "$noctalia_credentials" ]]; then
  install -m 600 "$noctalia_credentials_seed" "$noctalia_credentials"
  printf 'Initialized machine-local Noctalia credentials from credentials.toml.example.\n'
else
  chmod 600 "$noctalia_credentials"
fi

zathura_config_dir="$config_home/zathura"
zathura_theme="$zathura_config_dir/noctaliarc"
[[ ! -L "$zathura_config_dir" ]] ||
  fail "Zathura config directory must be real: $zathura_config_dir"
[[ ! -e "$zathura_config_dir" || -d "$zathura_config_dir" ]] ||
  fail "Zathura config path must be a directory: $zathura_config_dir"
install -d -m 755 "$zathura_config_dir"
[[ ! -L "$zathura_theme" ]] || fail "Zathura theme include must be a real file: $zathura_theme"
[[ ! -e "$zathura_theme" || -f "$zathura_theme" ]] ||
  fail "Zathura theme include path must be a regular file: $zathura_theme"
if [[ ! -e "$zathura_theme" ]]; then
  install -m 644 /dev/null "$zathura_theme"
  printf 'Initialized empty machine-local Zathura theme include: %s\n' "$zathura_theme"
fi

fish_config_dir="$HOME/.config/fish"
[[ ! -e "$fish_config_dir" || -d "$fish_config_dir" ]] ||
  fail "Fish config path must be a directory: $fish_config_dir"
install -d -m 700 "$fish_config_dir"
fish_local="$fish_config_dir/local.fish"
[[ ! -L "$fish_local" ]] || fail "Fish local overrides must be a real file: $fish_local"
[[ ! -e "$fish_local" || -f "$fish_local" ]] ||
  fail "Fish local overrides path must be a regular file: $fish_local"
if [[ ! -e "$fish_local" ]]; then
  install -m 600 /dev/null "$fish_local"
  printf 'Initialized empty machine-local Fish overrides: %s\n' "$fish_local"
else
  chmod 600 "$fish_local"
fi

pi_agent_dir="$HOME/.pi/agent"
install -d -m 700 "$pi_agent_dir"
pi_settings="$pi_agent_dir/settings.json"
pi_defaults="$pi_agent_dir/settings.default.json"
[[ ! -L "$pi_settings" ]] || fail "Pi active settings must be a real file: $pi_settings"
[[ ! -e "$pi_settings" || -f "$pi_settings" ]] ||
  fail "Pi active settings path must be a regular file: $pi_settings"
if [[ ! -e "$pi_settings" ]]; then
  install -m 600 "$pi_defaults" "$pi_settings"
  printf 'Initialized machine-local Pi settings from settings.default.json.\n'
else
  chmod 600 "$pi_settings"
fi

systemctl --user daemon-reload
printf 'Dotfiles installed. Enable centralized sync with:\n'
printf '  sync-control enable\n'
