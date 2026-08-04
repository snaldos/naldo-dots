# Desktop and laptop wallpaper topology

Both profiles expose one portable logical repository path:

```text
$HOME/Wallpapers
```

Only the desktop maps that path onto its secondary HDD. The actual mount identity
and paths are machine-local: no concrete UUID, active `/etc/fstab` file, or
physical repository path is tracked. This runbook provides only a placeholder
entry and reviewed commands.

## Desktop: identify, test, and persist the HDD mount

1. Inspect model, serial, size, filesystem, label, and existing mounts without
   modifying anything:

   ```bash
   lsblk -o NAME,MODEL,SERIAL,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
   ```

2. Match the intended HDD using physical evidence. Do not select a device from
   its transient `/dev/sdX` letter alone. Record a suitable `/dev/disk/by-id/...`
   partition path in machine-local notes, not this repository.
3. Create the mount point and mount the verified partition explicitly. The token
   below is a placeholder, never a committed device identity:

   ```bash
   sudo install -d -m 0755 /mnt/data
   sudo mount /dev/disk/by-id/VERIFIED-HDD-PARTITION /mnt/data
   findmnt --mountpoint /mnt/data
   ```

4. After checking the mounted data and UUID, back up `/etc/fstab`, add one
   UUID-based ext4 entry, validate it, reload the generated systemd mount unit,
   and prove that an fstab-based remount works. Substitute only the UUID observed
   from the verified mount:

   ```bash
   findmnt --mountpoint /mnt/data -o TARGET,SOURCE,FSTYPE,UUID,OPTIONS
   backup="/etc/fstab.backup-before-mnt-data-$(date -u +%Y%m%dT%H%M%SZ)"
   sudo install -o root -g root -m 0644 /etc/fstab "$backup"
   sudoedit /etc/fstab
   ```

   Add exactly one machine-local line:

   ```text
   UUID=VERIFIED-HDD-UUID /mnt/data ext4 defaults,nofail,x-systemd.device-timeout=10s,x-systemd.mount-timeout=30s 0 2
   ```

   Then validate and test without formatting or recreating the filesystem:

   ```bash
   sudo findmnt --verify --verbose --tab-file /etc/fstab
   sudo systemctl daemon-reload
   sync
   sudo umount /mnt/data
   sudo mount /mnt/data
   findmnt --mountpoint /mnt/data -o TARGET,SOURCE,FSTYPE,UUID,OPTIONS
   systemctl status mnt-data.mount
   ```

   `nofail` and the bounded device/mount waits keep an absent or unhealthy
   optional HDD from indefinitely blocking boot. The ext4 inode ownership and
   permissions remain on the existing filesystem.

5. Only after `findmnt` succeeds, create the parent directory with deliberate
   ownership, clone the repository, and initialize its local LFS hook:

   ```bash
   sudo install -d -o "$USER" -g "$(id -gn)" -m 0755 /mnt/data/repos
   git clone GIT-WALLPAPERS-REMOTE /mnt/data/repos/Wallpapers
   git -C /mnt/data/repos/Wallpapers lfs install --local
   git -C /mnt/data/repos/Wallpapers lfs pull
   git -C /mnt/data/repos/Wallpapers lfs fsck
   ```

6. Confirm `$HOME/Wallpapers` does not already contain data, then create the
   stable logical link:

   ```bash
   ln -s /mnt/data/repos/Wallpapers "$HOME/Wallpapers"
   readlink -f "$HOME/Wallpapers"
   ```

The dotfiles never create `/mnt/data`, `/mnt/data/repos`, or the wallpaper
worktree. They never mount the HDD or edit `/etc/fstab`. If `/mnt/data` is merely
an ordinary directory on the SSD because the HDD is absent, synchronization must
stop before staging or writing there.

Set this machine-local line in the real mode-`0600` file
`~/.config/naldo/sync/repositories.conf`:

```text
wallpapers_path=~/Wallpapers
WALLPAPERS_REQUIRED_MOUNT=/mnt/data
```

The guard uses `findmnt --mountpoint /mnt/data`, resolves the logical symlink only
after that check passes, and requires the physical worktree to be below the
mounted path.

## Laptop: direct SSD worktree

The laptop has no `/mnt/data` assumption and no external mount:

```bash
git clone GIT-WALLPAPERS-REMOTE "$HOME/Wallpapers"
git -C "$HOME/Wallpapers" lfs install --local
git -C "$HOME/Wallpapers" lfs pull
git -C "$HOME/Wallpapers" lfs fsck
```

Its machine-local configuration is:

```text
wallpapers_path=~/Wallpapers
WALLPAPERS_REQUIRED_MOUNT=
```

An existing configuration created before the guard was added is interpreted as
an empty guard, preserving laptop behavior.

## Verification before enabling periodic sync

Desktop:

```bash
findmnt --mountpoint /mnt/data
readlink -f "$HOME/Wallpapers"
git -C "$HOME/Wallpapers" status --short --branch
git -C "$HOME/Wallpapers" lfs fsck
sync-all wallpapers
```

Laptop:

```bash
test ! -L "$HOME/Wallpapers"
git -C "$HOME/Wallpapers" status --short --branch
git -C "$HOME/Wallpapers" lfs fsck
sync-all wallpapers
```

`sync-all wallpapers` can commit, fetch, rebase, and push; run it only as the
explicit manual synchronization test. Test dotfiles and notes separately. Enable
`sync-all.timer` only after all three manual tasks pass.
