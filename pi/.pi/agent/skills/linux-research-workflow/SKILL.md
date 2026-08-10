---
name: linux-research-workflow
description: "Inspect, debug, validate, maintain, or configure Naldo's Fedora-targeted Linux desktop/laptop: GNU Stow dotfiles, repository synchronization, Niri, native Noctalia v5, KDE Plasma fallback, systemd, Wayland, keyd, Ghostty, Fish, Helix, Yazi, Zen Flatpak, Herdr, and scientific tooling."
compatibility: "Fedora 44 Workstation target; Linux; Plasma Login Manager to retained GNOME, primary Niri/Noctalia, and fallback KDE Plasma; GNU Stow; systemd user services; Fish; Ghostty; Helix hx; Herdr."
---

# Linux Research Workstation

## Verified architecture, not assumptions

Treat this as a target profile that must still be inspected against the installed
Fedora release and application versions:

- intact Fedora 44 Workstation with Plasma Login Manager offering the retained
  GNOME session, package-provided Niri (primary), and Fedora `kde-desktop`
  Plasma (full fallback); GDM is installed but inactive as rollback
- Niri running through `niri-session`/`niri.service`, with native Noctalia as the shell
- Fish, Ghostty, Starship, Helix (`hx`), Yazi, Zen as
  `app.zen_browser.zen`, and Herdr; Neovim is only an optional stock fallback
- portable user configuration in `~/dotfiles`, deployed by GNU Stow with
  `--no-folding`
- explicit `install.sh --profile desktop|laptop` selection rendered into Niri's machine-local selector
- one disabled-by-default `sync-all.timer` for dotfiles, notes, and wallpapers
- Fedora session-native SSH agents: GCR under Niri/GNOME and OpenSSH under
  Plasma, with manual `ssh-add` after reboot and no custom key-loading autostart
- root-owned keyd mapping and Bongo Cat udev rule under `system/`, installed only by `install-system.sh`
- Noctalia templates as durable sources; rendered outputs remain machine-local

The bootstrap runbooks document the selected desktop topology and explicit
package transactions. User deployment scripts do not switch the login manager,
remove desktops, alter the boot path, enable repositories, update packages, or
change graphics drivers.

## Load the matching reference

- Stow, profiles, repository synchronization, timers, or private/generated state:
  [references/dotfiles-sync.md](references/dotfiles-sync.md)
- Niri, Noctalia, portals, Zen, or Wayland:
  [references/desktop-wayland.md](references/desktop-wayland.md)
- systemd, keyd, Herdr, Tailscale, or remote continuity:
  [references/system-remote.md](references/system-remote.md)
- Fish/Bash, application configs, Ghostty, Helix, Yazi, or Pi:
  [references/config-apps.md](references/config-apps.md)

For cross-layer symptoms, inspect every involved layer. A valid source does not
prove its generated consumer is current, and a successful service start does
not prove each repository synchronized.

## Ownership before editing

Classify the target first:

1. portable tracked source in a declared Stow package
2. ignored machine-local override or generated output in the deployed target
3. root-owned declarative source under `system/`
4. runtime/private state that must remain untracked
5. dependency/bootstrap documentation under `bootstrap/fedora/`

Resolve live symlinks with `readlink -f`, inspect ignore rules and generator
markers, and keep target directories real. Never use `stow --adopt` for an
unexpected target.

## Inspection workflow

1. Determine user/system scope and static/generated/runtime ownership.
2. Locate the loaded file, executable, process arguments, includes, and unit.
3. Record installed version and inspect local help, schemas, package files, or
   matching upstream documentation.
4. Establish Git status and the smallest relevant runtime baseline.
5. Edit the authoritative source, not generated state.
6. Validate syntax, owner semantics, and only then an explicitly controlled
   reload or smoke test.
7. Report files, checks, runtime mutations, network actions, and untested Fedora
   behavior exactly.

## Shell and safety boundaries

- Pi executes Bash; interactive shell configuration targets Fish.
- Fedora's Helix executable is `hx`; committed runtime configuration and the
  user installer require that native command directly.
- Neovim is optional; when present it remains stock and has no Stow package.
- Prefer application validators over generic parsing.
- Do not run repository synchronizers merely to validate them: they can commit,
  rebase, and push.
- Do not install/update packages, enable repositories, change login/boot/graphics
  configuration, restart the desktop, or modify system services without explicit
  authorization.
- Root-owned keyd/udev changes go through `install-system.sh`; inspect its dry
  run, explicit activation, and recovery procedure first.
- Never expose credentials, private sessions, browser profiles, histories,
  clipboard/notification state, or complete remote-access state.
- Do not edit Herdr-generated integration files such as
  `herdr-agent-state.ts`.
- Never discard, overwrite, commit, push, or rewrite unrelated work.
