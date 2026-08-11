# Fedora KDE Plasma Desktop bootstrap

This directory is a reusable, human-run Fedora clean-install guide, curated
installation inventory, and read-only verifier. It supports desktop and laptop
fresh installations, later clean installations, and occasional audits when
Fedora, providers, or system requirements change.

The manifests list software deliberately selected for a clean installation.
Fedora's `kde-desktop` comps group additionally owns Plasma's complete,
release-specific desktop closure; `dnf-packages.tsv` records its required
verification anchors rather than duplicating every group member. The manifests
are not a snapshot of every installed package, a record of transitive
dependencies, an automatic desired-state reconciler, the normal update
mechanism, or a requirement that desktop and laptop contain identical software.
Repository scripts do not install packages, enable repositories, switch the
display manager, remove desktops, change graphics, mount storage, activate
SSH/Tailscale, or authenticate services. System-changing commands remain
explicit clean-install steps for a human to review and run. Start with
[`CLEAN-INSTALL.md`](CLEAN-INSTALL.md) and the desktop boundary in
[`DESKTOPS.md`](DESKTOPS.md).

```text
Fedora boot → Plasma Login Manager → package-provided Niri → Noctalia  (primary)
                                  └→ package-provided Plasma  (full fallback)

GNOME Shell/session and GDM are absent. GNOME Keyring, GCR, GNOME/GTK portals,
Nautilus, and useful GNOME/GTK application infrastructure remain installed.
```

## Curated clean-install manifests

Each selected item and expected executable, desktop file, or unit is recorded
once for its chosen provider:

| File | Selected clean-install scope |
|---|---|
| `dnf-packages.tsv` | official Fedora package anchors, classification, executables, desktop files, units |
| `flatpaks.tsv` | required/optional Flathub IDs, packaged integration commands, and exported desktop files |
| `npm-packages.tsv` | user-prefix npm packages and exported commands |
| `uv-tools.tsv` | user-level Python tools and clean-provisioning activation policy |
| `cargo-tools.tsv` | deliberately pinned stable Cargo commands and update/uninstall route |
| `external-tools.tsv` | vendor/COPR providers, upstream installers/releases, CLI/editor extensions, RPM Fusion, and user fonts |

Each manifest has one final `profile` field. `all` applies to both machines;
`desktop` and `laptop` apply only to that explicit profile. Shared rows remain in
one file rather than branches or duplicated manifests. Currently NVIDIA is the
only selected profile-specific software row (`desktop`); no laptop-only tool has
been invented without a real selection. The desktop HDD wallpaper topology
remains profile-specific runbook documentation rather than a fictitious software
row.

The verifier reads these six files directly. There is no second command,
desktop-file, or service inventory to keep synchronized. Tracked user
executables and synchronization units are discovered from their Stow sources.

For `uv-tools.tsv`, `active` means install the tool on a clean machine; it does
not mean every installed language server is attached globally in Helix. The
Helix mapping remains authoritative for buffer-level activation.

Classifications:

- `session`: necessary for the selected PLM → Niri/Noctalia or Plasma sessions;
- `feature`: required by an intentionally configured workflow;
- `optional`: supported but deliberately non-default;
- `development`: research/development tooling that does not gate the desktop.

TSV list fields use commas and `-` for no output. Desktop specifications are
`application:FILE` or `wayland:FILE`; units are `user:UNIT` or `system:UNIT`.
Flatpak integration commands name executables packaged inside the application,
not host wrappers. The final profile is exactly `all`, `desktop`, or `laptop`.

Source terminology is literal: official Fedora repository,
upstream-documented third-party COPR, reviewed community COPR, official vendor
repository, official upstream installer/release/tagged source, reviewed GitHub
CLI extension, official VS Code extension, and Flathub application. COPR is
Fedora-hosted build infrastructure; no individual COPR is an official Fedora
package source. The existing desktop-only RPM Fusion row remains an explicitly
reviewed third-party repository rather than being mislabeled as one of those
sources.

## Selected sources

- Official Fedora DNF supplies the KDE Plasma Desktop Edition identity/defaults,
  complete `kde-desktop` group, Plasma Login Manager, Niri, Noctalia, and all
  selected GNOME/GTK infrastructure. Fedora also supplies both sessions'
  PAM/keyring and portal integration, OpenSSH clients, GitHub CLI, GCR, Git LFS,
  desktop applications, Helix, Node/npm, uv, Rust/Cargo, and build prerequisites.
  An inbound OpenSSH server is not selected.
- Flathub supplies Zen, Discord, Obsidian, the sole GPU Screen Recorder provider,
  and Sioyek. Vesktop is the only optional application alternative.
- Google Chrome uses Google's signed RPM repository. Visual Studio Code uses
  Microsoft's signed RPM repository as a minimal scientific fallback, with only
  Python, Jupyter, and Ruff selected directly from the extension marketplace.
- GitHub CLI comes from Fedora; `gh-dash` is a reviewed community extension
  managed by `gh` and authenticated through the system keyring.
- Tailscale uses its stable official vendor repository.
- Ghostty, Yazi, and keyd use reviewed community COPRs. LazyGit and Starship use
  upstream-documented third-party COPRs; DNF owns both.
- Herdr and Tuicr use reviewed official installers and machine-local ownership
  receipts. Tuicr is compared with a checksum-verified release. Pixi uses its
  official installer and dedicated `~/.pixi/bin`; `naldo-update` invokes its
  official self-updater only at that path. Conda is not selected beside it.
- Marksman uses a pinned, checksum-verified official upstream release under
  `~/.local/bin`; it is unavailable from Fedora 44's enabled DNF repositories.
- Noctalia owns clipboard history; Fedora `wl-clipboard` supplies CLI transfer.
- npm and uv are rolling except for `typescript@6`, which retains the `tsserver`
  API required by the selected LSP. Cargo tags/versions record reviewed routes;
  Tinymist, Markdown Oxide, Marksman, and Nerd Font replacements remain manual.
  `naldo-update` reports their latest GitHub releases without downloading them.
- NVIDIA uses current RPM Fusion instructions on the desktop only.

Fedora 44 package names and identities were audited for this release. Before a
later installation or audit, review the manifests and runbooks against the
actual Fedora release, current providers, and current system choices. Do
not invent missing package names or add fallback providers.

## Policy runbooks

| File | Purpose |
|---|---|
| `CLEAN-INSTALL.md` | single complete desktop/laptop profile-aware execution sequence |
| `DESKTOPS.md` | KDE-Edition/Niri/Plasma topology, PLM/KWallet, portals, and recovery |
| `EDITOR-TOOLS.md` | Helix/VS Code responsibilities, provider boundaries, and health checks |
| `REMOTE-ACCESS.md` | OpenSSH agents, manual Plasma key loading, Tailscale trust, and private state |
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
and packaged integration commands, official-installer receipts, selected GitHub
CLI/VS Code extensions, units, configured fonts, and tracked user outputs. It
performs no network request, transaction, authentication, mount, service
activation, or private-key read.
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
[`../../system/keyd/README.md`](../../system/keyd/README.md) before the separate,
explicit udev/keyd activation.
