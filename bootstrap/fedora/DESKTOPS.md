# Fedora 44 desktop stack

## Selected topology

Keep Fedora Workstation intact and add Niri and KDE rather than subtracting the
original desktop:

```text
Fedora boot → Plasma Login Manager → Niri → Noctalia      (preferred)
                                  ├→ KDE Plasma on KWin   (full fallback)
                                  └→ Workstation GNOME    (retained)

Installed inactive rollback display manager: GDM
```

This composition is intentionally ordinary: Fedora Workstation owns GNOME and
its application/integration closure, the `niri` package owns Niri's session and
portal policy, and Fedora's `kde-desktop` group owns Plasma's complete closure.
Plasma Login Manager changes only the greeter and active display-manager alias.
It does not require removing GDM or GNOME.

Install Plasma as Fedora's complete desktop composition rather than a
hand-picked shell subset:

```bash
dnf group info kde-desktop
sudo dnf group install kde-desktop
sudo systemctl disable plasma-setup.service
```

Fedora's group enables `plasma-setup.service`, an out-of-box wizard intended for
an unprovisioned account. Workstation has already provisioned the account, so
keep the package as a group member but leave that service disabled.

## Display manager and PAM boundary

The selected boot alias and expected service state are:

```bash
rpm -q gdm plasma-login-manager
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
systemctl is-enabled plasmalogin.service
systemctl is-active plasmalogin.service
test "$(systemctl is-active gdm.service 2>/dev/null || true)" = inactive
```

Switch from GDM only after GNOME, Niri, and Plasma have passed their baseline
checks through the currently active greeter:

```bash
sudo systemctl disable gdm.service
sudo systemctl enable --force plasmalogin.service
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
sudo systemctl reboot
```

Do **not** use `systemctl --dry-run` to preview display-manager enable/disable
operations. On the inspected system it still changed the
`display-manager.service` alias. Always inspect that alias after either command.
Only one display manager may own it; keeping GDM installed does not run two
login managers.

Fedora's `/usr/lib/pam.d/plasmalogin` integrates both
`pam_gnome_keyring.so` and `pam_kwallet5.so`. Keep these explicit anchors:

- Workstation/GNOME: `gdm`, `gnome-shell`, `gnome-session`, and `mutter`;
- PLM/Plasma: `plasma-login-manager` and `pam-kwallet`;
- Niri/GNOME secrets: `gnome-keyring`, `gnome-keyring-pam`, and `gcr`;
- portals: `xdg-desktop-portal`, `xdg-desktop-portal-gnome`,
  `xdg-desktop-portal-gtk`, and `xdg-desktop-portal-kde`.

The clean-install manifest installs those anchors explicitly. Do not run a
general `dnf autoremove` across this cross-desktop composition.

## Keyring behavior

The sessions use their native Secret Service implementation:

- **Niri and GNOME:** GNOME Keyring owns `org.freedesktop.secrets`; GCR can
  retrieve the SSH key passphrase from the login keyring.
- **Plasma:** KSecretD owns `org.freedesktop.secrets`; Fedora's OpenSSH agent is
  independent of KWallet and keeps an added SSH key only in memory.

Use the canonical KWallet name `kdewallet`:

```ini
[Wallet]
Default Wallet=kdewallet
First Use=false
```

Fedora's `pam-kwallet` 6.7.4 derives its login key from
`~/.local/share/kwalletd/kdewallet.salt`. A differently named wallet such as
`Default keyring` uses a different salt and can produce the misleading login
message `Wallet failed to get opened by PAM, error code is -9`. Do not patch the
PAM stack; recreate the wallet under the canonical name and use the login
password with Classic Blowfish when no OpenPGP secret key is available.

## SSH agent boundary

Retain Fedora's session-native agent selection rather than forcing one agent
across every desktop:

- Niri and GNOME use GCR at `$XDG_RUNTIME_DIR/gcr/ssh`.
- Plasma's `/etc/xdg/plasma-workspace/env/ssh-agent.sh` selects
  `$XDG_RUNTIME_DIR/ssh-agent.socket`.
- Plasma's `/usr/lib/systemd/user/plasma-core.target.d/ssh-agent.conf` starts
  `ssh-agent.service`.

Do not track replacements for those Plasma files, export `SSH_AUTH_SOCK` through
`environment.d`, or set it as a Fish universal variable. A fresh session must
inherit its package-owned socket naturally. There is deliberately no custom
key-loading autostart; key loading in Plasma is manual.

Verify Niri/GNOME with GCR. The first command may open GCR's local prompt; after
remembering the passphrase in GNOME Keyring, the post-restart command must be
silent:

```bash
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/gcr/ssh"
systemctl --user is-active gcr-ssh-agent.socket
systemctl --user restart gcr-ssh-agent.service
git -C "$HOME/dotfiles" ls-remote origin refs/heads/main
```

Verify Plasma with Fedora's OpenSSH agent, then load the key manually from a
terminal:

```bash
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/ssh-agent.socket"
test "$(fish -lc 'printf %s "$SSH_AUTH_SOCK"')" = \
  "$XDG_RUNTIME_DIR/ssh-agent.socket"
systemctl --user show-environment | \
  grep -Fx "SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket"
systemctl --user is-active ssh-agent.socket ssh-agent.service
ssh-add "$HOME/.ssh/id_ed25519"
ssh-add -T "$HOME/.ssh/id_ed25519.pub"
```

