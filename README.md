# Dotfiles

Linux-oriented workstation configuration targeting Fedora Workstation and a
GDM → Niri → Noctalia session. Portable user files are explicit GNU Stow
packages whose contents mirror paths under `$HOME`.

![Niri desktop with Helix, Pi, and the Noctalia control center](assets/screenshots/desktop-overview.png)

## Boundaries

Responsibilities are deliberately separate:

1. `install.sh` deploys **user configuration only** to `$HOME` with GNU Stow.
2. `install-system.sh` installs only reviewed root-owned keyd mapping and
   Noctalia input-device rule from `system/`.
3. `naldo-update` manually updates software already managed by available local
   providers; it has no package inventory.
4. `bootstrap/fedora/` is a reusable human-run clean-install guide and curated
   selected-software inventory, not a complete system snapshot or reconciler.

Neither installer configures the login manager, base GNOME desktop, boot loader,
initramfs, graphics drivers, repositories, mirrors, or operating-system updates.

## User installation

Install prerequisites first using the reviewed Fedora manifests, then run:

```bash
./install.sh --profile desktop
./install.sh --profile laptop
```

The profile is mandatory: it selects one of the two real Niri hardware
configurations without another profile layer.

`install.sh` requires Git, GNU Stow, locking, systemd user tools, and Helix. It
serializes against synchronization, runs the complete Stow preflight, and
restows every declared package with `--no-folding`. It initializes missing
machine-local Niri, Noctalia, Fish, Helix, Starship, Zathura, Pi, Git-include,
and repository-sync files while preserving existing private/generated content.
It never invokes sudo or a package manager.

Fedora provides Helix as `hx`. All durable consumers use that command, and the
installer requires native `hx` before changing the target home.

### Stow safety

Declared Stow packages are:

```text
ghostty fish starship herdr helix zathura yazi niri lazygit noctalia
xdg-desktop-portal pi desktop automation git
```

`assets`, `bootstrap`, `system`, and `tests` are explicitly non-Stow. Deployment
simulates the complete `--no-folding --restow` transaction first. Any existing
regular-file conflict, symlinked target parent, ignored state in a package
source, or Stow error aborts without automatic adoption or file conversion.

```bash
./deploy-links.sh --dry-run
./deploy-links.sh
./tests/deploy-links-test.sh
```

Target directories remain real, tracked files are individual links, and private
or generated files remain physically outside package sources.

## Root-owned keyd/Noctalia input integration

The shared keyd mapping and exact Bongo Cat udev rule are tracked under
`system/keyd/` and `system/udev/`:

```bash
./install-system.sh --dry-run
sudo ./install-system.sh
```

The installer requires keyd, validates both sources, and writes only
`/etc/keyd/default.conf` and
`/etc/udev/rules.d/69-keyd-bongocat.rules`. It does not reload udev, restart
keyd, or trigger devices. Read `system/keyd/README.md` for the stable device,
`uaccess`, explicit activation, verification, panic sequence, and TTY recovery.

## Repository synchronization

Exactly three repositories are supported:

- dotfiles through normal Git;
- second-brain notes through normal Git plus narrow attachment-only LFS rules;
- wallpapers with compressed image payloads in Git LFS.

Fedora's `git-lfs` package supplies the filters. Notes and Wallpapers require a
repository-local LFS pre-push hook and a successful `git lfs fsck` before the
timer is enabled.

Machine-local paths and enabled state live in the real mode-`0600` file
`~/.config/naldo/sync/repositories.conf`. `install.sh` or the first `sync-all`
run copies the tracked example only when this active file is absent. An enabled
missing repository fails visibly; a disabled task is logged as skipped.

