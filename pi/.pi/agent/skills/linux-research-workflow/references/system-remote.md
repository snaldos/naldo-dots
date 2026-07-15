# Arch, systemd, Boot, Herdr, and Tailscale

## systemd: Identify the Manager First

A system unit and a user unit with the same name are unrelated. Determine the scope, loaded fragment, drop-ins, state, and recent journal before editing:

```bash
systemctl --user show UNIT -p LoadState -p ActiveState -p SubState -p FragmentPath -p DropInPaths
systemctl --user cat UNIT
systemctl --user status --no-pager UNIT
journalctl --user -b -u UNIT --no-pager -n 100

# Omit --user only for a confirmed system unit.
systemctl show UNIT -p LoadState -p ActiveState -p SubState -p FragmentPath -p DropInPaths
```

Prefer user units/drop-ins under `~/.config/systemd/user/`. Do not edit `/usr/lib/systemd/system`; system overrides belong under `/etc/systemd/system` and require explicit authorization. Validate unit files before reload:

```bash
systemd-analyze --user verify path/to/user.service
systemd-analyze calendar 'CALENDAR SPEC'
```

After an authorized unit-file edit, `daemon-reload` updates manager metadata but does not restart the service. Treat `start`, `restart`, `stop`, `enable`, `disable`, `--now`, timer activation, and lingering as separate decisions. For timers inspect both units and `systemctl --user list-timers --all`.

Under UWSM, the Wayland session is a systemd-user lifecycle. Do not restart `user@UID.service`, UWSM session targets, or import broad environment dumps as a shortcut.

### Central synchronization timer

The current user setup has one periodic timer, `sync-all.timer`, activating the
oneshot `sync-all.service`. No per-repository timers should be installed. An inactive service after a
run is normal; inspect `Result`, exit status, journal task completions, timer
schedule, and repository divergence before declaring success.

`sync-control pause` is session-only; `disable` is persistent. Interval changes
write an ignored machine-local drop-in. Starting synchronization can commit,
rebase, and push four repositories, so it is never a read-only systemd test.
Read [dotfiles-sync-backup.md](dotfiles-sync-backup.md) for exact commands,
profile routing, and snapshot boundaries.

## Arch Package Inspection

Use read-only package evidence before changing dependencies:

```bash
pacman -Q TOOL
pacman -Qi TOOL
pacman -Qo "$(command -v TOOL)"
pacman -Ql TOOL
pacman -Qm                 # foreign/AUR packages
```

Inspect reverse dependencies and package provenance before proposing removal. Do not assume an AUR helper, run partial upgrades, install into system Python, or execute package transactions without explicit approval. Prefer `uv` for normal Python work and `pixi` when native/conda/CUDA dependencies justify it.

## systemd-boot and UKI

This machine currently boots a unified kernel image through systemd-boot, but verify every time:

```bash
bootctl status --no-pager
bootctl list --no-pager
bootctl -p                 # ESP
bootctl -x                 # $BOOT
```

A permission error while opening the ESP does not prove systemd-boot is absent. Establish the complete generation path before changing anything: boot loader entry type, ESP mount, UKI location, kernel package, `/etc/kernel/cmdline`, mkinitcpio config/presets/hooks, pacman hooks, and Secure Boot state.

Do not run `bootctl install/update/remove/set-*`, regenerate initramfs/UKIs, change kernel parameters, or write `/boot` or `/etc` without explicit approval and a recovery/rollback plan. Reinspect the produced UKI and `bootctl list` after any authorized boot change.

The private `~/backups` repository stores an allowlisted reconstruction
snapshot, not a boot image or automatic restore. Its unprivileged timer run may
preserve an older copy of protected files; a fresh protected capture requires an
explicitly authorized `sync.sh --sudo`. Never restore `/etc` or `/boot` wholesale.

## Herdr Sessions

Herdr is the persistent workspace/session layer, not just a terminal child process.

- Discover the loaded config from `herdr --help`; normally `~/.config/herdr/config.toml`, with `HERDR_CONFIG_PATH` as an override.
- Account for `HERDR_SESSION` and `HERDR_SOCKET_PATH`: named sessions can have distinct servers, sockets, and logs.
- Use `herdr status [server|client]`, `herdr session list`, `herdr api --help`, and `herdr --default-config` for the installed schema.
- API snapshots, pane metadata, logs, and session files can reveal commands, paths, and work context. Keep inspection targeted.
- After an authorized config edit, validate TOML, use `herdr server reload-config` for the intended session, then inspect status and a bounded log tail.

Never stop/delete a session, stop the server, update/handoff it, or disrupt panes as a validation step. Do not edit generated agent integrations. Check with `herdr integration status`; refresh Pi's integration with `herdr integration install pi` only when requested.

## Tailscale and Remote Continuity

Tailscale is a system daemon and may be the path keeping the current session reachable.

Safe identification:

```bash
tailscale version
systemctl show tailscaled.service -p ActiveState -p SubState -p FragmentPath
# Local inspection only; redact account, host, peer, and IP information.
tailscale status --peers=false
```

Use a bounded `tailscale ping <known-target>` only for an explicit connectivity test. Distinguish Tailscale reachability, normal SSH, Tailscale SSH, and `herdr --remote`; success at one layer does not prove the next.

Never read, copy, or expose the tailscaled state file or auth keys. Do not print full status JSON or peer lists unnecessarily. `tailscale set` changes only named preferences; `tailscale up` can require a complete desired configuration. Neither is a read-only probe. `down`, `logout`, account switching, SSH/route/DNS/exit-node changes, `serve`, `funnel`, daemon restarts, and firewall changes require explicit approval.

Before any potentially disconnecting action:

1. determine whether the user is local or connected through Tailscale/SSH/Herdr
2. map the exact connection path and active Herdr session
3. preserve a second recovery path or local access
4. stage and validate static changes first
5. perform the disruptive action separately, with explicit approval
