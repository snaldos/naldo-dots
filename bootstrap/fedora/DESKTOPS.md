# Fedora 44 desktop stack

## Selected topology

This repository targets one Fedora 44 machine with two supported Wayland
desktops:

```text
Fedora boot → GDM → Niri → Noctalia       (primary)
                  └→ KDE Plasma on KWin   (full fallback)
```

Install Plasma as Fedora's coherent desktop composition, not as a hand-picked
collection of shell packages:

```bash
dnf group info kde-desktop
sudo dnf group install kde-desktop
sudo systemctl disable plasma-setup.service
```

Fedora's group enables `plasma-setup.service`, an out-of-box wizard that runs
before the display manager when `/etc/plasma-setup-done` is absent. Workstation
has already provisioned the account, so keep the package as a group member but
disable that service before rebooting.

The curated DNF manifest records the required Plasma anchors and applications
that the verifier checks. Fedora's `kde-desktop` comps group owns the complete,
release-specific dependency and default-package closure. Start with Fedora's
Plasma defaults; do not export KDE session variables globally or add Plasma
configuration that changes the working Niri session.

GNOME remains installed during the transition. This is intentional: a package
being GNOME-related is not evidence that it is redundant.

## Display manager decision

GDM remains the selected display manager. On Fedora 44, the KDE group also
installs the new `plasma-login-manager`, but Fedora's display-manager preset is
first-installed-wins, so that package does not replace an existing GDM link.
Verify the actual boot path rather than package presence:

```bash
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/gdm.service
systemctl is-active gdm.service
systemctl is-enabled gdm.service
systemctl is-enabled plasmalogin.service || true
```

Keeping GDM is conservative here: it already starts the package-provided Niri
session reliably, supports Plasma sessions, unlocks the existing GNOME login
keyring, and has a known recovery path. Plasma Login Manager does have one
concrete advantage: its Fedora PAM stack integrates both GNOME Keyring and
KWallet, whereas GDM's integrates GNOME Keyring only. That may avoid a separate
KWallet prompt in Plasma, but it does not yet outweigh changing a proven Niri
login path to a new Fedora 44 component. Test the actual Plasma wallet behavior
first. Re-evaluate only if it is a real problem and both Niri and Plasma pass a
separate Plasma Login Manager trial; do not patch GDM's PAM stack casually or
switch merely to reduce the number of GNOME packages.

## Portal and keyring boundaries

Desktop-specific portal policy is required on a multi-desktop machine:

- Niri uses the tracked `niri-portals.conf`, preferring GNOME and GTK backends
  and GNOME Keyring for Secret Service.
- Plasma uses Fedora's package-provided `kde-portals.conf` and
  `xdg-desktop-portal-kde`.
- GNOME uses Fedora's package-provided `gnome-portals.conf`.

Do not add a user-level generic `portals.conf`: its higher-precedence fallback
would mask Fedora's desktop-specific KDE and GNOME files. Installing the KDE
backend does not change Niri because Niri has an explicit desktop-specific
selection.

Keep `gnome-keyring`, `gnome-keyring-pam`, `gcr`,
`xdg-desktop-portal-gnome`, and `xdg-desktop-portal-gtk`. They provide the
proven Niri secret, SSH, portal, and GDM integration; they are not candidates
for a KDE-purity cleanup.

## Plasma acceptance gate

A package transaction proves only installation. Before any GNOME desktop
cleanup, log out of Niri, select **Plasma** in GDM, and test a real session.
Require all of the following:

1. login, logout, lock, unlock, suspend, and resume work;
2. all displays, scaling, refresh rates, keyboard, pointer, and NVIDIA rendering
   behave correctly;
3. networking, Bluetooth, audio input/output, removable storage, and power
   controls work;
4. Dolphin, Konsole, System Settings, Discover, notifications, and PolicyKit
   prompts open normally;
5. KWallet and Secret Service behavior is usable, noting whether GDM login
   causes a separate KWallet prompt;
6. file chooser, screenshot, screen sharing/recording, and Secret Service portal
   workflows use the Plasma session correctly; and
7. logging back into Niri restores unchanged Niri, Noctalia, keyring, and portal
   behavior.

Useful non-private checks from Konsole are:

```bash
printf 'type=%s desktop=%s session=%s\n' \
  "$XDG_SESSION_TYPE" "$XDG_CURRENT_DESKTOP" "$XDG_SESSION_DESKTOP"
plasmashell --version
systemctl --user --no-pager --full status \
  plasma-workspace.target plasma-xdg-desktop-portal-kde.service \
  plasma-polkit-agent.service
ps -u "$(id -u)" -o comm=,args= | grep xdg-desktop-portal
```

Expected session identity is Wayland and KDE/Plasma. Do not restart or replace
the display manager as part of this desktop test.

## GNOME reduction gate

GNOME removal is phase two and remains blocked until the Plasma acceptance gate
has passed in real use. Even afterward, do not run `dnf group remove
gnome-desktop` blindly: the group contains GDM and the portal backends retained
for Niri.

First separate four sets:

1. **retain for the selected login path:** GDM and its runtime dependencies;
2. **retain for Niri/app integration:** GNOME Keyring, GCR, GNOME/GTK portals,
   GTK libraries, and any deliberately used applications;
3. **retain by preference:** useful standalone GNOME tools such as Disks may
   remain even when Plasma is the fallback desktop; and
4. **candidate redundant desktop surface:** the GNOME session entry, GNOME-only
   shell extensions, welcome/tour software, and duplicate applications that
   have no remaining use.

Preview every explicit candidate transaction and require zero removals from the
first two sets, Niri, Noctalia, Plasma, graphics, audio, networking, or the
selected applications. Remove small reviewed batches, reboot, and repeat both
desktop checks. Package provenance and dependency reasons matter more than a
name prefix.

Until that gate is confirmed, the supported state is **Niri + Plasma + retained
GNOME**, with GDM selected. That is a valid incremental state, not a failed
cutover.
