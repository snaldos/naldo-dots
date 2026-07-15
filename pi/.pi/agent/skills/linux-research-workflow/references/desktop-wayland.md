# Hyprland, Noctalia, and Wayland

## Establish the Running Topology

Inspect the session before changing it:

```bash
Hyprland --version-json
noctalia --version
ps -u "$(id -u)" -o pid=,comm=,args= | rg 'Hyprland|noctalia|uwsm|xdg-desktop-portal'
printf 'type=%s desktop=%s\n' "${XDG_SESSION_TYPE-}" "${XDG_CURRENT_DESKTOP-}"
systemctl --user --no-pager --type=service --state=running
```

Use targeted output; do not dump the full environment. Determine whether UWSM, a display manager, Hyprland Lua, or a user unit starts each component. Keep these layers separate:

1. application/toolkit and native Wayland versus XWayland
2. Noctalia shell surface or service
3. Hyprland compositor, output, rule, and plugin state
4. UWSM/systemd-user environment and lifecycle
5. portals, PipeWire/WirePlumber, D-Bus, and kernel/device support

For screen sharing or file-picker failures, inspect the selected `xdg-desktop-portal` backend and its user journal rather than changing global environment variables blindly.

## Hyprland 0.55+ Lua

### Ground truth

The normal entry point is `~/.config/hypr/hyprland.lua`, but confirm `Hyprland --config` process arguments and module paths. Before writing API calls, inspect the files shipped by the installed package:

- `/usr/share/hypr/stubs/hl.meta.lua`: current `hl` types, objects, events, config keys, and namespaces
- `/usr/share/hypr/hyprland.lua`: current default Lua examples
- `~/.config/hypr/.luarc.json`: language-server stub wiring
- `Hyprland --help`, `hyprctl --help`, and `hyprctl <command> --help`

`hl` is an embedded Lua global, not a standalone executable. Do not translate old Hyprlang `.conf` snippets mechanically.

### API model

- `hl.config({...})`, `hl.monitor({...})`, `hl.device({...})`, and rule functions declare configuration.
- `hl.dsp.*` functions construct dispatchers.
- `hl.bind(keys, dispatcher, options)` installs a bind. It may receive an `hl.dsp.*` value or a Lua callback.
- Inside a callback, `hl.dispatch(dispatcher)` executes a dispatcher immediately.
- `hl.on(...)`, `hl.timer(...)`, query functions, and window/workspace/monitor objects provide the in-process API.
- `hyprctl` remains the runtime IPC client. Prefer `-j` plus `jq` for inspection. Current command-line dispatch expressions use the Lua dispatcher API, for example the harmless probe `hyprctl dispatch 'hl.dsp.no_op()'`.

Prefer typed constructors such as `hl.dsp.focus({...})`, `hl.dsp.window.move({...})`, and `hl.dsp.exec_cmd(...)` over stale textual dispatcher names. Verify signatures in the installed stub/default config; plugin namespaces are version- and load-state-dependent.

### Ownership and generated files

Inspect `require(...)` edges and file headers. On this workstation, notable generated outputs currently include:

- `~/.config/hypr/monitors.lua` from `nwg-displays`
- `~/.config/hypr/noctalia.lua` from Noctalia templates

Do not edit these directly unless the user explicitly wants to abandon their generator. Hyprland config is its own Git repository; inspect its status first.

### Validation ladder

```bash
# Syntax only; does not understand hl or plugin state
luac -p path/to/file.lua

# Isolated semantic parse
Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua"

# Running compositor state
hyprctl -j configerrors | jq .
hyprctl -j monitors | jq .
hyprctl -j binds | jq .
```

Inspect top-level Lua before invoking `--verify-config`, because a Lua config can execute commands. Isolated verification may report plugin config keys or `hl.plugin.*` members as missing when `hyprpm` plugins are not loaded there. Never dismiss this silently: compare the pre-edit baseline, identify plugin-only diagnostics, and check the running compositor.

Reload only after validation and approval when session stability matters. Prefer `hyprctl reload config-only` when monitor reload is unnecessary, then recheck `configerrors`. Do not use `hyprpm reload` as a validator.

## Native Noctalia v5 Beta

Noctalia v5 is a native C++23 Wayland shell with TOML configuration and `noctalia msg` IPC. It is not Quickshell: do not propose QML edits, `qs ipc`, Quickshell services, or old v4 paths.

### Config, state, and logs

Resolve XDG variables, then distinguish:

- config: `$XDG_CONFIG_HOME/noctalia/config.toml`
- GUI/runtime overrides: `$XDG_STATE_HOME/noctalia/settings.toml`
- other runtime state/history under `$XDG_STATE_HOME/noctalia/`
- log: `$XDG_CACHE_HOME/noctalia/noctalia.log`
- installed overview: `/usr/share/doc/noctalia/README.md`

State can include clipboard, notification, location, and usage data. Inspect only what the task requires and never reproduce it wholesale.

### Inspect and validate

```bash
noctalia --version
noctalia --help
noctalia msg --help
noctalia config --help
noctalia config validate
noctalia config validate "$HOME/.config/noctalia/config.toml"
noctalia config export merged   # inspect locally; may contain private paths/data
noctalia config export full     # defaults plus effective config when needed
```

Use `noctalia msg <command>` names from the installed `msg --help`; the IPC is beta and can change. After an authorized edit, use `noctalia msg config-reload`, inspect only relevant status fields, and tail a bounded portion of the log. Never test with session, DPMS, lock, reboot, shutdown, or destructive history commands.

### Theme/template ownership

Noctalia can rewrite theme fragments for Hyprland, Ghostty, Starship, Fuzzel, Yazi, Neovim, Zen, and other apps. Before editing a themed file:

1. inspect `[theme.templates]` in the active/merged config
2. search the target for `Generated by Noctalia` or template markers
3. identify builtin/community versus user-template input and output
4. edit the durable source or custom template
5. validate every affected target before applying templates

`noctalia msg templates-apply` is a multi-file mutation, not a harmless reload. Do not run it merely to test one config.
