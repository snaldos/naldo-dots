#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
INSTALLER="$REPO_DIR/install.sh"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install-test.XXXXXX")"
HOME_TEST="$workspace/home"
RUNTIME_TEST="$workspace/runtime"
FAKE_BIN="$workspace/fake-bin"
checks=0
mkdir -p "$HOME_TEST" "$RUNTIME_TEST" "$FAKE_BIN"
trap 'rm -rf -- "$workspace"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$*"
}

assert_link_to() {
  local path="$1" expected="$2"
  [[ -L "$path" ]] || fail "expected symlink: $path"
  [[ "$(readlink -f -- "$path")" == "$(readlink -f -- "$expected")" ]] ||
    fail "unexpected link target: $path"
}

cat >"$FAKE_BIN/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$SYSTEMCTL_TEST_LOG"
EOF
cat >"$FAKE_BIN/hx" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 755 "$FAKE_BIN/systemctl" "$FAKE_BIN/hx"
export SYSTEMCTL_TEST_LOG="$workspace/systemctl.log"
export HOME="$HOME_TEST"
export XDG_CONFIG_HOME="$HOME_TEST/.config"
export XDG_RUNTIME_DIR="$RUNTIME_TEST"
export PATH="$FAKE_BIN:/usr/local/bin:/usr/bin:/bin"

"$INSTALLER" --profile desktop >"$workspace/install-one.log" 2>&1 || {
  cat "$workspace/install-one.log" >&2
  fail 'fresh-home installation failed'
}
assert_link_to "$HOME_TEST/.config/niri/config.kdl" "$REPO_DIR/niri/.config/niri/config.kdl"
assert_link_to "$HOME_TEST/.config/ghostty/fallbacks/noctalia" \
  "$REPO_DIR/ghostty/.config/ghostty/fallbacks/noctalia"
assert_link_to "$HOME_TEST/.config/git/naldo.conf" "$REPO_DIR/git/.config/git/naldo.conf"
assert_link_to "$HOME_TEST/.local/bin/sync-all" "$REPO_DIR/automation/.local/bin/sync-all"
assert_link_to "$HOME_TEST/.local/bin/naldo-update" "$REPO_DIR/automation/.local/bin/naldo-update"
[[ -f "$HOME_TEST/.config/niri/machine.kdl" && ! -L "$HOME_TEST/.config/niri/machine.kdl" ]] ||
  fail 'Niri machine selector is not real machine-local state'
grep -Fq 'profiles/desktop.kdl' "$HOME_TEST/.config/niri/machine.kdl" ||
  fail 'desktop Niri profile was not selected'
[[ "$(stat -c '%a' "$HOME_TEST/.config/naldo/sync/repositories.conf")" == 600 ]] ||
  fail 'sync configuration mode is not 0600'
[[ "$(stat -c '%a' "$HOME_TEST/.pi/agent/settings.json")" == 600 ]] ||
  fail 'Pi active settings mode is not 0600'
