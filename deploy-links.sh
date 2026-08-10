#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="${HOME:?HOME is not set}"
DRY_RUN=0
packages=(
  ghostty fish starship herdr helix zathura yazi niri lazygit noctalia
  pi desktop automation git
)
non_stow_directories=(assets bootstrap system tests)

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

Deploy the declared GNU Stow packages. Existing target conflicts are reported
and never changed automatically.

Options:
  --dry-run        Run the complete Stow simulation without changing links
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
if [[ "${NALDO_DOTFILES_LOCK_HELD:-0}" != 1 ]]; then
  exec 9>"$(git -C "$REPO_DIR" rev-parse --git-path naldo-sync.lock)"
  flock -n 9 || fail "another dotfiles operation is active"
fi

[[ -d "$TARGET_DIR" && ! -L "$TARGET_DIR" ]] || fail "target must be a real directory: $TARGET_DIR"
TARGET_DIR="$(cd -- "$TARGET_DIR" && pwd -P)"

for package in "${packages[@]}"; do
  [[ -d "$REPO_DIR/$package" && ! -L "$REPO_DIR/$package" ]] ||
    fail "missing real Stow package: $package"
done
for directory in "${non_stow_directories[@]}"; do
  [[ -d "$REPO_DIR/$directory" && ! -L "$REPO_DIR/$directory" ]] ||
    fail "missing declared non-Stow directory: $directory"
done

mapfile -d '' ignored_source_entries < <(
  git -C "$REPO_DIR" ls-files --others --ignored --exclude-standard -z -- "${packages[@]}"
)
((${#ignored_source_entries[@]} == 0)) ||
  fail "ignored generated/private state exists inside a package source"

# A symlinked target parent can redirect Stow outside the intended home tree.
# Check every tracked package path before asking Stow to plan the transaction.
while IFS= read -r -d '' source_path; do
  target_relative="${source_path#*/}"
  target_parent="${target_relative%/*}"
  [[ "$target_parent" != "$target_relative" ]] || continue
  current="$TARGET_DIR"
  IFS='/' read -r -a components <<<"$target_parent"
  for component in "${components[@]}"; do
    [[ -n "$component" && "$component" != "." ]] || continue
    current="$current/$component"
    [[ ! -L "$current" ]] || fail "target parent is a symlink: $current"
  done
done < <(git -C "$REPO_DIR" ls-files -z -- "${packages[@]}")

stow_args=(
  --dir="$REPO_DIR"
  --target="$TARGET_DIR"
  --no-folding
  --restow
)

log "checking links under $TARGET_DIR"
stow "${stow_args[@]}" --simulate --verbose=2 "${packages[@]}"
if ((DRY_RUN == 1)); then
  log "dry run complete"
  exit 0
fi

log "reconciling links under $TARGET_DIR"
stow "${stow_args[@]}" "${packages[@]}"
log "links reconciled"