OpenSSH forgets the unlocked key when its agent or user manager stops. Run the
manual `ssh-add` again after reboot before enabling or relying on unattended
synchronization in Plasma. An active but unselected GCR socket may remain
available for the retained Niri/GNOME sessions; `SSH_AUTH_SOCK` identifies the
agent the session uses.

## X11 screen-sharing bridge boundary

Fedora's complete KDE group includes XWayland Video Bridge for legacy X11
applications that cannot consume native Wayland screen-cast portals. Niri,
Noctalia, native browsers, and portal-aware recording applications do not need
this bridge. Keep the package installed for Plasma/GNOME compatibility.

The package-owned `/etc/xdg/autostart/org.kde.xwaylandvideobridge.desktop` has
no desktop restriction. On the inspected Intel laptop, its idle full-output X11
surface is mapped through xwayland-satellite as a persistent black Niri tile;
the same versions remain hidden on the NVIDIA desktop. This is runtime
interop—not a wallpaper or layer-shell surface—and an opacity/window rule would
leave the unwanted client alive.

The tracked `desktop` package therefore shadows only the XDG autostart metadata
with the same desktop-file ID and this explicit session scope:

```ini
OnlyShowIn=KDE;GNOME;
```

It does not replace the executable, remove the KDE group member, or change any
package-owned file. Validate both the source and deployed link:

```bash
desktop-file-validate \
  "$HOME/.config/autostart/org.kde.xwaylandvideobridge.desktop"
test "$(readlink -f "$HOME/.config/autostart/org.kde.xwaylandvideobridge.desktop")" = \
  "$HOME/dotfiles/desktop/.config/autostart/org.kde.xwaylandvideobridge.desktop"
```

In Niri, systemd may generate the autostart unit, but its `KDE:GNOME`
`ExecCondition` must skip execution: the service stays inactive and no bridge
process or window exists. Plasma and GNOME may run the service for legacy
screen-sharing compatibility.

## Portal boundaries

Use Fedora's package-owned desktop policies without a user override:

- Niri loads `/usr/share/xdg-desktop-portal/niri-portals.conf`, owned by the
  `niri` package. Fedora 44 selects GNOME first, GTK second, and GNOME Keyring
  for Secret Service.
- GNOME uses its native GNOME portal stack.
- Plasma loads Fedora's `kde-portals.conf` and uses
  `xdg-desktop-portal-kde`, KWallet, and Plasma notifications.

Fedora 44's GNOME `FileChooser` implementation delegates to
`org.gnome.Nautilus`, so retain Nautilus even when Yazi is the default file
manager and Dolphin is available. Do not replace that chooser with GTK merely
to compensate for a removed Workstation package.

Verify that no higher-precedence user policy masks Fedora:

```bash
test ! -e "$HOME/.config/xdg-desktop-portal/portals.conf"
test ! -e "$HOME/.config/xdg-desktop-portal/niri-portals.conf"
rpm -qf /usr/share/xdg-desktop-portal/niri-portals.conf
```

Do not export KDE session variables globally or replace working Niri components
merely to make the primary desktop look KDE-native.

## Acceptance gate

After a clean installation, release upgrade, or display-manager change, test all
three sessions through PLM:

1. **Niri:** Noctalia, GNOME/GTK portals, browser open/save/upload, GNOME
   Keyring, silent GCR signing, NVIDIA where applicable, networking, Bluetooth,
   PipeWire/WirePlumber, recording, lock, and suspend/resume.
2. **Plasma:** KWin/Plasma, KDE portals, PolicyKit, networking, Bluetooth,
   audio, removable storage, Discover, notifications, lock/suspend, canonical
   `kdewallet`, Fedora's OpenSSH agent, and signing after an explicit `ssh-add`.
3. **GNOME:** GNOME Shell/Mutter, GNOME portals, Nautilus chooser, keyring,
   networking, audio, lock, and suspend/resume.
4. Return to **Niri** so PLM remembers the preferred daily session.

The inspected machine already passed the Niri and Plasma gates before GNOME was
restored. A real PLM → GNOME login remains required before claiming the new
three-session topology is fully accepted.

## Workstation retention policy

Do not remove Workstation applications or support libraries merely because a
KDE or preferred application overlaps them. Desktop files consume little
operational complexity; hidden portal, preview, online-account, printing, and
file-manager integrations are more important than package-count reduction.

Specifically:

- do not remove GDM, GNOME Shell/session, Mutter, Nautilus, Papers, GNOME
  Software, Evolution Data Server, GNOME Online Accounts, or their support
  stacks as part of this setup;
- do not run `dnf group remove gnome-desktop`;
- do not run an unreviewed `dnf autoremove`;
- keep only one *active* display manager by controlling the systemd alias.

Preference remains separate from installation: Yazi, Zathura, imv, mpv, Helix,
and Thunderbird can remain MIME defaults while Workstation and KDE applications
stay available.

## Recovery

Because GDM remains installed, rollback is only a service switch:

```bash
sudo systemctl disable plasmalogin.service
sudo systemctl enable --force gdm.service
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/gdm.service
sudo systemctl reboot
```

Return to PLM with the inverse operation after correcting the problem:

```bash
sudo systemctl disable gdm.service
sudo systemctl enable --force plasmalogin.service
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
sudo systemctl reboot
```

Verify `/etc/systemd/system/display-manager.service` after every operation.
