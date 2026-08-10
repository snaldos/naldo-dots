#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
DEPLOY_LINKS="$REPO_DIR/deploy-links.sh"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-deploy-test.XXXXXX")"
checks=0
trap 'rm -rf -- "$workspace"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$*"
}

run_successfully() {
  local output="$1"
  shift
  if ! "$@" >"$output" 2>&1; then
    cat "$output" >&2
    fail "command failed: $*"
  fi
}

run_expect_failure() {
  local output="$1"
  shift
  if "$@" >"$output" 2>&1; then
    fail "command unexpectedly succeeded: $*"
  fi
}

clean_target="$workspace/clean"
mkdir "$clean_target"
run_successfully "$workspace/clean-dry.log" "$DEPLOY_LINKS" --dry-run --target "$clean_target"
[[ -z "$(find "$clean_target" -mindepth 1 -print -quit)" ]] || fail 'dry run changed its target'
grep -Fq '[stow] dry run complete' "$workspace/clean-dry.log" || fail 'dry-run completion missing'
pass 'clean-home simulation is complete and non-mutating'

run_successfully "$workspace/clean-apply.log" "$DEPLOY_LINKS" --target "$clean_target"
[[ -L "$clean_target/.config/helix/config.toml" ]] || fail 'Helix source was not linked'
[[ -L "$clean_target/.local/bin/sync-all" ]] || fail 'sync-all source was not linked'
[[ -L "$clean_target/.local/bin/naldo-update" ]] || fail 'naldo-update source was not linked'
[[ -L "$clean_target/.local/share/applications/yazi.desktop" ]] || fail 'Yazi desktop source was not linked'
first_link="$(readlink "$clean_target/.config/helix/config.toml")"
run_successfully "$workspace/clean-repeat.log" "$DEPLOY_LINKS" --target "$clean_target"
[[ "$(readlink "$clean_target/.config/helix/config.toml")" == "$first_link" ]] ||
  fail 'repeated deployment changed the managed link target'
pass 'fresh deployment is complete and idempotent'

identical_target="$workspace/identical"
mkdir -p "$identical_target/.config/niri"
cp "$REPO_DIR/niri/.config/niri/config.kdl" \
  "$identical_target/.config/niri/config.kdl"
cp "$identical_target/.config/niri/config.kdl" "$workspace/identical.before"
run_expect_failure "$workspace/identical.log" "$DEPLOY_LINKS" --target "$identical_target"
cmp -s "$workspace/identical.before" "$identical_target/.config/niri/config.kdl" ||
  fail 'conflicting regular target changed'
[[ -f "$identical_target/.config/niri/config.kdl" &&
  ! -L "$identical_target/.config/niri/config.kdl" ]] ||
  fail 'conflicting regular target was adopted or migrated'
pass 'regular target conflicts require explicit review even when byte-identical'

mixed_target="$workspace/mixed"
mkdir -p "$mixed_target/.config/zathura"
printf 'private local configuration\n' >"$mixed_target/.config/zathura/zathurarc"
cp "$mixed_target/.config/zathura/zathurarc" "$workspace/mixed.before"
run_expect_failure "$workspace/mixed.log" "$DEPLOY_LINKS" --target "$mixed_target"
cmp -s "$workspace/mixed.before" "$mixed_target/.config/zathura/zathurarc" ||
  fail 'differing conflict changed during failed preflight'
[[ ! -e "$mixed_target/.config/helix/config.toml" ]] ||
  fail 'another package was deployed despite a preflight conflict'
pass 'one differing conflict blocks the complete transaction before mutation'

symlink_target="$workspace/symlink-parent"
redirect_target="$workspace/redirect"
mkdir "$symlink_target" "$redirect_target"
ln -s "$redirect_target" "$symlink_target/.config"
run_expect_failure "$workspace/symlink-parent.log" "$DEPLOY_LINKS" --target "$symlink_target"
grep -Fq 'target parent is a symlink' "$workspace/symlink-parent.log" ||
  fail 'symlinked target-parent diagnostic missing'
[[ -z "$(find "$redirect_target" -mindepth 1 -print -quit)" ]] ||
  fail 'deployment followed a symlinked target parent'
pass 'symlinked target parents cannot redirect deployment outside the target'

removed_reconciliation='--adopt|migra'"tion|lega"'cy'
! rg -n -- "$removed_reconciliation" "$DEPLOY_LINKS" >/dev/null ||
  fail 'deployment script still contains automatic target-conversion behavior'
pass 'deployment contains no automatic target-conversion path'

printf '1..%d\n' "$checks"
