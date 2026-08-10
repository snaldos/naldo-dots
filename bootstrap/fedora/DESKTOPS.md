# Fedora 44 desktop stack

## Selected topology

Use Fedora KDE Plasma Desktop Edition as the edition/defaults identity, add Niri
as the preferred session, and keep Plasma as the complete graphical fallback:

```text
Fedora KDE Plasma Desktop Edition
└── Plasma Login Manager
    ├── Niri → Noctalia      (preferred)
    └── KDE Plasma on KWin   (full fallback)
```

GNOME Shell/session, Mutter, and GDM are absent. This is not a purge of
GNOME-named software. Niri deliberately retains Fedora's GNOME/GTK portals,
GNOME Keyring, GCR, and Nautilus:

```text
Niri
├── Noctalia
├── gnome-keyring + gnome-keyring-pam
├── GCR SSH agent
├── xdg-desktop-portal-gnome
├── xdg-desktop-portal-gtk
└── Nautilus FileChooser delegate
```

The manifests install these anchors explicitly because a clean Fedora KDE
installation does not promise to provide Niri's GNOME integration closure.
Transitive GTK/GNOME libraries remain package-managed dependencies rather than a
name-based hand-maintained list.

Install Plasma as Fedora's complete composition rather than a hand-picked shell
subset:

```bash
dnf group info kde-desktop
sudo dnf group install kde-desktop
sudo systemctl disable plasma-setup.service
```

Fedora's group enables `plasma-setup.service`, an out-of-box wizard intended for
an unprovisioned account. Keep the package as a group member but leave that
service disabled after initial provisioning.

## Fedora edition identity

The selected release packages are:

```text
fedora-release-kde-desktop
fedora-release-identity-kde-desktop
```

The identity package owns `/usr/lib/os-release`, KDE system presets, and
`/etc/dnf/protected.d/plasma-desktop.conf`. It changes Fedora's edition branding
and defaults; it does not replace application packages or portal/keyring
choices. The expected identity is:

```bash
test "$(. /etc/os-release; printf %s "$VARIANT_ID")" = kde
rpm -q fedora-release-kde-desktop fedora-release-identity-kde-desktop
test "$(cat /etc/dnf/protected.d/plasma-desktop.conf)" = plasma-desktop
```

## Display manager and PAM boundary

Only PLM owns the display-manager alias:

```bash
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
systemctl is-enabled plasmalogin.service
systemctl is-active plasmalogin.service
! rpm -q gdm >/dev/null 2>&1
```

Fedora's `/usr/lib/pam.d/plasmalogin` integrates both
`pam_gnome_keyring.so` and `pam_kwallet5.so`. GNOME Keyring can therefore unlock
for Niri without GNOME Shell, and KWallet can unlock for Plasma without a custom
PAM patch.

Required anchors are:

- primary session: `niri`, `xwayland-satellite`, and `noctalia`;
- login/fallback: `plasma-login-manager`, `plasma-desktop`,
  `plasma-workspace`, `kwin`, and `pam-kwallet`;
- Niri secrets and SSH: `gnome-keyring`, `gnome-keyring-pam`, and `gcr`;
- portals: `xdg-desktop-portal`, `xdg-desktop-portal-gnome`,
  `xdg-desktop-portal-gtk`, and `xdg-desktop-portal-kde`;
- Niri file chooser: `nautilus`.

## Keyring behavior

The sessions use their native Secret Service implementation:

- **Niri:** GNOME Keyring owns `org.freedesktop.secrets`; GCR can retrieve the
  SSH-key passphrase from the login keyring.
- **Plasma:** KSecretD owns `org.freedesktop.secrets`; Fedora's OpenSSH agent is
  independent of KWallet and keeps an added SSH key only in memory.

Use the canonical KWallet name `kdewallet`:

```ini
[Wallet]
Default Wallet=kdewallet
First Use=false
```

Fedora's `pam-kwallet` 6.7.4 derives its login key from
`~/.local/share/kwalletd/kdewallet.salt`. A differently named wallet can produce
`Wallet failed to get opened by PAM, error code is -9`. Do not patch PAM;
recreate the wallet under the canonical name and use the login password with
Classic Blowfish when no OpenPGP secret key is available.

## SSH agent boundary

Retain Fedora's session-native agent selection:

- Niri uses GCR at `$XDG_RUNTIME_DIR/gcr/ssh`.
- Plasma's `/etc/xdg/plasma-workspace/env/ssh-agent.sh` selects
  `$XDG_RUNTIME_DIR/ssh-agent.socket`.
