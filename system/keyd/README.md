# keyd and Noctalia Bongo Cat system integration

This is the complete root-owned configuration managed by `install-system.sh`:

```text
system/keyd/default.conf                 → /etc/keyd/default.conf
system/udev/69-keyd-bongocat.rules       → /etc/udev/rules.d/69-keyd-bongocat.rules
```

It is outside every GNU Stow package. Desktop and laptop use the same mapping
and virtual-device rule, so the system installer has no machine profile.

## Why the udev rule is required

Noctalia v5's official Bongo Cat plugin 1.1.4 does not auto-detect keyboards.
Keyboard animation is disabled until `input_devices` names one or more paths,
and the plugin recommends stable `/dev/input/by-id/` or `/dev/input/by-path/`
paths instead of changing `eventN` names. The tracked widget deliberately reads:

```text
/dev/input/by-id/keyd-virtual-kbd
```

Upstream keyd 2.6.0 defines its uinput keyboard name exactly as
`keyd virtual keyboard` (`VKBD_NAME` in `src/keyd.h`). The reviewed rule matches
only that named input parent and its `event*` child, creates the stable symlink,
and adds `uaccess`:

```udev
KERNEL=="event*", SUBSYSTEM=="input", ATTRS{name}=="keyd virtual keyboard", SYMLINK+="input/by-id/keyd-virtual-kbd", TAG+="uaccess"
```

There is no `MODE=` override and no world-readable or world-writable input-device
permission. `uaccess` lets systemd-logind grant the active local session access;
do not add the user permanently to the broad `input` group.

## Install without activation

Install keyd first from the reviewed `alternateved/keyd` COPR documented under
`bootstrap/fedora/`. Then inspect and run:

```bash
./install-system.sh --dry-run
sudo ./install-system.sh
```

The installer validates `default.conf`, validates the exact rule text, copies
both files as root-owned mode `0644`, and is safe to repeat. It does not install
keyd, reload udev, restart keyd, or trigger any device.

## Explicit activation and verification

Know the recovery sequence below before recreating the virtual keyboard. Reload
the rule database, then restart keyd once so its uinput device is recreated and
processed by the new rule:

```bash
sudo udevadm control --reload-rules
sudo systemctl restart keyd.service
```

Restarting keyd is the least invasive reliable recreation method: `keyd reload`
reloads mappings but need not replace the existing uinput device. Do not run a
broad `udevadm trigger` against unrelated input devices.

Verify the exact link, target, tags, and event stream:

```bash
udevadm info /dev/input/by-id/keyd-virtual-kbd
readlink -f /dev/input/by-id/keyd-virtual-kbd
ls -l /dev/input/by-id/keyd-virtual-kbd
getfacl "$(readlink -f /dev/input/by-id/keyd-virtual-kbd)"
keyd monitor
```

`udevadm info` must show `DEVLINKS=/dev/input/by-id/keyd-virtual-kbd` and
`uaccess` in `TAGS`/`CURRENT_TAGS`. `getfacl` should show an ACL for the active
logged-in user, not a world-writable device.

## Emergency recovery

A bad remap can make normal typing impossible.

1. Press `Backspace+Escape+Enter` together. keyd documents this panic sequence
   as terminating keyd and restoring the physical keyboard.
2. Switch to a text console, another local session, or a recovery shell.
3. Stop keyd if necessary: `sudo systemctl stop keyd.service`.
4. Restore or remove `/etc/keyd/default.conf`, then validate it with
   `sudo keyd check /etc/keyd/default.conf`.
5. Start keyd only after validation: `sudo systemctl start keyd.service`.
6. Keep the alternate console/login path available while testing mappings.

The repository stores neither device nodes nor keyd runtime state.
