#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
DEPLOY_LINKS="$REPO_DIR/deploy-links.sh"
FIXTURE="$REPO_DIR/tests/fixtures/zathurarc-pre-split"
REAL_STOW="$(command -v stow)"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-deploy-test.XXXXXX")"
checks=0

cleanup() {
  case "$workspace" in
  "${TMPDIR:-/tmp}"/dotfiles-deploy-test.*)
    rm -rf -- "$workspace"
    ;;
  *)
    printf 'Refusing to remove unexpected test workspace: %s\n' "$workspace" >&2
    ;;
  esac
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$*"
}

new_target() {
  local name="$1"
  TARGET="$workspace/$name"
  mkdir -- "$TARGET"
}

assert_regular() {
  local path="$1"
  [[ -f "$path" && ! -L "$path" ]] || fail "expected real regular file: $path"
}

assert_link_to() {
  local path="$1" expected="$2"
  [[ -L "$path" ]] || fail "expected symlink: $path"
  [[ "$(readlink -f -- "$path")" == "$(readlink -f -- "$expected")" ]] ||
    fail "unexpected symlink target: $path"
}

assert_no_staging_directory() {
  local target="$1"
  ! find "$target" -maxdepth 1 -name '.dotfiles-stow-migration.*' -print -quit | grep -q . ||
    fail "migration staging directory remains under $target"
}

write_legacy_portal() {
  printf '%s' \
    $'[preferred]\ndefault=hyprland;gtk;\norg.freedesktop.impl.portal.FileChooser=termfilechooser;\n' \
    >"$1"
}

