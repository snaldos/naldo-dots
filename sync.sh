#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REMOTE="${SYNC_REMOTE:-origin}"
BRANCH="${SYNC_BRANCH:-main}"
HOST="$(hostname -s)"
COMMIT_MESSAGE="${SYNC_COMMIT_MESSAGE:-${*:-sync(${HOST}): $(date --iso-8601=seconds)}}"

log() {
  printf '[dotfiles] %s\n' "$*"
}

fail() {
  log "ERROR: $*" >&2
  exit 1
}

cd "$REPO_DIR"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a Git repository: $REPO_DIR"
git remote get-url "$REMOTE" >/dev/null 2>&1 || fail "missing Git remote: $REMOTE"

exec 9>"$(git rev-parse --git-path naldo-sync.lock)"
flock -n 9 || fail "another dotfiles sync is already running"

[[ ! -d "$(git rev-parse --git-path rebase-merge)" ]] || fail "a rebase is already in progress"
[[ ! -d "$(git rev-parse --git-path rebase-apply)" ]] || fail "a rebase is already in progress"
[[ ! -f "$(git rev-parse --git-path MERGE_HEAD)" ]] || fail "a merge is already in progress"

current_branch="$(git branch --show-current)"
[[ "$current_branch" == "$BRANCH" ]] || fail "expected branch $BRANCH, found ${current_branch:-detached HEAD}"

git add -A
git diff --cached --check

if git diff --cached --quiet; then
  log "no local changes to commit"
else
  git commit -m "$COMMIT_MESSAGE"
fi

[[ -z "$(git status --porcelain)" ]] || fail "working tree changed while syncing; run again"

log "fetching $REMOTE"
git fetch --prune "$REMOTE"

if git show-ref --verify --quiet "refs/remotes/$REMOTE/$BRANCH"; then
  log "rebasing onto $REMOTE/$BRANCH"
  git rebase "$REMOTE/$BRANCH"
fi

log "pushing $BRANCH"
git push --set-upstream "$REMOTE" "$BRANCH"
log "sync complete"
