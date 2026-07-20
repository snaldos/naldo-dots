#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="${HOME:?HOME is not set}"
DRY_RUN=0
packages=(
  ghostty fish starship herdr nvim zathura yazi hypr lazygit noctalia pi
  desktop automation machine
)

log() {
  printf '[stow] %s\n' "$*"
}

fail() {
  log "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS]

Reconcile the declared GNU Stow packages with a target directory.

Options:
  --dry-run        Show the planned Stow operations without changing links
  --target DIR     Override the target directory (default: \$HOME)
  -h, --help       Show this help
EOF
}

while (($# > 0)); do
  case "$1" in
  --dry-run)
    DRY_RUN=1
    shift
    ;;
  --target)
    (($# >= 2)) || fail "--target requires a directory"
    TARGET_DIR="$2"
    shift 2
    ;;
  --target=*)
    TARGET_DIR="${1#*=}"
    [[ -n "$TARGET_DIR" ]] || fail "--target requires a directory"
    shift
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    fail "unknown option: $1"
    ;;
  esac
done

for required_command in git stow flock; do
  command -v "$required_command" >/dev/null 2>&1 || fail "missing command: $required_command"
done

git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  fail "not a Git working tree: $REPO_DIR"
# install.sh and sync.sh hold this lock across their complete transactions.
if [[ "${NALDO_DOTFILES_LOCK_HELD:-0}" != 1 ]]; then
  exec 9>"$(git -C "$REPO_DIR" rev-parse --git-path naldo-sync.lock)"
  flock -n 9 || fail "another dotfiles operation is active"
fi
[[ -d "$TARGET_DIR" ]] || fail "target is not a directory: $TARGET_DIR"
TARGET_DIR="$(cd -- "$TARGET_DIR" && pwd -P)"

for package in "${packages[@]}"; do
  [[ -d "$REPO_DIR/$package" ]] || fail "missing Stow package: $package"
done

mapfile -d '' ignored_source_entries < <(
  git -C "$REPO_DIR" ls-files --others --ignored --exclude-standard -z -- "${packages[@]}"
)
((${#ignored_source_entries[@]} == 0)) ||
  fail "ignored generated/private state exists inside a package source"

stow_args=(
  --dir="$REPO_DIR"
  --target="$TARGET_DIR"
  --no-folding
  --restow
)
if ((DRY_RUN == 1)); then
  stow_args+=(--simulate --verbose=2)
  log "checking links under $TARGET_DIR"
else
  log "reconciling links under $TARGET_DIR"
fi

stow "${stow_args[@]}" "${packages[@]}"

if ((DRY_RUN == 1)); then
  log "dry run complete"
else
  log "links reconciled"
fi
