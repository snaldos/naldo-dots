#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
INSTALLER="$REPO_DIR/install-system.sh"
KEYD_SOURCE="$REPO_DIR/system/keyd/default.conf"
UDEV_SOURCE="$REPO_DIR/system/udev/69-keyd-bongocat.rules"
NOCTALIA_CONFIG="$REPO_DIR/noctalia/.config/noctalia/config.toml"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-system-test.XXXXXX")"
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

expected_rule='KERNEL=="event*", SUBSYSTEM=="input", ATTRS{name}=="keyd virtual keyboard", SYMLINK+="input/by-id/keyd-virtual-kbd", TAG+="uaccess"'
[[ "$(<"$UDEV_SOURCE")" == "$expected_rule" ]] || fail 'tracked udev rule is not exact'
! grep -Eq 'MODE[+:]?=|GROUP[+:]?=' "$UDEV_SOURCE" || fail 'udev rule broadens input-device permissions'
grep -Fq 'input_devices = ["/dev/input/by-id/keyd-virtual-kbd"]' "$NOCTALIA_CONFIG" ||
  fail 'Noctalia does not reference the installed stable symlink'
pass 'Bongo Cat rule matches only the exact keyd device and grants logind uaccess'

"$INSTALLER" --dry-run >"$workspace/dry-one.log" 2>&1 || {
  cat "$workspace/dry-one.log" >&2
  fail 'system dry run failed'
}
"$INSTALLER" --dry-run >"$workspace/dry-two.log" 2>&1 || fail 'repeated system dry run failed'
cmp -s "$workspace/dry-one.log" "$workspace/dry-two.log" || fail 'repeated dry runs are not deterministic'
grep -Eq 'install -o root -g root -m 0644 -- .*/system/keyd/default.conf /etc/keyd/default.conf' \
  "$workspace/dry-one.log" || fail 'keyd source destination or mode missing'
grep -Fq 'install -d -o root -g root -m 0755 -- /etc/udev/rules.d' "$workspace/dry-one.log" ||
  fail 'udev destination directory or mode missing'
grep -Eq 'install -o root -g root -m 0644 -- .*/system/udev/69-keyd-bongocat.rules /etc/udev/rules.d/69-keyd-bongocat.rules' \
  "$workspace/dry-one.log" || fail 'udev source destination or mode missing'
grep -Fq 'Dry run complete; no system paths were changed.' "$workspace/dry-one.log" ||
  fail 'dry-run boundary was not reported'
pass 'dry run prints both exact root-owned installations and is repeatable'

if "$INSTALLER" --profile desktop >"$workspace/obsolete-profile.log" 2>&1; then
  fail 'system installer retained a meaningless machine profile'
fi
grep -Fq 'unknown option: --profile' "$workspace/obsolete-profile.log" ||
  fail 'obsolete profile option did not fail explicitly'
pass 'shared keyd integration has no artificial desktop/laptop profile'

mkdir "$workspace/empty-path"
ln -s /usr/bin/dirname "$workspace/empty-path/dirname"
if PATH="$workspace/empty-path" /usr/bin/bash "$INSTALLER" --dry-run >"$workspace/missing-keyd.log" 2>&1; then
  fail 'missing keyd unexpectedly succeeded'
fi
grep -Fq 'keyd is not installed; refusing before any write' "$workspace/missing-keyd.log" ||
  fail 'missing-keyd preflight diagnostic missing'
! grep -Fq '+ install' "$workspace/missing-keyd.log" ||
  fail 'installer printed a write after missing-keyd preflight failed'
pass 'missing keyd fails before any privileged action'

keyd check "$KEYD_SOURCE" >"$workspace/keyd-check.log" 2>&1 || {
  cat "$workspace/keyd-check.log" >&2
  fail 'tracked keyd configuration failed validation'
}
! rg -n 'udevadm|systemctl|keyd[[:space:]]+(reload|restart|start)' "$INSTALLER" >/dev/null ||
  fail 'system installer activates udev or keyd'
while IFS= read -r system_path; do
  case "$system_path" in
  /etc/keyd|/etc/keyd/default.conf|/etc/udev/rules.d|/etc/udev/rules.d/69-keyd-bongocat.rules) ;;
  *) fail "system installer targets an unrelated path: $system_path" ;;
  esac
done < <(rg -o '/etc/[A-Za-z0-9._/-]+' "$INSTALLER" | sort -u)
pass 'system installer validates but never activates the narrow keyd integration'

printf '1..%d\n' "$checks"
