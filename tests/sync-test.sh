#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
GENERIC_SYNC="$REPO_DIR/automation/.local/libexec/naldo/sync-git-repo"
SYNC_ALL="$REPO_DIR/automation/.local/bin/sync-all"
INIT_CONFIG="$REPO_DIR/automation/.local/libexec/naldo/init-sync-config"
CONFIG_TEMPLATE="$REPO_DIR/automation/.config/naldo/sync/repositories.conf.example"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-sync-test.XXXXXX")"
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

configure_identity() {
  git -C "$1" config user.name 'Dotfiles Test'
  git -C "$1" config user.email 'dotfiles-test@example.invalid'
}

new_remote_clone() {
  local name="$1" bare seed
  bare="$workspace/remotes/$name.git"
  seed="$workspace/seeds/$name"
  mkdir -p "$workspace/remotes" "$workspace/seeds" "$workspace/clones"
  git init --bare --initial-branch=main "$bare" >/dev/null
  git clone -q "$bare" "$seed" 2>/dev/null
  configure_identity "$seed"
  printf 'initial\n' >"$seed/content.txt"
  git -C "$seed" add content.txt
  git -C "$seed" commit -qm initial
  git -C "$seed" push -q -u origin main
  git clone -q "$bare" "$workspace/clones/$name"
  configure_identity "$workspace/clones/$name"
  printf '%s\n' "$workspace/clones/$name"
}

mkdir -p "$workspace/fake-bin" "$workspace/runtime"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$workspace/fake-bin/notify-send"
cat >"$workspace/fake-bin/findmnt" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == "--mountpoint" && "${2:-}" == "${FINDMNT_EXPECTED:-}" ]] || exit 2
[[ "${FINDMNT_PRESENT:-0}" == 1 ]]
EOF
chmod 755 "$workspace/fake-bin/notify-send" "$workspace/fake-bin/findmnt"
export PATH="$workspace/fake-bin:$PATH"
export XDG_RUNTIME_DIR="$workspace/runtime"
export SYNC_CREDENTIAL_GUARD="$REPO_DIR/automation/.local/libexec/naldo/git-secret-guard"

ordinary="$(new_remote_clone ordinary)"
printf 'local ordinary change\n' >>"$ordinary/content.txt"
"$GENERIC_SYNC" --label ordinary "$ordinary" >"$workspace/ordinary.log" 2>&1 || {
  cat "$workspace/ordinary.log" >&2
  fail 'ordinary repository synchronization failed'
}
git --git-dir="$workspace/remotes/ordinary.git" show main:content.txt |
  grep -Fq 'local ordinary change' || fail 'ordinary change was not pushed'
[[ ! -e "$ordinary/sync.sh" ]] || fail 'ordinary repository unexpectedly needed sync.sh'
pass 'generic helper stages validates commits fetches rebases and pushes without repository-local scripts'

markers="$(new_remote_clone markers)"
printf '%s\n' '<<<<<<< HEAD' 'local' '=======' 'remote' '>>>>>>> other' >"$markers/conflict.txt"
if "$GENERIC_SYNC" --label markers "$markers" >"$workspace/markers.log" 2>&1; then
  fail 'leftover conflict markers unexpectedly synchronized'
fi
grep -Fq 'leftover conflict markers' "$workspace/markers.log" ||
  fail 'conflict-marker diagnostic missing'
! git --git-dir="$workspace/remotes/markers.git" cat-file -e main:conflict.txt 2>/dev/null ||
  fail 'conflict-marker file was pushed'
pass 'generic helper rejects staged conflict markers before commit or push'

credentials="$(new_remote_clone credentials)"
printf 'api_key=sk-%s\n' 'abcdefghijklmnopqrstuv' >"$credentials/private.env"
if "$GENERIC_SYNC" --label credentials "$credentials" >"$workspace/credentials.log" 2>&1; then
  fail 'credential-like content unexpectedly synchronized'
fi
grep -Fq 'credential check failed' "$workspace/credentials.log" ||
  fail 'credential-guard diagnostic missing'
! git --git-dir="$workspace/remotes/credentials.git" cat-file -e main:private.env 2>/dev/null ||
  fail 'credential-like file was pushed'
pass 'generic helper scans the complete staged index for credentials'

conflict="$(new_remote_clone conflict)"
printf 'local version\n' >"$conflict/content.txt"
other="$workspace/seeds/conflict"
printf 'remote version\n' >"$other/content.txt"
git -C "$other" add content.txt
git -C "$other" commit -qm remote-change
git -C "$other" push -q
if "$GENERIC_SYNC" --label conflict "$conflict" >"$workspace/conflict.log" 2>&1; then
  fail 'conflicting rebase unexpectedly succeeded'
fi
grep -Fq 'rebase stopped safely' "$workspace/conflict.log" ||
  fail 'safe rebase-conflict diagnostic missing'
[[ -d "$(git -C "$conflict" rev-parse --absolute-git-dir)/rebase-merge" ]] ||
  fail 'conflicting rebase state was not preserved for explicit recovery'
