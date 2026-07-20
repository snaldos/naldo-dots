#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DEPLOY_LINKS="$REPO_DIR/deploy-links.sh"
CREDENTIAL_GUARD="$REPO_DIR/automation/.local/libexec/naldo/git-secret-guard"
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

reconcile_links() {
  [[ -x "$DEPLOY_LINKS" ]] || fail "missing executable: $DEPLOY_LINKS"
  NALDO_DOTFILES_LOCK_HELD=1 "$DEPLOY_LINKS" || fail "could not reconcile Stow links"
}

reload_user_units_if_changed() {
  local old_revision="$1" new_revision="$2" diff_status

  if git diff --quiet "$old_revision" "$new_revision" -- automation/.config/systemd/user; then
    return
  else
    diff_status=$?
  fi
  ((diff_status == 1)) || fail "could not compare user systemd unit revisions"

  command -v systemctl >/dev/null 2>&1 || fail "user units changed but systemctl is unavailable"
  log "reloading user systemd unit inventory"
  systemctl --user daemon-reload || fail "could not reload user systemd units"
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

initial_head="$(git rev-parse HEAD)"

git add -A
git diff --cached --check

[[ -x "$CREDENTIAL_GUARD" ]] || fail "missing credential guard: $CREDENTIAL_GUARD"
log "checking public repository index for credentials"
"$CREDENTIAL_GUARD" "$REPO_DIR" || fail "credential check failed"

if git diff --cached --quiet; then
  log "no local changes to commit"
else
  git commit -m "$COMMIT_MESSAGE"
fi

[[ -z "$(git status --porcelain)" ]] || fail "working tree changed while syncing; run again"
local_head="$(git rev-parse HEAD)"

log "reconciling Stow links for the local tree"
reconcile_links
reload_user_units_if_changed "$initial_head" "$local_head"
[[ -z "$(git status --porcelain)" ]] || fail "working tree changed while deploying links; run again"

log "fetching $REMOTE"
git fetch --prune "$REMOTE"

if git show-ref --verify --quiet "refs/remotes/$REMOTE/$BRANCH"; then
  log "rebasing onto $REMOTE/$BRANCH"
  git rebase "$REMOTE/$BRANCH"
fi

integrated_head="$(git rev-parse HEAD)"
if [[ "$integrated_head" != "$local_head" ]]; then
  log "reconciling Stow links for the integrated tree"
  reconcile_links
  reload_user_units_if_changed "$local_head" "$integrated_head"
  [[ -z "$(git status --porcelain)" ]] || fail "working tree changed while deploying links; run again"
fi

log "pushing $BRANCH"
git push --set-upstream "$REMOTE" "$BRANCH"
log "sync complete"
