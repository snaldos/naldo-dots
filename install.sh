#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DEPLOY_LINKS="$REPO_DIR/deploy-links.sh"
INIT_SYNC_CONFIG="$REPO_DIR/automation/.local/libexec/naldo/init-sync-config"

fail() {
  printf 'install: ERROR: %s\n' "$*" >&2
  exit 2
}

usage() {
  cat <<'EOF'
Usage: ./install.sh --profile desktop|laptop

Deploy all user configuration and initialize machine-local state for the one
explicit machine profile.
EOF
}

profile=""
while (($# > 0)); do
  case "$1" in
  --profile)
    (($# >= 2)) || fail "--profile requires a value"
    profile="$2"
    shift 2
    ;;
  --profile=*)
    profile="${1#*=}"
    [[ -n "$profile" ]] || fail "--profile requires a value"
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

case "$profile" in
  desktop|laptop) ;;
  "") fail "--profile desktop|laptop is required" ;;
  *) fail "invalid profile: $profile (expected desktop or laptop)" ;;
esac

for required_command in git stow flock systemctl hx; do
  command -v "$required_command" >/dev/null 2>&1 || fail "missing command: $required_command"
done
git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  fail "not a Git working tree: $REPO_DIR"

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
ghostty_config_dir="$config_home/ghostty"
ghostty_theme_dir="$ghostty_config_dir/themes"
ghostty_theme="$ghostty_theme_dir/noctalia"
ghostty_theme_seed="$REPO_DIR/ghostty/.config/ghostty/fallbacks/noctalia"
niri_config_dir="$config_home/niri"
niri_machine_selector="$niri_config_dir/machine.kdl"
niri_zen_theme_config="$niri_config_dir/zen-theme.kdl"
sync_config="$config_home/naldo/sync/repositories.conf"
sync_config_template="$REPO_DIR/automation/.config/naldo/sync/repositories.conf.example"
git_config_include="$config_home/git/naldo.conf"
helix_config_dir="$config_home/helix"
helix_theme_dir="$helix_config_dir/themes"
helix_theme="$helix_theme_dir/noctalia.toml"
starship_base_source="$REPO_DIR/starship/.config/starship.base.toml"
starship_active="$config_home/starship.toml"

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
install -d "$runtime_dir"
exec 8>"$runtime_dir/naldo-sync-all.lock"
flock -n 8 || fail "synchronization is active; retry after sync-all finishes"
exec 9>"$(git -C "$REPO_DIR" rev-parse --git-path naldo-sync.lock)"
flock -n 9 || fail "another dotfiles operation is active"

[[ -f "$ghostty_theme_seed" ]] || fail "missing Ghostty theme fallback: $ghostty_theme_seed"
[[ -f "$starship_base_source" ]] || fail "missing Starship behavior seed: $starship_base_source"
[[ ! -L "$config_home" ]] || fail "config home must be a real directory: $config_home"
[[ ! -e "$config_home" || -d "$config_home" ]] || fail "config home path must be a directory: $config_home"
install -d -m 755 "$config_home"
[[ ! -L "$starship_active" ]] || fail "Starship active config must be a real file: $starship_active"
[[ ! -e "$starship_active" || -f "$starship_active" ]] ||
  fail "Starship active config path must be a regular file: $starship_active"
if [[ ! -e "$starship_active" ]]; then
  starship_temporary="$(mktemp --tmpdir="$config_home" '.starship.XXXXXX.toml')"
  if ! install -m 644 "$starship_base_source" "$starship_temporary" ||
    ! mv -f -- "$starship_temporary" "$starship_active"; then
    rm -f -- "$starship_temporary"
    fail "could not initialize Starship active config: $starship_active"
  fi
  printf 'Initialized Starship active config from tracked behavior seed: %s\n' "$starship_active"
fi

[[ -x "$DEPLOY_LINKS" ]] || fail "missing executable: $DEPLOY_LINKS"
[[ -x "$INIT_SYNC_CONFIG" ]] || fail "missing executable: $INIT_SYNC_CONFIG"
NALDO_DOTFILES_LOCK_HELD=1 "$DEPLOY_LINKS" || fail "could not reconcile Stow links"

[[ ! -L "$ghostty_config_dir" ]] || fail "Ghostty config directory must be real: $ghostty_config_dir"
[[ ! -e "$ghostty_config_dir" || -d "$ghostty_config_dir" ]] ||
  fail "Ghostty config path must be a directory: $ghostty_config_dir"
[[ ! -L "$ghostty_theme_dir" ]] || fail "Ghostty theme directory must be real: $ghostty_theme_dir"
[[ ! -e "$ghostty_theme_dir" || -d "$ghostty_theme_dir" ]] ||
  fail "Ghostty theme path must be a directory: $ghostty_theme_dir"
