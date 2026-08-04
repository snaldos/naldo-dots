# Fedora Workstation bootstrap

This directory is a reusable, human-run Fedora clean-install guide, curated
installation inventory, and read-only verifier. It supports the current desktop
migration, the following laptop migration, later clean installations, and
occasional audits when Fedora, providers, or workstation preferences change.

The manifests list software deliberately selected for a clean installation.
They are not a snapshot of every installed package, a record of transitive
dependencies, an automatic desired-state reconciler, the normal update
mechanism, or a requirement that desktop and laptop contain identical software.
Repository scripts do not install packages, enable repositories, configure GDM,
change graphics, mount storage, activate SSH/Tailscale, or authenticate services;
system-changing commands remain explicit steps for a human to review and run.
Start with [`CLEAN-INSTALL.md`](CLEAN-INSTALL.md).

```text
Fedora boot → GDM → package-provided Niri session → Noctalia
```

## Curated clean-install manifests

Each selected item and expected executable, desktop file, or unit is recorded
once for its chosen provider:

| File | Selected clean-install scope |
|---|---|
| `dnf-packages.tsv` | official Fedora package, classification, executables, desktop files, units |
| `flatpaks.tsv` | required/optional Flathub IDs, packaged integration commands, and exported desktop files |
| `npm-packages.tsv` | user-prefix npm packages and exported commands |
| `uv-tools.tsv` | user-level Python tools and active/inactive policy |
| `cargo-tools.tsv` | deliberately pinned stable Cargo commands and update/uninstall route |
| `external-tools.tsv` | vendor repositories, precisely classified reviewed COPRs, official upstream installers/releases, RPM Fusion, and user fonts |

Each manifest has one final `profile` field. `all` applies to both machines;
`desktop` and `laptop` apply only to that explicit profile. Shared rows remain in
one file rather than branches or duplicated manifests. Currently NVIDIA is the
only selected profile-specific software row (`desktop`); no laptop-only tool has
been invented without a real selection. The desktop HDD wallpaper topology
remains profile-specific runbook documentation rather than a fictitious software
row.

The verifier reads these six files directly. There is no second command,
desktop-file, or service inventory to keep synchronized. Tracked user
executables, the Yazi desktop entry, and synchronization units are discovered
from their Stow sources.

Classifications:

- `session`: necessary for GDM → Niri → Noctalia;
- `feature`: required by an intentionally configured workflow;
- `optional`: supported but deliberately non-default;
- `development`: research/development tooling that does not gate the desktop.

TSV list fields use commas and `-` for no output. Desktop specifications are
`application:FILE` or `wayland:FILE`; units are `user:UNIT` or `system:UNIT`.
Flatpak integration commands name executables packaged inside the application,
not host wrappers. The final profile is exactly `all`, `desktop`, or `laptop`.

Source terminology is literal: official Fedora repository,
upstream-documented third-party COPR, reviewed community COPR, official vendor
repository, official upstream installer, official upstream release, official
upstream tagged source, and Flathub application. COPR is Fedora-hosted build
infrastructure; no individual COPR is an official Fedora package source. The
existing desktop-only RPM Fusion row remains an explicitly reviewed third-party
repository rather than being mislabeled as one of those sources.

## Selected sources

- Official Fedora DNF supplies the base session, OpenSSH, GCR's shared SSH-agent
  socket, Git LFS, desktop applications, Helix (`hx`), Node/npm, uv, Rust/Cargo,
  `evtest`, and build prerequisites.
- Flathub supplies required Zen, official Discord, Obsidian, the sole GPU
  Screen Recorder provider, and the explicitly selected community-maintained
  Sioyek PDF viewer. Vesktop is the only optional application alternative. No
  native second copy of GPU Screen Recorder is selected.
- Google Chrome uses Google's signed RPM and resulting official vendor repository
  as a selected secondary browser.
- Tailscale uses Tailscale's stable official vendor repository.
- Ghostty, Yazi, and keyd use reviewed community COPRs. LazyGit and Starship use
  distinct upstream-documented third-party COPRs; DNF owns both.
- Herdr uses a reviewed local execution of the official upstream installer and
  its stable self-update channel. Pixi is selected through the same
  download-inspect-execute discipline using its official installer and dedicated
  `~/.pixi/bin` path.
- Noctalia v5 provides clipboard history and closed-application persistence;
  Fedora `wl-clipboard` supplies `wl-copy` and `wl-paste`.
- npm and uv tools are rolling user tools. Cargo versions/tags remain explicit
  because the clean-install commands record reviewed stable routes, not the
  routine update policy. `naldo-update` updates ordinary registry binaries.
  Tinymist and Markdown Oxide use official upstream tagged sources and remain
  deliberate manual updates in [`MAINTENANCE.md`](../../MAINTENANCE.md).
- NVIDIA uses current RPM Fusion instructions on the desktop only.

Fedora 44 package names and identities were audited for this release. Before a
later installation or audit, review the manifests and runbooks against the
actual Fedora release, current providers, and current workstation choices. Do
not invent missing package names or add fallback providers.

## Policy runbooks

| File | Purpose |
|---|---|
| `CLEAN-INSTALL.md` | canonical ordered fresh-install sequence |
| `LAPTOP-SETUP.md` | complete laptop-only command-by-command execution path after Fedora is installed |
| `EDITOR-TOOLS.md` | Helix responsibilities, installation commands and health checks |
| `REMOTE-ACCESS.md` | OpenSSH/Tailscale trust, private state and manual activation |
| `WALLPAPERS.md` | desktop HDD guard and laptop direct worktree |
| `verify.sh` | read-only installed package/output report |

Application policy is represented by `dnf-packages.tsv`, `flatpaks.tsv`,
`external-tools.tsv`, and the tracked `mimeapps.list`, rather than a duplicated
Markdown matrix.

## Read-only verification

After installing dependencies and running `install.sh`, select the same explicit
profile used by the clean-install guide:

```bash
./bootstrap/fedora/verify.sh --profile desktop
./bootstrap/fedora/verify.sh --profile laptop
```

The verifier checks only rows marked `all` or matching the selected profile,
plus shared tracked user outputs. It checks RPM package presence and selected
external RPM ownership, manifest-declared commands, desktop files, Flatpak IDs
and packaged integration commands, official-installer ownership where defined,
unit files, configured font families, and tracked user outputs. It performs no
network request, transaction, authentication, mount, service activation, or
private-key read.
Missing applicable `session`/`feature` entries fail; optional/development entries
are reported only.

## Root-owned keyd boundary

Bongo Cat explicitly reads `/dev/input/by-id/keyd-virtual-kbd`; current Noctalia
does not auto-detect it. After installing keyd from its reviewed COPR:

```bash
./install-system.sh --dry-run
sudo ./install-system.sh
```

This installs only `/etc/keyd/default.conf` and the exact udev rule creating the
stable keyd virtual-keyboard symlink with `uaccess`. Read
`system/keyd/README.md` before the separate, explicit udev/keyd activation.