[[ ! -e "$HOME_TEST/.local/bin/hx" ]] || fail 'installer created an unexpected hx wrapper'
[[ "$(HOME="$HOME_TEST" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" git config --global --includes --get core.editor)" == hx ]] ||
  fail 'fresh-home effective Git editor is not hx'
[[ "$(grep -c '^--user daemon-reload$' "$SYSTEMCTL_TEST_LOG")" == 1 ]] ||
  fail 'installer did not perform exactly one user-unit inventory reload'
! grep -Eq '(^| )(enable|start|restart)( |$)' "$SYSTEMCTL_TEST_LOG" ||
  fail 'installer activated a user service or timer'
[[ ! -e "$HOME_TEST/.local/bin/launch-zen" ]] || fail 'obsolete fixed-command Zen wrapper was deployed'
# Literal source assertion; expansion belongs to the launcher at runtime.
# shellcheck disable=SC2016
grep -Fq 'spawn_app flatpak run "$ZEN_FLATPAK_ID"' \
  "$HOME_TEST/.config/niri/scripts/app_launcher.sh" || fail 'Zen launch is not direct'
pass 'fresh home receives no-folding links, local state, explicit desktop profile, and disabled timer inventory'

[[ -f "$HOME_TEST/.config/ghostty/themes/noctalia" &&
  ! -L "$HOME_TEST/.config/ghostty/themes/noctalia" ]] ||
  fail 'fresh Ghostty theme fallback is not real machine-local state'
cmp -s "$REPO_DIR/ghostty/.config/ghostty/fallbacks/noctalia" \
  "$HOME_TEST/.config/ghostty/themes/noctalia" || fail 'fresh Ghostty fallback differs from its tracked seed'
[[ -f "$HOME_TEST/.config/helix/themes/noctalia.toml" &&
  ! -L "$HOME_TEST/.config/helix/themes/noctalia.toml" ]] ||
  fail 'fresh Helix base theme fallback is absent'
[[ -f "$HOME_TEST/.config/zathura/noctaliarc" &&
  ! -s "$HOME_TEST/.config/zathura/noctaliarc" ]] || fail 'fresh Zathura color fallback is not empty'
[[ ! -e "$HOME_TEST/.config/niri/noctalia.kdl" ]] || fail 'installer rendered Noctalia Niri state'
[[ ! -e "$HOME_TEST/.config/yazi/theme.toml" ]] || fail 'installer rendered Noctalia Yazi state'
grep -Fq 'include optional=true "noctalia.kdl"' "$HOME_TEST/.config/niri/config.kdl" ||
  fail 'Niri Noctalia include is not optional on first login'
for generated in \
  ghostty/.config/ghostty/themes/noctalia \
  niri/.config/niri/noctalia.kdl \
  helix/.config/helix/themes/noctalia.toml \
  yazi/.config/yazi/theme.toml \
  yazi/.config/yazi/flavors/noctalia.yazi/flavor.toml \
  yazi/.config/yazi/flavors/noctalia.yazi/tmtheme.xml \
  zathura/.config/zathura/noctaliarc; do
  git -C "$REPO_DIR" check-ignore -q "$generated" || fail "generated output is not ignored: $generated"
  ! git -C "$REPO_DIR" ls-files --error-unmatch "$generated" >/dev/null 2>&1 ||
    fail "generated output is tracked: $generated"
done
pass 'fresh-session generated consumers have safe fallbacks without tracked generated state'

printf '# retained local fish state\n' >"$HOME_TEST/.config/fish/local.fish"
printf '{"machineLocal":true}\n' >"$HOME_TEST/.pi/agent/settings.json"
printf '# retained credentials\n' >"$HOME_TEST/.config/noctalia/credentials.toml"
printf '# locally rendered Ghostty palette\nbackground = #123456\nforeground = #ffffff\n' \
  >"$HOME_TEST/.config/ghostty/themes/noctalia"
printf '\n# retained repository override\n' >>"$HOME_TEST/.config/naldo/sync/repositories.conf"
for path in \
  "$HOME_TEST/.config/fish/local.fish" \
  "$HOME_TEST/.pi/agent/settings.json" \
  "$HOME_TEST/.config/noctalia/credentials.toml" \
  "$HOME_TEST/.config/ghostty/themes/noctalia" \
  "$HOME_TEST/.config/naldo/sync/repositories.conf"; do
  sha256sum "$path" >>"$workspace/local-state.before"
done

"$INSTALLER" --profile desktop >"$workspace/install-two.log" 2>&1 || {
  cat "$workspace/install-two.log" >&2
  fail 'idempotent reinstall failed'
}
: >"$workspace/local-state.after"
for path in \
  "$HOME_TEST/.config/fish/local.fish" \
  "$HOME_TEST/.pi/agent/settings.json" \
  "$HOME_TEST/.config/noctalia/credentials.toml" \
  "$HOME_TEST/.config/ghostty/themes/noctalia" \
  "$HOME_TEST/.config/naldo/sync/repositories.conf"; do
  sha256sum "$path" >>"$workspace/local-state.after"
done
cmp -s "$workspace/local-state.before" "$workspace/local-state.after" ||
  fail 'idempotent reinstall changed machine-local contents'
[[ "$(grep -c '^--user daemon-reload$' "$SYSTEMCTL_TEST_LOG")" == 2 ]] ||
  fail 'second install did not perform one additional unit inventory reload'
[[ "$(HOME="$HOME_TEST" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" git config --global --get-all include.path | wc -l)" == 1 ]] ||
  fail 'idempotent reinstall duplicated the Git include'
pass 'reinstallation is idempotent and preserves existing local/private files'

"$INSTALLER" --profile laptop >"$workspace/install-laptop.log" 2>&1 || {
  cat "$workspace/install-laptop.log" >&2
  fail 'laptop profile reinstall failed'
}
grep -Fq 'profiles/laptop.kdl' "$HOME_TEST/.config/niri/machine.kdl" ||
  fail 'laptop Niri profile was not selected'
assert_link_to "$HOME_TEST/.local/bin/naldo-update" "$REPO_DIR/automation/.local/bin/naldo-update"
[[ ! -e "$HOME_TEST/.config/naldo/machine-profile" ]] ||
  fail 'unused machine-profile indirection was deployed'
pass 'desktop and laptop profiles select their corresponding Niri sources directly'

missing_profile_home="$workspace/missing-profile-home"
mkdir -p "$missing_profile_home"
if HOME="$missing_profile_home" XDG_CONFIG_HOME="$missing_profile_home/.config" \
  XDG_RUNTIME_DIR="$RUNTIME_TEST" PATH="$PATH" \
  "$INSTALLER" >"$workspace/missing-profile.log" 2>&1; then
  fail 'installer accepted an implicit machine profile'
fi
grep -Fq -- '--profile desktop|laptop is required' "$workspace/missing-profile.log" ||
  fail 'missing explicit-profile diagnostic was not reported'
[[ -z "$(find "$missing_profile_home" -mindepth 1 -print -quit)" ]] ||
  fail 'missing profile was detected after mutating the target home'
pass 'fresh installation requires one explicit real machine profile'

missing_hx_home="$workspace/missing-hx-home"
missing_hx_bin="$workspace/missing-hx-bin"
mkdir -p "$missing_hx_home" "$missing_hx_bin"
for command_name in dirname git stow flock systemctl; do
  ln -s "$(command -v "$command_name")" "$missing_hx_bin/$command_name"
done
if HOME="$missing_hx_home" XDG_CONFIG_HOME="$missing_hx_home/.config" \
  XDG_RUNTIME_DIR="$RUNTIME_TEST" PATH="$missing_hx_bin" \
  /bin/bash "$INSTALLER" --profile desktop >"$workspace/missing-hx.log" 2>&1; then
  fail 'installer accepted a Fedora target without hx'
fi
grep -Fq 'missing command: hx' "$workspace/missing-hx.log" ||
  fail 'missing native hx diagnostic was not reported'
[[ -z "$(find "$missing_hx_home" -mindepth 1 -print -quit)" ]] ||
  fail 'missing hx was detected only after mutating the target home'
pass 'native Fedora hx is required before any home deployment'

printf '1..%d\n' "$checks"
