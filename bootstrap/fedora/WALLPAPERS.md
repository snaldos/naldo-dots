# Desktop and laptop wallpaper topology

Both profiles expose one portable logical repository path:

```text
$HOME/Wallpapers
```

Only the desktop maps that path onto its secondary HDD. Mount identity and paths
are machine-local; no UUID, `/etc/fstab` entry, mount command, or physical
repository path is stored in portable runtime configuration.

## Desktop: identify and mount the HDD manually

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

4. Only after `findmnt` succeeds, create the parent directory with deliberate
   ownership and clone the repository:

   ```bash
   sudo install -d -o "$USER" -g "$(id -gn)" -m 0755 /mnt/data/repos
   git clone GIT-WALLPAPERS-REMOTE /mnt/data/repos/Wallpapers
   ```

5. Confirm `$HOME/Wallpapers` does not already contain data, then create the
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
sync-all wallpapers
```

Laptop:

```bash
test ! -L "$HOME/Wallpapers"
git -C "$HOME/Wallpapers" status --short --branch
sync-all wallpapers
```

`sync-all wallpapers` can commit, fetch, rebase, and push; run it only as the
explicit manual synchronization test. Test dotfiles and notes separately. Enable
`sync-all.timer` only after all three manual tasks pass.