- Plasma's `/usr/lib/systemd/user/plasma-core.target.d/ssh-agent.conf` starts
  `ssh-agent.service`.

Do not track replacements for those Plasma files, export `SSH_AUTH_SOCK` through
`environment.d`, or set it as a Fish universal variable. There is deliberately
no custom key-loading autostart; key loading in Plasma is manual.

Verify Niri with GCR:

```bash
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/gcr/ssh"
systemctl --user is-active gcr-ssh-agent.socket
systemctl --user restart gcr-ssh-agent.service
git -C "$HOME/dotfiles" ls-remote origin refs/heads/main
```

Verify Plasma with Fedora's OpenSSH agent, then load the key manually:

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

OpenSSH forgets the key when its agent or user manager stops. Run the manual
`ssh-add` again after reboot before unattended synchronization in Plasma.

## X11 screen-sharing bridge boundary

Fedora's complete KDE group includes XWayland Video Bridge for legacy X11
applications that cannot consume native Wayland screen-cast portals. Niri,
Noctalia, native browsers, and portal-aware recorders do not need it.

The package-owned `/etc/xdg/autostart/org.kde.xwaylandvideobridge.desktop` has
no desktop restriction. Its idle full-output X11 surface can appear as a black
Niri tile through xwayland-satellite. The tracked same-ID XDG override therefore
uses:

```ini
OnlyShowIn=KDE;
```

It retains the package for Plasma, changes no package-owned file, and skips the
bridge in Niri. Do not replace this with a Niri opacity rule.

```bash
desktop-file-validate \
  "$HOME/.config/autostart/org.kde.xwaylandvideobridge.desktop"
test "$(readlink -f "$HOME/.config/autostart/org.kde.xwaylandvideobridge.desktop")" = \
  "$HOME/dotfiles/desktop/.config/autostart/org.kde.xwaylandvideobridge.desktop"
```

## Portal boundaries

Use Fedora's package-owned policies without a user override:

- Niri loads `/usr/share/xdg-desktop-portal/niri-portals.conf`, owned by the
  `niri` package. Fedora 44 selects GNOME first, GTK second, and GNOME Keyring
  for Secret Service. These package names do not create a GNOME login session.
- Plasma loads Fedora's `kde-portals.conf` and uses
  `xdg-desktop-portal-kde`, KWallet, and Plasma notifications.

Fedora 44's GNOME `FileChooser` delegates to `org.gnome.Nautilus`, so Nautilus
is a selected Niri dependency. No user `inode/directory` override is tracked:
Fedora resolves ordinary directory opens to Nautilus in Niri and Dolphin in
Plasma. Yazi remains terminal-only and is launched explicitly.

```bash
test ! -e "$HOME/.config/xdg-desktop-portal/portals.conf"
test ! -e "$HOME/.config/xdg-desktop-portal/niri-portals.conf"
rpm -qf /usr/share/xdg-desktop-portal/niri-portals.conf
```

## Acceptance gate

After a clean installation, release upgrade, or display-manager change, test
both sessions through PLM:

1. **Niri:** Noctalia, GNOME/GTK portals, browser open/save/upload, GNOME
   Keyring, silent GCR signing, NVIDIA where applicable, networking, Bluetooth,
   PipeWire/WirePlumber, recording, lock, and suspend/resume.
2. **Plasma:** KWin/Plasma, KDE portals, PolicyKit, networking, Bluetooth,
   audio, removable storage, Discover, notifications, lock/suspend, canonical
   `kdewallet`, Fedora's OpenSSH agent, and signing after explicit `ssh-add`.
3. Return to **Niri** so PLM remembers the preferred daily session.

The final session directory contains package-provided `niri.desktop` and
`plasma.desktop`, with no `gnome.desktop` or `gnome-classic.desktop`.

## Retention policy

Keep GNOME/GTK packages that provide a selected Niri or application capability.
Hidden portal, preview, online-account, printing, keyring, and file-manager
integration matters more than reducing package count. Never infer removability
from a package name.

## Recovery

PLM and full Plasma are the supported graphical fallback. If PLM fails, use a
local TTY:

```bash
sudo dnf reinstall plasma-login-manager plasma-workspace plasma-desktop kwin
sudo systemctl enable --force plasmalogin.service
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
sudo systemctl reboot
```

Installing GDM would also install GNOME Shell/session through Fedora's hard
dependencies and is therefore an explicit topology rollback, not routine
recovery.
