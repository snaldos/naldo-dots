# Dotfiles, machine profiles, and repository synchronization

## Ownership model

| Class | Authoritative location | Policy |
|---|---|---|
| Portable user configuration | `~/dotfiles` Stow package | Track reviewed source |
| Machine override | real file under deployed target | Preserve; initialize only when absent |
| Generated output | template/generator is authoritative | Ignore the output |
| Runtime or credentials | application state directory | Never track, print, or copy |
| Root-owned declarative config | `~/dotfiles/system/` | Install only through `install-system.sh` |

## GNU Stow repository

Declared packages are:

```text
ghostty fish starship herdr helix zathura yazi niri lazygit noctalia
pi desktop automation git
```

`assets`, `bootstrap`, `system`, and `tests` are explicitly non-Stow directories.
`deploy-links.sh` simulates the complete transaction and restows with
`--no-folding`. Any regular-file conflict, symlinked target parent, ignored state
in package sources, or Stow failure aborts; deployment never adopts or converts
an existing target automatically.

`install.sh` targets `$HOME`, selects `desktop` or `laptop`, serializes against
synchronization, initializes missing private/generated files, installs a
machine-local Git include, and reloads only the user unit inventory. It performs
no privileged operation or package transaction.

After adding, renaming, or deleting an individual tracked file, run
`./deploy-links.sh --dry-run` and then `./deploy-links.sh`. Its complete
`--restow` removes stale managed symlinks. Verify a deleted target with both
`test ! -e TARGET` and `test ! -L TARGET`, because a dangling symlink fails the
first test but passes the second. A remaining regular file is unmanaged and must
be inspected rather than adopted automatically.

Removing a whole package is explicit: unstow it while its source still exists
with `stow --dir="$HOME/dotfiles" --target="$HOME" --no-folding --delete PACKAGE`.
GNU Stow has no deployment database. Always retain `--no-folding` so target
directories stay real and generated/private files never live in package sources.

## Machine profile

`install.sh` requires `--profile desktop` or `--profile laptop` and renders
`~/.config/niri/machine.kdl` to include the matching tracked Niri fragment. That
selector is the only active profile state. The system keyd/udev integration is
shared and therefore has no profile option.

## Generated and private files

Noctalia credentials, Niri selectors/theme includes, Fish local overrides,
Starship's active config, Helix's generated base theme, Zathura colors, Pi active
settings, and synchronization paths are real target-side files. Existing content
is preserved. Pi credentials, trust, sessions, databases, logs, installed
packages, and Herdr-managed generated integration remain outside the Stow source.

## Repository synchronization

The machine-local file
`~/.config/naldo/sync/repositories.conf` controls paths and enabled state for
exactly three tasks:

```text
dotfiles
notes
wallpapers
```

`install.sh` or the first `sync-all` invocation copies the tracked example only
when the active file is absent. Disabled tasks are logged as skipped. Enabled
missing paths fail visibly.

Both profiles use `$HOME/Wallpapers`. The laptop worktree lives directly there
and leaves `WALLPAPERS_REQUIRED_MOUNT` empty. The desktop links it to
`/mnt/data/repos/Wallpapers` and sets the guard to `/mnt/data`. A nonempty guard
must be an actual mount according to `findmnt`, and the resolved worktree must be
below it, before synchronization can touch Git. The automation never creates or
mounts the physical path.

- Dotfiles retain `~/dotfiles/sync.sh` for Stow reconciliation and conditional
  user-unit reloads.
- Notes and wallpapers use the ordinary
  `~/.local/libexec/naldo/sync-git-repo`; they need no repository-local script.
- Both synchronizers lock locally, stage all changes, reject conflict markers,
  warn on other whitespace errors, scan the index for likely credentials,
  commit, fetch, rebase, and push. A rebase conflict stops before push.
- `sync-all` holds one cross-task runtime lock, continues after task failures,
  reports context, and exits nonzero if any enabled requested task fails.

The user timer remains disabled until `sync-control enable`. Its tracked schedule
has a startup delay, periodic interval, and randomized delay. A machine-local
unit drop-in can change the interval.

```bash
sync-control run
sync-control status
sync-control logs
sync-control pause
sync-control resume
sync-control disable
sync-control enable
sync-control interval 6h
sync-control reset-interval
```

These commands can mutate Git remotes or user service state. Status checks alone
are non-mutating; never run a synchronization as a validator.
