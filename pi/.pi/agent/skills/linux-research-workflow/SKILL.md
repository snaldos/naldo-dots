---
name: linux-research-workflow
description: "Inspect, debug, validate, migrate, or configure Naldo's Arch Linux desktop/laptop: GNU Stow dotfiles, centralized Git synchronization and machine snapshots, Hyprland Lua/hl and plugins, native Noctalia v5, systemd/systemd-boot, Wayland/UWSM, Herdr/Tailscale, Ghostty, Fish, Neovim, Starship, Fuzzel, Yazi, Zen, packages, and scientific tooling."
compatibility: "Arch Linux; Hyprland 0.55+ Lua configuration; native Noctalia v5 beta; GNU Stow; UWSM/systemd-user; Fish interactive shell; Bash automation; Ghostty; Neovim/LazyVim; Herdr; Tailscale."
---

# Linux Research Workstation

## Verified Architecture, Not Assumptions

Treat this as a current profile that must still be inspected:

- rolling Arch Linux; installed versions, help, schemas, and package files are authoritative
- Hyprland 0.55+ with Lua configuration and embedded `hl`, normally under UWSM/systemd-user
- HyprPM `scrolloverview`, configured by `hyprland/plugins.lua` when loaded
- native Noctalia v5 beta invoked as `noctalia`, not the old Quickshell/QML shell
- Ghostty, Fish, Starship, Neovim/LazyVim, Fuzzel, Yazi, Zen Browser, and Herdr
- portable user config in the public GNU Stow repository `~/dotfiles`
- one ignored `desktop|laptop` machine profile controlling Hyprland defaults and `~/backups-$profile`
- one `sync-all.timer` orchestrating dotfiles, machine snapshot, notes, and wallpapers
- Noctalia templates as durable theme sources; rendered outputs remain ignored
- Tailscale for possible remote access and systemd-boot with a UKI, both subject to re-verification

## Load the Matching Reference

Before nontrivial diagnosis or editing, read only the relevant guide:

- Stow ownership, machine profiles, Git synchronization, timers, snapshots, or migration:
  [references/dotfiles-sync-backup.md](references/dotfiles-sync-backup.md)
- Hyprland, plugins, Noctalia, UWSM, portals, or Wayland:
  [references/desktop-wayland.md](references/desktop-wayland.md)
- systemd, Arch packages, systemd-boot, Herdr, Tailscale, or remote continuity:
  [references/system-remote.md](references/system-remote.md)
- Fish/Bash, Lua/TOML, Ghostty, LazyVim, Starship, Fuzzel, Yazi, or Zen:
  [references/config-apps.md](references/config-apps.md)

For cross-layer symptoms, inspect every involved layer. A loaded plugin does not
prove its Lua module ran; a valid template does not prove its rendered consumer
is valid; a successful service start does not prove every repository pushed.

## Ownership Before Editing

Classify the target first:

1. portable tracked source in a Stow package
2. ignored machine override such as the Hyprland profile or timer interval
3. generated output whose template/source must be edited instead
4. runtime/private state that must remain untracked
5. allowlisted system reconstruction data captured by `backups-$profile`

Resolve live symlinks with `readlink -f`, inspect `.gitignore`, and check generator
markers. Never duplicate Stow-managed files in the machine snapshot.

## Inspection Workflow

1. Determine scope: user/system, static/runtime, portable/machine/generated/private.
2. Locate what is loaded: executable, process arguments, symlink source,
   includes/requires, XDG paths, systemd fragments/drop-ins, and generator.
3. Record installed version and package provenance; inspect local help, man pages,
   stubs, schemas, defaults, or source matching that version.
4. Establish baselines: repository status, application diagnostics, runtime
   state, and connection path. Preserve unrelated work.
5. Edit the smallest authoritative source. Do not hand-edit generated outputs.
6. Validate in layers: syntax, owning-application semantics, then an explicitly
   controlled reload or smoke test. Reinspect runtime state afterward.
7. Report exact files, checks, runtime mutations, Git/network actions, and
   anything untested.

Do not assume a path is active merely because it exists. On a rolling release,
do not assume an older command, plugin dispatcher, or schema still applies.

## Shell and Format Boundaries

- Pi's command tool executes Bash; interactive shell configuration targets Fish.
- Emit Fish syntax only for `.fish` files or an explicitly requested interactive command.
- Identify whether Bash is executed or sourced before changing strict mode or dialect.
- `luac -p` checks grammar only; Hyprland's `hl` and Neovim's `vim` require host validation.
- Prefer the owning application's effective-config/validator over generic TOML parsing.
- Preserve local style; do not install or run broad formatters for a focused edit.

## Safety and Privacy

- Prefer user-level, XDG-compliant changes. Do not use `sudo`, alter `/etc` or
  `/boot`, mutate packages, or restart system services without explicit authorization.
- `sync.sh`, `sync-all`, template application, package updates, `enable --now`,
  reloads, and session actions are mutations—not validators.
- Do not run repository sync scripts unless staging, committing, rebasing, and
  pushing all non-ignored changes is authorized.
- If access may use Tailscale, SSH, or Herdr, map the connection and recovery
  path before restarting networking, the user manager, UWSM, Hyprland, or Herdr.
- Never expose Tailscale/SSH state, browser profiles, cookies/history, clipboard
  or notification history, full environments, Pi credentials/sessions, or
  Noctalia credential state.
- Herdr-generated integration files such as `herdr-agent-state.ts` are managed;
  use Herdr's integration commands rather than editing them.
- Never discard, overwrite, commit, push, or rewrite unrelated work.