install -d -m 755 "$ghostty_theme_dir"
[[ ! -L "$ghostty_theme" ]] || fail "Ghostty Noctalia theme must be a real file: $ghostty_theme"
[[ ! -e "$ghostty_theme" || -f "$ghostty_theme" ]] ||
  fail "Ghostty Noctalia theme path must be a regular file: $ghostty_theme"
if [[ ! -e "$ghostty_theme" ]]; then
  install -m 644 "$ghostty_theme_seed" "$ghostty_theme"
  printf 'Initialized machine-local Ghostty theme with tracked fallback: %s\n' "$ghostty_theme"
fi

"$INIT_SYNC_CONFIG" --config "$sync_config" --template "$sync_config_template"

[[ -f "$git_config_include" ]] || fail "missing deployed Git behavior include: $git_config_include"
git_include_present=0
while IFS= read -r configured_include; do
  if [[ "$configured_include" == "$git_config_include" ]]; then
    git_include_present=1
    break
  fi
done < <(git config --global --path --get-all include.path 2>/dev/null || true)
if ((git_include_present == 0)); then
  git config --global --add include.path "$git_config_include"
  printf 'Added machine-local Git include for portable behavior: %s\n' "$git_config_include"
else
  printf 'Preserved machine-local Git include: %s\n' "$git_config_include"
fi
[[ "$(git config --global --includes --get core.editor 2>/dev/null || true)" == "hx" ]] ||
  fail "portable Git include is loaded, but the effective core.editor is not hx"

[[ ! -L "$niri_config_dir" ]] || fail "Niri config directory must be real: $niri_config_dir"
[[ ! -e "$niri_config_dir" || -d "$niri_config_dir" ]] ||
  fail "Niri config path must be a directory: $niri_config_dir"
install -d -m 755 "$niri_config_dir"

niri_profile_config="$niri_config_dir/profiles/$profile.kdl"
[[ -f "$niri_profile_config" ]] || fail "missing Niri machine profile: $niri_profile_config"
[[ ! -L "$niri_machine_selector" ]] ||
  fail "Niri machine selector must be a real file: $niri_machine_selector"
[[ ! -e "$niri_machine_selector" || -f "$niri_machine_selector" ]] ||
  fail "Niri machine selector path must be a regular file: $niri_machine_selector"

niri_machine_temporary="$(mktemp --tmpdir="$niri_config_dir" '.machine.XXXXXX.kdl')"
if ! printf 'include "profiles/%s.kdl"\n' "$profile" >"$niri_machine_temporary" ||
  ! chmod 600 "$niri_machine_temporary" ||
  ! mv -f -- "$niri_machine_temporary" "$niri_machine_selector"; then
  rm -f -- "$niri_machine_temporary"
  fail "could not write Niri machine selector: $niri_machine_selector"
fi
printf 'Niri profile selector: %s -> profiles/%s.kdl\n' "$niri_machine_selector" "$profile"

[[ ! -L "$niri_zen_theme_config" ]] ||
  fail "Niri Zen theme include must be a real file: $niri_zen_theme_config"
[[ ! -e "$niri_zen_theme_config" || -f "$niri_zen_theme_config" ]] ||
  fail "Niri Zen theme include path must be a regular file: $niri_zen_theme_config"
if [[ ! -e "$niri_zen_theme_config" ]]; then
  printf '%s\n' '// Machine-local Zen Flatpak theme; managed by Niri theme launcher.' |
    install -m 600 /dev/stdin "$niri_zen_theme_config"
  printf 'Initialized Niri Zen theme include: %s\n' "$niri_zen_theme_config"
else
  chmod 600 "$niri_zen_theme_config"
fi

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

[[ ! -L "$helix_config_dir" ]] || fail "Helix config directory must be real: $helix_config_dir"
[[ ! -e "$helix_config_dir" || -d "$helix_config_dir" ]] ||
  fail "Helix config path must be a directory: $helix_config_dir"
[[ ! -L "$helix_theme_dir" ]] || fail "Helix theme directory must be real: $helix_theme_dir"
[[ ! -e "$helix_theme_dir" || -d "$helix_theme_dir" ]] ||
  fail "Helix theme path must be a directory: $helix_theme_dir"
install -d -m 755 "$helix_theme_dir"
[[ ! -L "$helix_theme" ]] || fail "Helix Noctalia theme must be a real file: $helix_theme"
[[ ! -e "$helix_theme" || -f "$helix_theme" ]] ||
  fail "Helix Noctalia theme path must be a regular file: $helix_theme"
if [[ ! -e "$helix_theme" ]]; then
  printf '%s\n' \
    'inherits = "nord"' \
    '' \
    '[palette]' \
    'onSurfaceVariant = "#A3ACB8"' \
    'onSecondaryContainer = "#D8DEE9"' \
    'onTertiaryContainer = "#E5E9F0"' |
    install -m 644 /dev/stdin "$helix_theme"
  printf 'Initialized machine-local Helix theme with Nord fallback: %s\n' "$helix_theme"
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