[[ "$(git --git-dir="$workspace/remotes/conflict.git" show main:content.txt)" == 'remote version' ]] ||
  fail 'conflicting local commit was pushed'
git -C "$conflict" rebase --abort
pass 'generic helper stops before push and preserves explicit recovery on conflict'

local_config="$workspace/config/naldo/sync/repositories.conf"
"$INIT_CONFIG" --config "$local_config" --template "$CONFIG_TEMPLATE" >"$workspace/init-one.log"
printf '\n# local sentinel\n' >>"$local_config"
cp "$local_config" "$workspace/config.before"
"$INIT_CONFIG" --config "$local_config" --template "$CONFIG_TEMPLATE" >"$workspace/init-two.log"
cmp -s "$local_config" "$workspace/config.before" || fail 'existing machine-local sync config was overwritten'
[[ "$(stat -c '%a' "$local_config")" == 600 ]] || fail 'machine-local sync config mode is not 0600'
grep -Fq 'Preserved machine-local sync configuration' "$workspace/init-two.log" ||
  fail 'preserved-config diagnostic missing'
pass 'machine-local sync configuration is initialized once and then preserved'

mapfile -t listed_tasks < <("$SYNC_ALL" --list-tasks)
[[ "${listed_tasks[*]}" == 'dotfiles notes wallpapers' ]] ||
  fail "unexpected task set: ${listed_tasks[*]}"
pass 'sync-all exposes exactly dotfiles notes and wallpapers tasks'

notes="$(new_remote_clone notes)"
wallpapers_laptop="$(new_remote_clone wallpapers-laptop)"
printf 'note update\n' >>"$notes/content.txt"
printf 'laptop wallpaper update\n' >>"$wallpapers_laptop/content.txt"

dotfiles="$workspace/fake-dotfiles"
mkdir "$dotfiles"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$dotfiles/sync.sh"
chmod 755 "$dotfiles/sync.sh"
config="$workspace/repositories.conf"
cat >"$config" <<EOF
dotfiles_enabled=true
dotfiles_path=$dotfiles
notes_enabled=true
notes_path=$notes
wallpapers_enabled=true
wallpapers_path=$wallpapers_laptop
WALLPAPERS_REQUIRED_MOUNT=
EOF
chmod 600 "$config"
NALDO_SYNC_CONFIG="$config" NALDO_GENERIC_SYNC="$GENERIC_SYNC" \
  "$SYNC_ALL" notes wallpapers >"$workspace/sync-all.log" 2>&1 || {
  cat "$workspace/sync-all.log" >&2
  fail 'sync-all generic notes/laptop-wallpapers run failed'
}
git --git-dir="$workspace/remotes/notes.git" show main:content.txt | grep -Fq 'note update' ||
  fail 'notes update was not pushed'
git --git-dir="$workspace/remotes/wallpapers-laptop.git" show main:content.txt |
  grep -Fq 'laptop wallpaper update' || fail 'laptop wallpaper update was not pushed'
[[ ! -e "$notes/sync.sh" && ! -e "$wallpapers_laptop/sync.sh" ]] ||
  fail 'ordinary repository-local scripts were introduced'
pass 'notes and a normal laptop wallpaper worktree use the generic synchronizer'

desktop_source="$(new_remote_clone wallpapers-desktop)"
desktop_mount="$workspace/desktop-mnt-data"
desktop_real="$desktop_mount/repos/Wallpapers"
desktop_link="$workspace/desktop-home-Wallpapers"
mkdir -p "$desktop_mount/repos"
mv -- "$desktop_source" "$desktop_real"
ln -s "$desktop_real" "$desktop_link"
printf 'desktop wallpaper update\n' >>"$desktop_link/content.txt"
desktop_config="$workspace/desktop-repositories.conf"
cat >"$desktop_config" <<EOF
dotfiles_enabled=true
dotfiles_path=$dotfiles
notes_enabled=false
notes_path=$notes
wallpapers_enabled=true
wallpapers_path=$desktop_link
WALLPAPERS_REQUIRED_MOUNT=$desktop_mount
EOF
chmod 600 "$desktop_config"
FINDMNT_PRESENT=1 FINDMNT_EXPECTED="$desktop_mount" \
  NALDO_SYNC_CONFIG="$desktop_config" NALDO_GENERIC_SYNC="$GENERIC_SYNC" \
  "$SYNC_ALL" wallpapers >"$workspace/desktop-wallpapers.log" 2>&1 || {
  cat "$workspace/desktop-wallpapers.log" >&2
  fail 'present wallpaper mount guard rejected the desktop worktree'
}
pass 'a present required mount permits wallpaper synchronization'
git --git-dir="$workspace/remotes/wallpapers-desktop.git" show main:content.txt |
  grep -Fq 'desktop wallpaper update' || fail 'symlinked desktop wallpaper update was not pushed'
[[ "$(readlink -f -- "$desktop_link")" == "$desktop_real" ]] ||
  fail 'desktop logical wallpaper path stopped resolving to the mounted worktree'
pass 'a symlinked desktop wallpaper worktree is synchronized through the stable logical path'

