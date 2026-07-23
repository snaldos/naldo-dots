# Niri, Noctalia, and Wayland

## Establish the Running Topology

Inspect before changing it:

```bash
niri --version
pgrep -a -x niri
ps -u "$(id -u)" -o pid=,comm=,args= | rg 'niri|noctalia|xdg-desktop-portal'
printf 'type=%s desktop=%s\n' "${XDG_SESSION_TYPE-}" "${XDG_CURRENT_DESKTOP-}"
systemctl --user --no-pager --type=service --state=running
```

Separate these layers:

1. native Wayland application/toolkit versus XWayland
2. Noctalia shell surface or service
3. Niri compositor, outputs, rules, workspaces, and IPC
4. the `niri-session` systemd-user lifecycle
5. portals, PipeWire/WirePlumber, D-Bus, and kernel/device support

For sharing or picker failures, inspect the selected portal implementation and
a bounded user journal before changing global environment variables.

## Niri

### Ground truth and ownership

The active config is `~/.config/niri/config.kdl`, linked from the portable
`niri` Stow package. Confirm the link rather than assuming a similarly named
file is loaded. Niri runs through `niri-session` and `niri.service`; it does not
use a separate Wayland session manager.

Common settings remain in `config.kdl`. The shared machine selector reads the
optional `~/.config/naldo/machine-profile/profile`, otherwise tracked `default`.
`install.sh` atomically renders the ignored real file
`~/.config/niri/machine.kdl`, which includes either `profiles/desktop.kdl` or
`profiles/laptop.kdl`. The generated Zen theme selector and Noctalia theme
fragment are likewise optional real target-side files.

Do not edit generated includes directly. A persistent named workspace can alter
dynamic numeric ordering; the notes helper instead names the bottom empty
workspace on demand.

### IPC and validation

Inspect installed help before using an action:

```bash
niri msg --help
niri msg action --help
niri msg -j outputs
niri msg -j workspaces
niri msg -j windows
```

Use JSON plus `jq` for nontrivial window/workspace inspection. Prefer Niri's
native action in a binding; use a helper only when sequencing, polling, or
conditional behavior is genuinely required.

Validate the authoritative config before relying on Niri's live reload:

```bash
niri validate
niri validate -c PATH/TO/config.kdl
```

When a common change can interact with output or switch-event fragments,
validate isolated copies with both tracked machine profiles. Missing optional
Noctalia or Zen includes are expected in an isolated test directory. Reinspect
the bounded user journal after a live edit; do not restart the session as a
validator.

### Portals and authentication

Niri uses the GNOME and GTK portal backends selected by
`~/.config/xdg-desktop-portal/niri-portals.conf`. GNOME Keyring supplies the
external authentication agent when Noctalia's built-in polkit agent is disabled.
A running portal process does not prove the intended backend was selected;
inspect config precedence and targeted process/service state.

## Native Noctalia v5 Beta

Noctalia v5 is the native C++ Wayland shell with TOML configuration and
`noctalia msg` IPC. It is not Quickshell: do not propose QML, `qs ipc`, or old
v4 paths.

### Config, state, and privacy

Resolve XDG variables and distinguish:

- durable config/templates: `$XDG_CONFIG_HOME/noctalia/`
- machine-local plugin credentials:
  `$XDG_CONFIG_HOME/noctalia/credentials.toml`, mode `0600`
- non-secret GUI/machine preferences: `$XDG_STATE_HOME/noctalia/settings.toml`
- credential-bearing application state: `$XDG_STATE_HOME/noctalia/state.toml`
- histories/caches under the remaining state tree
- log: `$XDG_CACHE_HOME/noctalia/noctalia.log`

Noctalia loads top-level `*.toml` files, so keep plugin keys in
`credentials.toml`, not a `credentials/` directory, the tracked config, or
GUI-managed `settings.toml`. `install.sh` initializes the local file from the
tracked `credentials.toml.example`, which documents the schema without being
loaded. Treat both `credentials.toml` and `state.toml` as credentials: do not
print, copy, or add them to snapshots. Clipboard, notification, location,
usage, and screen-time state are private and normally irrelevant.

### Inspect and validate

```bash
noctalia --version
noctalia --help
noctalia msg --help
noctalia config --help
noctalia config validate "$HOME/.config/noctalia/config.toml"
```

Merged/full exports may reveal private paths or state. Inspect only when needed,
keep output local, and never replace the maintained source without a reviewed
diff. IPC names are beta; use installed help. After an authorized edit, reload
only if necessary, inspect targeted status, and tail a bounded log. Never test
with lock, DPMS, logout, reboot, shutdown, or destructive history commands.

### Launcher and script menus

Noctalia is the menu frontend for shared desktop and Niri-specific scripts. For
transient pickers, scripts pipe newline-separated choices to
`noctalia dmenu -p PROMPT` and read the selected line from stdout; cancellation
exits `1`. The running Noctalia instance must share `XDG_RUNTIME_DIR` and
`WAYLAND_DISPLAY`. Persistent command palettes can instead use
`[shell.launcher.dmenu.entry.<id>]` providers.

Noctalia's centralized `[keybinds]` table applies across launcher and shell
surfaces. Preserve arrow defaults when adding alternatives, for example
`up = ["up", "ctrl+k"]` and `down = ["down", "ctrl+j"]`. Supported modifiers
are `ctrl`, `shift`, and `alt`; Super bindings are rejected.

### Templates

All durable user-template inputs are under
`~/.config/noctalia/templates/`; outputs are ignored in consuming packages.
Before changing a themed consumer:

1. inspect active `[theme.templates]`
2. classify builtin/community/user input and output
3. edit the durable source or stable fallback logic
4. validate config and all affected consumers
5. apply templates only with authorization

`noctalia msg templates-apply` is a multi-file mutation with possible hooks, not
a harmless validator.

### Greeter boundary

Noctalia Greeter keeps its bundled compositor. The authenticated session is
pinned separately in `/etc/greetd/config.toml`; it must name the installed Niri
session. Appearance state under `/var/lib/noctalia-greeter/` can remember a
last-used session, but the explicit greetd argument takes precedence. Validate
session names with `noctalia-greeter sessions` before changing system config.
