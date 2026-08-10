# Niri, Noctalia, and Wayland

## Establish the running topology

Inspect before changing it:

```bash
niri --version
pgrep -a -x niri
ps -u "$(id -u)" -o pid=,comm=,args= | rg 'niri|noctalia|xdg-desktop-portal'
printf 'type=%s desktop=%s\n' "${XDG_SESSION_TYPE-}" "${XDG_CURRENT_DESKTOP-}"
systemctl --user --no-pager --type=service --state=running
```

The primary login path is Plasma Login Manager → the package-provided Niri
session → native Noctalia. The same chooser exposes Fedora's package-provided
KDE Plasma session as the full fallback desktop. GDM and GNOME Shell are absent;
GNOME Keyring, GCR, and GNOME/GTK portals remain deliberate Niri dependencies.
The bootstrap runbooks document that topology, while the user installers never
switch display managers or remove desktops. Read `bootstrap/fedora/DESKTOPS.md`
before a desktop-stack change. Separate compositor, shell, systemd-user
lifecycle, portals, PipeWire/WirePlumber, and kernel/device support when
diagnosing a symptom.

## Niri

The active entry point is `~/.config/niri/config.kdl`, linked from the `niri`
package. Its includes are explicit and ordered. `install.sh` renders the real
machine-local `machine.kdl`; `zen-theme.kdl` and Noctalia's generated fragment
are optional real files loaded last.

Validate the authoritative config rather than trusting live reload:

```bash
niri validate
niri validate -c PATH/TO/config.kdl
niri msg --help
niri msg action --help
niri msg -j outputs
niri msg -j workspaces
niri msg -j windows
```

For shared changes, validate isolated copies with both machine profiles. Use
JSON and `jq` for nontrivial IPC inspection. Do not restart the session merely
to validate a static edit.

Niri uses GNOME and GTK portal backends selected by the tracked,
desktop-specific portal config. Retain Nautilus even though Yazi is the default
file manager: Fedora 44's GNOME `FileChooser` backend delegates browser uploads
to `org.gnome.Nautilus`. Plasma uses Fedora's KDE portal backend. Do not add a
generic user `portals.conf`, which would mask Fedora's desktop-specific policy.
Noctalia supplies Niri's user-facing PolicyKit agent; the system authority
remains separate. GNOME Keyring supplies Niri's Secret Service. Verify backend
selection and service state rather than adding manual startup commands.

## Native Noctalia v5

Noctalia v5 is a native Wayland shell configured by TOML and controlled with
`noctalia msg`; it is not the old Quickshell/QML shell.

Ownership boundaries:

- durable config/templates: `$XDG_CONFIG_HOME/noctalia/`
- machine-local plugin credentials: `credentials.toml`, mode `0600`
- GUI/machine preferences and private state: `$XDG_STATE_HOME/noctalia/`
- log/cache: `$XDG_CACHE_HOME/noctalia/`

Do not place credentials in tracked config, GUI-managed settings, support
exports, or synchronization repositories. Treat encrypted state, clipboard,
notification, account, and location data as private.

```bash
noctalia --version
noctalia --help
noctalia msg --help
noctalia config --help
noctalia config validate "$HOME/.config/noctalia/config.toml"
```

Merged/full exports can reveal machine state. Keep them local and never replace
maintained source with an export. Template application rewrites multiple files
and may run hooks, so it is a mutation rather than a validator.

Noctalia is also the dmenu frontend for desktop helpers. A missing optional tool
must produce a feature-local diagnostic, not prevent Niri or Noctalia startup.

The official Bongo Cat plugin does not auto-detect an input device. Its tracked
`input_devices` setting names `/dev/input/by-id/keyd-virtual-kbd`, which is
created by the exact `system/udev/69-keyd-bongocat.rules` rule and granted to the
active local session through `uaccess`. Do not replace it with an unstable
`eventN`, a broad mode, or membership in the `input` group.

The annotation helper asks Noctalia v5 to capture a region, reads the resulting
PNG from the clipboard, and pipes it to Fedora's `swappy -f -`. Do not add grim
or slurp to this path: Noctalia owns capture, while Swappy owns annotation.

## Zen Flatpak

Zen has one supported installation identity:

```text
Flatpak ID:   app.zen_browser.zen
Desktop file: app.zen_browser.zen.desktop
Launch:       flatpak run app.zen_browser.zen
```

The inspected Flatpak metadata reports `StartupWMClass=zen` and
`RemotingName=zen`, but the selected installation currently reports the live
Niri app ID `app.zen_browser.zen`. Wayland runtime identity is authoritative and
can change independently. After installing and opening Zen, inspect it without
printing browser titles:

```bash
niri msg -j windows | jq -r '.[].app_id' | sort -u
```

Adjust the generated opacity rule only from that evidence. Zen and Ghostty have
no dedicated floating app IDs or rules; `Mod+Z` and `Mod+T` open ordinary tiled
windows. Never inspect browser profile databases, cookies, history, or sessions.