Both profiles use `$HOME/Wallpapers`. The laptop clones directly there and leaves
`WALLPAPERS_REQUIRED_MOUNT` empty. The desktop links that logical path to
`/mnt/data/repos/Wallpapers` and sets `WALLPAPERS_REQUIRED_MOUNT=/mnt/data`.
Before wallpaper synchronization, `sync-all` proves the guard is an actual mount
with `findmnt` and that the resolved worktree is below it. It never creates or
mounts `/mnt/data`; see `bootstrap/fedora/WALLPAPERS.md`.

`sync.sh` remains dotfiles-specific because it reconciles Stow links and reloads
changed user-unit inventory. Notes and wallpapers use the generic
`~/.local/libexec/naldo/sync-git-repo` and need no workstation-specific script.
Both paths preserve local locking, conflict-marker validation, credential
scanning, commit, fetch/rebase/push behavior, and safe failure before push on a
rebase conflict.

The user timer is installed but remains disabled until explicitly enabled. Its
tracked schedule uses a 10-minute user-manager startup delay, a 30-minute
interval, and a 2-minute randomized delay.

```bash
sync-control enable
sync-control pause
sync-control resume
sync-control interval 6h
sync-control run
sync-control status
sync-control logs
sync-control disable
```

The Noctalia scripts menu exposes only repository synchronization and a local
Noctalia config export. Operating-system maintenance is intentionally absent.

## Workstation maintenance

`naldo-update` is deployed from the shared `automation` Stow package and must be
invoked manually. It updates only already-managed local software, never runs
repository synchronization, and does not read the Fedora clean-install
manifests. See [`MAINTENANCE.md`](MAINTENANCE.md) for its provider order and the
manual policy for Git-tagged Cargo tools.

## Zen Flatpak

Zen has one supported identity:

```text
Flatpak: app.zen_browser.zen
Desktop: app.zen_browser.zen.desktop
Command: flatpak run app.zen_browser.zen
```

The Niri application menu invokes that command directly; MIME associations use
the Flatpak desktop file. On the selected installation, Niri reports the live
Wayland app ID `app.zen_browser.zen`; desktop-file `StartupWMClass` metadata is
not authoritative. Reconfirm the runtime identity after installation without
printing browser titles:

```bash
niri msg -j windows | jq -r '.[].app_id' | sort -u
```

The matching Niri rules document where to update that evidence if upstream
changes it.

## Editor and private state

Helix (`hx`) is the primary editor for Fish, Git, LazyGit, Yazi, Herdr, Pi, and
text MIME handling. The tracked Git include contains behavior only; identity,
signing, credentials, and trust stay in machine-local Git configuration.
Neovim remains unconfigured and outside Stow.

Noctalia-rendered themes, Niri selectors, Fish local overrides, Starship's active
config, Helix's generated base theme, Zathura colors, sync paths, and Pi active
settings are real machine-local files. The installer seeds safe Ghostty and
Helix themes plus an empty Zathura color include; Niri skips its optional
Noctalia include and Yazi uses defaults until the local shell renders them. Pi credentials, sessions, trust, DBs,
logs, installed packages, and Herdr-managed generated integration state are
ignored and absent from package sources. Existing `~/.pi/agent/settings.json`
is never overwritten; `settings.default.json` seeds only a missing file and uses
`hx` for a fresh Fedora account.

## Fedora bootstrap and verification

For a migration, later clean install, or occasional Fedora audit, start with
`bootstrap/fedora/CLEAN-INSTALL.md`. After Fedora is installed on the laptop,
`bootstrap/fedora/LAPTOP-SETUP.md` is the profile-specific execution checklist.
Both derive software from the same six profile-aware provider manifests and
link the editor-tool, remote-access, and wallpaper runbooks. After
installing selected dependencies and running the user installer:

```bash
./bootstrap/fedora/verify.sh --profile desktop  # or laptop
./tests/run-tests.sh
```

The verifier reports missing RPM/provider ownership, commands, desktop/session
files, Flatpak IDs and packaged integration commands, configured font families,
tracked user outputs, and units. Results
use `session`, `feature`, `optional`, or `development` classification. It
performs no network or package operation.
