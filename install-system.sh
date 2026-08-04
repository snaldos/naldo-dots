#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
KEYD_SOURCE="$REPO_DIR/system/keyd/default.conf"
KEYD_DESTINATION="/etc/keyd/default.conf"
UDEV_SOURCE="$REPO_DIR/system/udev/69-keyd-bongocat.rules"
UDEV_DESTINATION="/etc/udev/rules.d/69-keyd-bongocat.rules"
DRY_RUN=0

fail() {
  printf 'install-system: ERROR: %s\n' "$*" >&2
  exit 2
}

usage() {
  cat <<'EOF'
Usage: ./install-system.sh [--dry-run]

Install the complete reviewed keyd/Noctalia input integration:
  /etc/keyd/default.conf
  /etc/udev/rules.d/69-keyd-bongocat.rules

The installer validates and copies configuration only. It never installs keyd,
reloads udev, changes service state, or recreates input devices.
EOF
}

while (($# > 0)); do
  case "$1" in
  --dry-run)
    DRY_RUN=1
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

command -v keyd >/dev/null 2>&1 || fail "keyd is not installed; refusing before any write"
command -v install >/dev/null 2>&1 || fail "missing command: install"
[[ -f "$KEYD_SOURCE" && ! -L "$KEYD_SOURCE" ]] || fail "missing real keyd source: $KEYD_SOURCE"
[[ -f "$UDEV_SOURCE" && ! -L "$UDEV_SOURCE" ]] || fail "missing real udev source: $UDEV_SOURCE"

keyd check "$KEYD_SOURCE"

expected_udev_rule='KERNEL=="event*", SUBSYSTEM=="input", ATTRS{name}=="keyd virtual keyboard", SYMLINK+="input/by-id/keyd-virtual-kbd", TAG+="uaccess"'
[[ "$(<"$UDEV_SOURCE")" == "$expected_udev_rule" ]] ||
  fail "udev rule differs from the reviewed keyd virtual-keyboard rule"

print_action() {
  printf '+ install'
  printf ' %q' "$@"
  printf '\n'
}

run_install() {
  print_action "$@"
  ((DRY_RUN == 1)) || install "$@"
}

if ((DRY_RUN == 0 && EUID != 0)); then
  fail "a real installation must run as root; use --dry-run to inspect actions"
fi

run_install -d -o root -g root -m 0755 -- /etc/keyd
run_install -o root -g root -m 0644 -- "$KEYD_SOURCE" "$KEYD_DESTINATION"
run_install -d -o root -g root -m 0755 -- /etc/udev/rules.d
run_install -o root -g root -m 0644 -- "$UDEV_SOURCE" "$UDEV_DESTINATION"

if ((DRY_RUN == 1)); then
  printf 'Dry run complete; no system paths were changed.\n'
else
  printf 'Installed keyd configuration: %s\n' "$KEYD_DESTINATION"
  printf 'Installed keyd virtual-device rule: %s\n' "$UDEV_DESTINATION"
  printf 'udev and keyd were not reloaded; follow system/keyd/README.md explicitly.\n'
fi