run_successfully() {
  local output="$1"
  shift
  if ! "$@" >"$output" 2>&1; then
    printf '%s\n' "$(<"$output")" >&2
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

# A byte-identical regular file has no unique state and can become a managed link.
new_target identical
install -d "$TARGET/.config/xdg-desktop-portal"
cp "$REPO_DIR/xdg-desktop-portal/.config/xdg-desktop-portal/portals.conf" \
  "$TARGET/.config/xdg-desktop-portal/portals.conf"
run_successfully "$workspace/identical-dry.log" \
  "$DEPLOY_LINKS" --dry-run --target "$TARGET"
assert_regular "$TARGET/.config/xdg-desktop-portal/portals.conf"
grep -Fq 'would migrate .config/xdg-desktop-portal/portals.conf: replace byte-identical file' \
  "$workspace/identical-dry.log" || fail "identical-file migration was not reported"
run_successfully "$workspace/identical-apply.log" "$DEPLOY_LINKS" --target "$TARGET"
assert_link_to "$TARGET/.config/xdg-desktop-portal/portals.conf" \
  "$REPO_DIR/xdg-desktop-portal/.config/xdg-desktop-portal/portals.conf"
assert_no_staging_directory "$TARGET"
pass 'byte-identical regular target is safely linked'

# The exact portal configuration superseded by the tracked package is a known migration.
new_target portal
install -d "$TARGET/.config/xdg-desktop-portal"
write_legacy_portal "$TARGET/.config/xdg-desktop-portal/hyprland-portals.conf"
write_legacy_portal "$TARGET/.config/xdg-desktop-portal/portals.conf"
run_successfully "$workspace/portal-dry.log" "$DEPLOY_LINKS" --dry-run --target "$TARGET"
assert_regular "$TARGET/.config/xdg-desktop-portal/hyprland-portals.conf"
assert_regular "$TARGET/.config/xdg-desktop-portal/portals.conf"
run_successfully "$workspace/portal-apply.log" "$DEPLOY_LINKS" --target "$TARGET"
assert_link_to "$TARGET/.config/xdg-desktop-portal/hyprland-portals.conf" \
  "$REPO_DIR/xdg-desktop-portal/.config/xdg-desktop-portal/hyprland-portals.conf"
assert_link_to "$TARGET/.config/xdg-desktop-portal/portals.conf" \
  "$REPO_DIR/xdg-desktop-portal/.config/xdg-desktop-portal/portals.conf"
assert_no_staging_directory "$TARGET"
pass 'recognized portal files migrate without --adopt'

# The old generated Zathura file is split into tracked behavior and local colors.
new_target zathura
install -d "$TARGET/.config/zathura"
cp "$FIXTURE" "$TARGET/.config/zathura/zathurarc"
run_successfully "$workspace/zathura-dry.log" "$DEPLOY_LINKS" --dry-run --target "$TARGET"
assert_regular "$TARGET/.config/zathura/zathurarc"
[[ ! -e "$TARGET/.config/zathura/noctaliarc" ]] ||
  fail 'dry run created the Zathura color fragment'
run_successfully "$workspace/zathura-apply.log" "$DEPLOY_LINKS" --target "$TARGET"
assert_link_to "$TARGET/.config/zathura/zathurarc" \
  "$REPO_DIR/zathura/.config/zathura/zathurarc"
assert_regular "$TARGET/.config/zathura/noctaliarc"
grep -Fq '# Rendered by Noctalia from this tracked template.' \
  "$TARGET/.config/zathura/noctaliarc" || fail 'Zathura color header was not preserved'
! grep -Fq 'selection-clipboard' "$TARGET/.config/zathura/noctaliarc" ||
  fail 'portable Zathura behavior leaked into the generated color fragment'
assert_no_staging_directory "$TARGET"
pass 'recognized generated Zathura config is split safely'

# One unexpected conflict prevents every otherwise-safe migration in the same run.
new_target mixed
install -d "$TARGET/.config/xdg-desktop-portal" "$TARGET/.config/zathura"
write_legacy_portal "$TARGET/.config/xdg-desktop-portal/portals.conf"
printf 'user-specific configuration\n' >"$TARGET/.config/zathura/zathurarc"
cp "$TARGET/.config/xdg-desktop-portal/portals.conf" "$workspace/mixed-portal.before"
cp "$TARGET/.config/zathura/zathurarc" "$workspace/mixed-zathura.before"
run_expect_failure "$workspace/mixed-dry.log" "$DEPLOY_LINKS" --dry-run --target "$TARGET"
run_expect_failure "$workspace/mixed-apply.log" "$DEPLOY_LINKS" --target "$TARGET"
cmp -s -- "$workspace/mixed-portal.before" \
  "$TARGET/.config/xdg-desktop-portal/portals.conf" || fail 'safe file changed during failed preflight'
cmp -s -- "$workspace/mixed-zathura.before" "$TARGET/.config/zathura/zathurarc" ||
  fail 'unexpected file changed during failed preflight'
assert_regular "$TARGET/.config/xdg-desktop-portal/portals.conf"
assert_regular "$TARGET/.config/zathura/zathurarc"
grep -Fq 'no target files were changed' "$workspace/mixed-apply.log" ||
  fail 'unsafe-conflict diagnostic was not emitted'
grep -Fq 'refusing --adopt' "$workspace/mixed-apply.log" ||
  fail 'unsafe-adoption diagnostic was not emitted'
assert_no_staging_directory "$TARGET"
pass 'unexpected differing file blocks the complete migration plan'

# If Stow fails after the preflight, staged targets and generated outputs are restored.
new_target rollback
install -d "$TARGET/.config/zathura" "$workspace/fake-bin"
cp "$FIXTURE" "$TARGET/.config/zathura/zathurarc"
cp "$TARGET/.config/zathura/zathurarc" "$workspace/rollback.before"
cat >"$workspace/fake-bin/stow" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
count=0
[[ ! -f "$STOW_TEST_COUNTER" ]] || read -r count <"$STOW_TEST_COUNTER"
((count += 1))
printf '%s\n' "$count" >"$STOW_TEST_COUNTER"
if ((count == 2)); then
  printf 'injected Stow failure\n' >&2
  exit 42
fi
exec "$STOW_REAL" "$@"
EOF
chmod 755 "$workspace/fake-bin/stow"
run_expect_failure "$workspace/rollback.log" \
  env PATH="$workspace/fake-bin:$PATH" STOW_REAL="$REAL_STOW" \
  STOW_TEST_COUNTER="$workspace/stow-counter" "$DEPLOY_LINKS" --target "$TARGET"
cmp -s -- "$workspace/rollback.before" "$TARGET/.config/zathura/zathurarc" ||
  fail 'legacy target was not restored after the injected Stow failure'
assert_regular "$TARGET/.config/zathura/zathurarc"
[[ ! -e "$TARGET/.config/zathura/noctaliarc" ]] ||
  fail 'generated migration output remained after rollback'
grep -Fq 'restoring target files after unsuccessful reconciliation' "$workspace/rollback.log" ||
  fail 'rollback diagnostic was not emitted'
assert_no_staging_directory "$TARGET"
pass 'post-preflight Stow failure restores targets and generated outputs'

printf '1..%d\n' "$checks"
