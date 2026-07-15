# Dotfiles, Machine Profiles, Synchronization, and Snapshots

## Ownership Model

Classify a file before editing or backing it up:

| Class | Authoritative location | Policy |
|---|---|---|
| Portable user configuration | `~/dotfiles` | Track in the appropriate GNU Stow package |
| Machine override | ignored file under the deployed path | Keep local; provide a tracked example/default when useful |
| Generated output | owning template or generator | Track the durable source, ignore the output |
| Runtime or credentials | application state directories | Do not track, print, or copy into snapshots |
| System reconstruction state | `~/backups/snapshot` | Capture only through the allowlisted snapshot script |

Do not duplicate Stow-managed configuration in the backup repository. Do not
turn generated theme output into a portable source merely because it currently
exists.

## GNU Stow Repository

The canonical public repository is `~/dotfiles`, with these packages:

```text
ghostty fish starship herdr nvim zathura yazi fuzzel hypr lazygit
noctalia pi desktop automation
```

Important entry points:

- `~/dotfiles/install.sh`: initializes/validates the machine profile, restows
  all packages, initializes machine-local Pi settings when absent, and reloads
  the user-systemd unit inventory.
- `~/dotfiles/sync.sh`: stages all non-ignored changes, checks whitespace,
  commits, fetches/rebases `origin/main`, and pushes.
- `~/dotfiles/README.md`: concise deployment and synchronization instructions.

`sync.sh` is a Git/network mutation, not a validator. Do not invoke it unless a
commit and push are explicitly authorized. Before editing a live path, resolve
its source with `readlink -f`; Stow may link either a file or a parent directory.
Never use `stow --adopt` without first reviewing every resulting source change.

Preferred dry run:

```bash
packages=(ghostty fish starship herdr nvim zathura yazi fuzzel hypr lazygit noctalia pi desktop automation)
stow -d "$HOME/dotfiles" -t "$HOME" -n --verbose=2 -R "${packages[@]}"
```

Neovim's local repository metadata under `~/.config/nvim/.git` is machine-local;
do not import it into the outer dotfiles repository.

## Canonical Machine Profile

The active machine-local file is outside every Git repository:

```text
~/.config/naldo/machine-profile
```

It contains exactly one enum value, `desktop` or `laptop`. Dotfiles track only
`machine/profiles`, `machine/profile.default`, and documentation. The installer
migrates the former Hyprland-local file and accepts an explicit override such as
`MACHINE_PROFILE=laptop ./install.sh`.

The profile controls portable machine behavior, currently including:

```text
desktop -> XKB layout gb
laptop  -> XKB layout us
```

Each machine independently clones its private snapshot repository at
`~/backups`; Git history and `origin` determine whether it is the desktop or
laptop backup. The backup is not the authority for the live profile. During
migration, consumers may temporarily accept the old Hyprland profile and
`backups-$profile` paths.

## Generated Themes and Active Settings

All durable Noctalia user-template inputs live under:

```text
~/.config/noctalia/templates/
```

Configured outputs currently cover Fuzzel, Ghostty, Neovim, Pi, Starship,
Yazi, and Zathura; builtin/community templates also cover selected desktop
components. Read `[theme.templates]` in the active Noctalia config for the exact
current list.

Rendered outputs are ignored. Supported absence behavior is intentional:

- Ghostty optionally loads its generated theme fragment.
- Hyprland conditionally requires generated `noctalia.lua`.
- Neovim defaults to Tokyo Night; `theme.lua` explicitly selects
  `tokyonight`, `matugen`, or `base16`.
- Fish selects generated Starship config when present and the tracked base
  config otherwise.
- Fuzzel, Yazi, and Zathura use application defaults until outputs are rendered.
- Pi selects Noctalia only when its generated theme is discoverable and
  otherwise selects built-in `dark`.

Pi's active `~/.pi/agent/settings.json` is ignored because live theme changes
rewrite it. `settings.default.json` is the tracked durable default. Never add the
active file back to Git.

## Repository Synchronization

Each repository has a standalone `sync.sh`:

```text
~/dotfiles
~/backups
~/Vaults/second-brain
~/Wallpapers
```

`~/.local/bin/sync-all` invokes all four, continues after an individual failure,
and exits nonzero if any task failed. `sync-all.service` is a oneshot user unit;
being `inactive` after completion is normal.

There is one periodic user timer: `sync-all.timer`. The tracked default is
30 minutes, with an initial boot/login delay and small randomized delay. A
1-minute interval exists only for temporary testing.

```bash
sync-control run             # asynchronous run now
sync-control status          # timer, next run, and last service result
sync-control logs            # recent journal
sync-control pause           # current login session only
sync-control resume
sync-control disable         # persistent across logins
sync-control enable
sync-control interval 6h     # persistent on this machine, ignored by Git
sync-control reset-interval  # return to tracked default
```

The interval override is
`~/.config/systemd/user/sync-all.timer.d/interval.conf`. It is machine-local and
does not propagate between desktop and laptop. Successful and failed runs send
notifications with status/log commands.

Detailed verification:

```bash
journalctl --user -u sync-all.service -n 150 --no-pager
systemctl --user show sync-all.service -p Result -p ExecMainStatus
systemctl --user list-timers sync-all.timer --all --no-pager

for repo in "$HOME/dotfiles" "$HOME/backups" "$HOME/Vaults/second-brain" "$HOME/Wallpapers"; do
  git -C "$repo" status --short
  git -C "$repo" rev-list --left-right --count HEAD...@{u}
done
```

An empty status and `0 0` divergence indicate clean local/upstream tracking refs.
A fresh remote check additionally requires an authorized `git fetch`.

## Machine Snapshot

`~/backups` is a private Git repository whose current tree contains:

```text
.gitignore
README.md
sync.sh
snapshot/
```

The allowlisted snapshot covers reconstruction-relevant package manifests,
boot configuration, selected `/etc` and `/usr/local` configuration, systemd
state, keyd and udev rules, greetd/Noctalia-greeter state, HyprPM state, and
non-secret Noctalia settings/plugin manifests. It intentionally excludes
portable dotfiles, browser profiles, histories, caches, logs, UKIs/EFI binaries,
private keys, network credentials, Pi credentials, and Noctalia's
credential-bearing `state.toml`.

```bash
~/backups/sync.sh --local  # regenerate without Git/network mutation
~/backups/sync.sh          # regenerate, commit, rebase, push
~/backups/sync.sh --sudo   # additionally read protected allowlisted files
```

Do not use `--sudo` without explicit authorization. An unprivileged run keeps a
previous protected snapshot when the source still exists but is unreadable.
Restore by reviewing file-by-file differences and recorded metadata, never by
copying the entire snapshot over a new installation.

## Migration Rule

For a new machine, stop legacy timers first, archive conflicting repositories
and live configs outside all Git trees, clone canonical repositories, create the
machine-local profile, resolve Stow conflicts explicitly, and retain the
archive until the user authorizes deletion. Do not replace unique uncommitted
notes or wallpapers with a clone.