absent_mount="$workspace/absent-mnt-data"
absent_link="$workspace/absent-home-Wallpapers"
ln -s "$absent_mount/repos/Wallpapers" "$absent_link"
absent_config="$workspace/absent-mount.conf"
sed -e "s|^wallpapers_path=.*$|wallpapers_path=$absent_link|" \
  -e "s|^WALLPAPERS_REQUIRED_MOUNT=.*$|WALLPAPERS_REQUIRED_MOUNT=$absent_mount|" \
  "$config" >"$absent_config"
chmod 600 "$absent_config"
printf 'note update while wallpaper mount is absent\n' >>"$notes/content.txt"
if FINDMNT_PRESENT=0 FINDMNT_EXPECTED="$absent_mount" \
  NALDO_SYNC_CONFIG="$absent_config" NALDO_GENERIC_SYNC="$GENERIC_SYNC" \
  "$SYNC_ALL" notes wallpapers >"$workspace/absent-mount.log" 2>&1; then
  fail 'missing required wallpaper mount unexpectedly synchronized'
fi
grep -Fq "required wallpaper mount is not mounted: $absent_mount" "$workspace/absent-mount.log" ||
  fail 'missing required mount diagnostic absent'
[[ ! -e "$absent_mount" ]] || fail 'sync-all created content below an absent mount path'
pass 'a missing required mount fails without creating the mount point or repository'
git --git-dir="$workspace/remotes/notes.git" show main:content.txt |
  grep -Fq 'note update while wallpaper mount is absent' ||
  fail 'wallpaper mount failure prevented the independent notes task'
pass 'the wallpaper mount guard does not block another synchronization task'

ssd_source="$(new_remote_clone wallpapers-ssd-guard)"
ssd_mount="$workspace/unmounted-mnt-data"
ssd_real="$ssd_mount/repos/Wallpapers"
ssd_link="$workspace/ssd-home-Wallpapers"
mkdir -p "$ssd_mount/repos"
mv -- "$ssd_source" "$ssd_real"
ln -s "$ssd_real" "$ssd_link"
printf 'must remain local\n' >>"$ssd_real/content.txt"
ssd_head_before="$(git -C "$ssd_real" rev-parse HEAD)"
ssd_config="$workspace/ssd-guard.conf"
sed -e "s|^wallpapers_path=.*$|wallpapers_path=$ssd_link|" \
  -e "s|^WALLPAPERS_REQUIRED_MOUNT=.*$|WALLPAPERS_REQUIRED_MOUNT=$ssd_mount|" \
  "$config" >"$ssd_config"
chmod 600 "$ssd_config"
if FINDMNT_PRESENT=0 FINDMNT_EXPECTED="$ssd_mount" \
  NALDO_SYNC_CONFIG="$ssd_config" NALDO_GENERIC_SYNC="$GENERIC_SYNC" \
  "$SYNC_ALL" wallpapers >"$workspace/ssd-guard.log" 2>&1; then
  fail 'unmounted SSD fallback directory unexpectedly synchronized'
fi
[[ "$(git -C "$ssd_real" rev-parse HEAD)" == "$ssd_head_before" ]] ||
  fail 'guard failure committed inside the unmounted SSD directory'
git -C "$ssd_real" diff --cached --quiet ||
  fail 'guard failure staged content inside the unmounted SSD directory'
grep -Fq 'must remain local' "$ssd_real/content.txt" ||
  fail 'guard failure altered the unmounted SSD worktree'
! git --git-dir="$workspace/remotes/wallpapers-ssd-guard.git" show main:content.txt |
  grep -Fq 'must remain local' || fail 'guard failure pushed from the unmounted SSD directory'
pass 'the mount guard prevents writes beneath an unmounted desktop mount point'

sed 's/^notes_enabled=true$/notes_enabled=false/' "$config" >"$workspace/disabled.conf"
chmod 600 "$workspace/disabled.conf"
NALDO_SYNC_CONFIG="$workspace/disabled.conf" NALDO_GENERIC_SYNC="$GENERIC_SYNC" \
  "$SYNC_ALL" notes >"$workspace/disabled.log" 2>&1 || fail 'disabled task should skip successfully'
grep -Fq 'skipping notes (disabled' "$workspace/disabled.log" ||
  fail 'disabled task was not skipped explicitly'
pass 'disabled synchronization task is skipped explicitly'

sed "s|^notes_path=.*$|notes_path=$workspace/missing-notes|" "$config" >"$workspace/missing.conf"
chmod 600 "$workspace/missing.conf"
if NALDO_SYNC_CONFIG="$workspace/missing.conf" NALDO_GENERIC_SYNC="$GENERIC_SYNC" \
  "$SYNC_ALL" notes >"$workspace/missing.log" 2>&1; then
  fail 'enabled missing repository unexpectedly succeeded'
fi
grep -Fq 'enabled notes repository is missing' "$workspace/missing.log" ||
  fail 'enabled missing repository diagnostic absent'
pass 'enabled missing repository fails visibly'

printf '1..%d\n' "$checks"
