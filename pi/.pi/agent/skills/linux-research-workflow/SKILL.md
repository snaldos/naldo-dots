---
name: linux-research-workflow
description: "Inspect, debug, validate, or configure Naldo's Arch Linux workstation: Hyprland Lua/hl, native Noctalia v5, systemd/systemd-boot, Herdr, Tailscale, Wayland/UWSM, Ghostty, Fish/Bash, Neovim/LazyVim, Starship, Fuzzel, Yazi, Zen, Arch packages, uv/pixi, scripts, and dotfiles."
compatibility: "Arch Linux; Hyprland 0.55+ Lua configuration; native Noctalia v5 beta; UWSM/systemd; Fish interactive shell; Bash automation; Herdr; Tailscale; Ghostty; Neovim/LazyVim; Wayland."
---

# Linux Research Workstation

## Workstation Model

Treat this as a profile, not a substitute for inspection:

- rolling Arch Linux; installed versions and local documentation are authoritative
- Hyprland 0.55+ with Lua configuration and the embedded `hl` API, normally under UWSM/systemd-user
- Noctalia v5 beta: the native C++ Wayland rewrite invoked as `noctalia`, **not** the old Quickshell/QML shell
- Ghostty, Fish, Starship, Neovim/LazyVim, Fuzzel, Yazi, and Zen Browser
- Herdr for persistent terminal workspaces and agent sessions
- Tailscale for possible remote access; systemd-boot with a UKI, subject to re-verification
- Noctalia theme templates generate parts of several other applications' configs

## Load the Relevant Reference

Before nontrivial diagnosis or editing, read only the matching guide:

- Hyprland, Noctalia, UWSM, portals, or Wayland: [references/desktop-wayland.md](references/desktop-wayland.md)
- systemd, Arch packages, systemd-boot, Herdr, Tailscale, or remote continuity: [references/system-remote.md](references/system-remote.md)
- Fish/Bash, Lua/TOML, Ghostty, LazyVim, Starship, Fuzzel, Yazi, or Zen: [references/config-apps.md](references/config-apps.md)

For a cross-layer problem, inspect each involved layer rather than guessing from symptoms.

## Inspect Before Editing

1. Determine scope and impact: user or system, static config or runtime state, local or remote session.
2. Locate what is actually loaded: executable, process arguments, environment override, symlink target, includes/requires, XDG paths, drop-ins, and generated-file markers.
3. Record the version and package provenance. Read matching local `--help`, man pages, package docs, schemas, stubs, or default config before using online examples.
4. Check repository status and establish a validation baseline. Preserve unrelated changes.
5. Edit the authoritative source with the smallest reversible diff; never hand-edit a generated target when its template/source is available.
6. Validate in layers: syntax, application semantics, then an explicitly controlled reload or smoke test. Compare with the baseline.
7. Report the exact files changed, checks run, runtime actions taken, warnings, and anything left untested.

Do not assume a default path merely because it exists. On rolling releases, do not assume last month's command or schema still applies.

## Shell and Format Boundaries

- Pi's command tool runs Bash; interactive terminal configuration targets Fish.
- Emit Fish syntax only for `.fish` files or an explicitly requested Fish command.
- For Bash, identify whether a file is executed or sourced before adding strict mode or changing its dialect.
- For Lua, a generic parser checks syntax only; Hyprland's `hl` and Neovim's `vim` globals require their host validators.
- For TOML, prefer the owning application's validator/effective-config command over a generic parser.
- Preserve project formatting. Do not install a formatter merely to make one edit.

## Safety and Privacy

- Prefer user-level, XDG-compliant changes. Do not use `sudo`, alter `/etc` or `/boot`, mutate packages, or restart system services unless explicitly authorized.
- If access may be through Tailscale, SSH, or Herdr, do not restart networking, `tailscaled`, SSH, the Herdr server, the systemd user manager, UWSM, Hyprland, or the shell until the connection path and fallback are known and approval is explicit.
- Never expose Tailscale auth/state, SSH material, browser profiles, cookies/history, clipboard or notification history, full environment dumps, session contents, or unredacted peer/account/IP data.
- Herdr integration files such as `~/.pi/agent/extensions/herdr-agent-state.ts` are managed. Use `herdr integration status` and `herdr integration install pi`; do not edit them.
- Treat reloads, generated-theme application, session actions, monitor changes, plugin updates, and `enable --now` as runtime mutations—not validation.
- Never discard, commit, push, or rewrite unrelated dotfile work.
