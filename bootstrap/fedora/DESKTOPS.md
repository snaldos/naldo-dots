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

The sessions deliberately use their native Secret Service implementation:

- **Niri and GNOME:** GNOME Keyring owns `org.freedesktop.secrets`; GCR
  retrieves the SSH key passphrase from the login keyring.
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
`Locked=true` through the Secret Service facade. This is stale collection
bookkeeping, not a PAM failure, when the native backend reports
`isOpen(kdewallet)=true`. A real libsecret/GCR request performs the standard
Secret Service unlock protocol silently and changes the collection to unlocked.
The acceptance test is therefore a fresh GCR restart followed by real SSH
signing, not the initial `Locked` property alone.

## SSH agent boundary

Fedora 44's Plasma composition otherwise selects a second OpenSSH agent through
two package-owned files:

- `/etc/xdg/plasma-workspace/env/ssh-agent.sh` fills an empty
  `SSH_AUTH_SOCK` with `$XDG_RUNTIME_DIR/ssh-agent.socket`;
- `/usr/lib/systemd/user/plasma-core.target.d/ssh-agent.conf` pulls
  `ssh-agent.service` into every Plasma session.

That conflicts with the selected single GCR agent. The tracked `desktop` Stow
package therefore owns two higher-precedence user files:

- `~/.config/plasma-workspace/env/ssh-agent.sh` exports
  `$XDG_RUNTIME_DIR/gcr/ssh` inside Plasma;
- `~/.config/systemd/user/plasma-core.target.d/ssh-agent.conf` shadows only the
  same-named vendor drop-in, without editing or masking a package file.

After a fresh Plasma login, verify the ambient route rather than hiding a wrong
session environment with a per-command override:

```bash
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/gcr/ssh"
test "$(fish -lc 'printf %s "$SSH_AUTH_SOCK"')" = "$XDG_RUNTIME_DIR/gcr/ssh"
systemctl --user show-environment | \
  grep -Fx "SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh"
test "$(systemctl --user is-active ssh-agent.service 2>/dev/null || true)" = inactive
test "$(systemctl --user is-active ssh-agent.socket 2>/dev/null || true)" = inactive
test "$(systemctl --user show ssh-agent.service -p MainPID --value)" = 0
```

A signing command prefixed with `SSH_AUTH_SOCK=...` proves only that GCR itself
works; it does not prove that Bash, Fish, applications, or `sync-all.service`
will select GCR naturally.

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
   `kdewallet`, and silent GCR signing after a fresh agent restart.
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
