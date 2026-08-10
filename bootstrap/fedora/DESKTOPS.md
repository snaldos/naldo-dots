# Fedora 44 desktop stack

## Selected topology

This repository targets two supported Wayland desktops behind Plasma Login
Manager:

```text
Fedora boot → Plasma Login Manager → Niri → Noctalia      (primary)
                                  └→ KDE Plasma on KWin   (full fallback)
```

Plasma is the coherent recovery desktop; Niri remains the preferred daily
session. Plasma Login Manager remembers the last session selected for each
user, so log into **Niri** once after Plasma maintenance to restore it as the
login-screen default.

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
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
systemctl is-enabled plasmalogin.service
systemctl is-active plasmalogin.service
! rpm -q gdm >/dev/null 2>&1
```

For a staged transition while GDM is still installed, switch only after Niri
and Plasma have both passed their acceptance checks:

```bash
sudo systemctl disable gdm.service
sudo systemctl enable plasmalogin.service
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
sudo systemctl reboot
```

Do **not** use `systemctl --dry-run` to preview display-manager enable/disable
operations. On the inspected system it still changed the
`display-manager.service` alias. Always inspect that alias after either command.

Fedora's `/usr/lib/pam.d/plasmalogin` integrates both `pam_gnome_keyring.so` and
`pam_kwallet5.so`. Keep all of these explicit package anchors:

- `plasma-login-manager` and `pam-kwallet`;
- `gnome-keyring`, `gnome-keyring-pam`, and `gcr`;
- `xdg-desktop-portal`, `xdg-desktop-portal-gnome`,
  `xdg-desktop-portal-gtk`, and `xdg-desktop-portal-kde`.

Marking them as user-selected prevents a later `dnf autoremove` from treating
login-keyring integration as an obsolete GNOME dependency:

```bash
sudo dnf mark user \
  plasma-login-manager pam-kwallet \
  gnome-keyring gnome-keyring-pam gcr \
  xdg-desktop-portal xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk xdg-desktop-portal-kde
```

## Keyring behavior

Niri and Plasma deliberately use different Secret Service implementations:

- **Niri:** GNOME Keyring owns `org.freedesktop.secrets`; GCR retrieves the SSH
  key passphrase from the login keyring.
- **Plasma:** KSecretD owns `org.freedesktop.secrets`; GCR retrieves the
  separately enrolled SSH key passphrase from KWallet.

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

KWallet 6.28 can initially expose an already PAM-opened collection as
`Locked=true` through the Secret Service façade. This is stale collection
bookkeeping, not a PAM failure, when the native backend reports
`isOpen(kdewallet)=true`. A real libsecret/GCR request performs the standard
Secret Service unlock protocol silently and changes the collection to unlocked.
The acceptance test is therefore a fresh GCR restart followed by real SSH
signing, not the initial `Locked` property alone.

## Portal boundaries

Desktop-specific portal policy remains required:

- Niri uses the tracked `niri-portals.conf`, preferring GNOME and GTK backends
  and GNOME Keyring for Secret Service. Retain Nautilus even though Yazi is the
  default file manager: Fedora 44's GNOME `FileChooser` portal delegates browser
  uploads to the `org.gnome.Nautilus` D-Bus service.
- Plasma uses Fedora's package-provided `kde-portals.conf` and
  `xdg-desktop-portal-kde`.

Do not add a user-level generic `portals.conf`: its higher-precedence fallback
would mask Fedora's desktop-specific policy. Do not export KDE session variables
globally or replace working Niri components merely to make the primary desktop
look KDE-native.

## Acceptance evidence and regression gate

The Fedora 44 cutover was accepted only after both PLM paths passed real tests:

1. PLM offered the packaged Niri and Plasma sessions and remembered the last
   choice.
2. PLM → Niri started Niri/Noctalia with GNOME/GTK portals, GNOME Keyring,
   silent GCR signing, NVIDIA, display, networking, Bluetooth, PipeWire, and
   WirePlumber intact.
3. PLM → Plasma started KWin/Plasma with KDE portals, PolicyKit, networking,
   Bluetooth, audio, removable storage, Discover, notifications, lock/unlock,
   and suspend/resume intact.
4. The canonical `kdewallet` was created and PAM-opened without error `-9`.
5. After a complete Plasma relogin and GCR restart, SSH signing retrieved its
   passphrase silently from KWallet.

After a release upgrade or display-manager change, repeat both login paths,
portal checks, lock/suspend, and a GCR restart plus authenticated operation.

## Reviewed GNOME reduction

Removing a desktop session is different from purging every package with
`gnome` in its name. The selected target removes GDM, GNOME Shell/session,
Mutter, the GNOME Shell extensions, initial setup/tour, and GNOME Remote
Desktop. It also removes reviewed duplicate Workstation applications and their
now-ownerless support stacks where the declared defaults already provide Yazi
or Dolphin, Zathura or Okular, imv, mpv, Helix, Discover, Plasma System Monitor,
Filelight, KCharSelect, Thunderbird, or Noctalia.

It deliberately retains the Niri integration packages listed above, including
Nautilus solely for the GNOME portal chooser; Yazi remains the default file
manager and Dolphin the graphical fallback. The current standalone capability
set also retains GNOME Disks, Calculator, Simple Scan, Snapshot, Boxes, and
Connections; those are applications, not a third desktop.

Never run `dnf group remove gnome-desktop` or an unreviewed `dnf autoremove`.
Fedora Workstation protects `gnome-shell` because it assumes GNOME is the only
graphical shell. The clean-install guide documents the one audited transaction
that clears that command-local list and immediately restores every core
protection except `gnome-shell`; do not persistently edit the package-owned
protection file.

Preview explicit batches with `--assumeno --no-autoremove`. Require zero
removals from Niri, Noctalia, Plasma, PLM, KWallet PAM, GNOME Keyring/GCR,
portals, graphics, audio, networking, or deliberately retained applications.
Standalone application cleanup remains preference-driven rather than a desktop
purity requirement.

## Recovery

Before GDM is removed, rollback is only a service switch:

```bash
sudo systemctl disable plasmalogin.service
sudo systemctl enable gdm.service
sudo systemctl reboot
```

After the reviewed cleanup, reinstall the rollback stack first:

```bash
sudo dnf install gdm gnome-shell gnome-session-wayland-session
sudo systemctl disable plasmalogin.service
sudo systemctl enable gdm.service
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/gdm.service
sudo systemctl reboot
```

Verify `/etc/systemd/system/display-manager.service` after every operation.
