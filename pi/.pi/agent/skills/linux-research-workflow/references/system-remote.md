# systemd, keyd, Herdr, and remote continuity

## Identify the systemd manager

System and user units with the same name are unrelated. Inspect scope, fragment,
drop-ins, state, and bounded logs before editing:

```bash
systemctl --user show UNIT -p LoadState -p ActiveState -p SubState -p FragmentPath -p DropInPaths
systemctl --user cat UNIT
journalctl --user -b -u UNIT --no-pager -n 100

# Omit --user only for a confirmed system unit.
systemctl show UNIT -p LoadState -p ActiveState -p SubState -p FragmentPath -p DropInPaths
```

User units belong under `~/.config/systemd/user/`. Validate before an authorized
reload:

```bash
systemd-analyze --user verify PATH/TO/UNIT
systemd-analyze calendar 'CALENDAR SPEC'
```

A daemon reload changes inventory but does not restart a service. Starting,
stopping, enabling, disabling, reloading, and restarting are separate decisions.
The repository synchronization timer is intentionally disabled until the user
runs `sync-control enable`.

## Root-owned keyd boundary

The reviewed sources are `system/keyd/default.conf` and
`system/udev/69-keyd-bongocat.rules`, outside every Stow package.
`install-system.sh` validates both before printing/writing only
`/etc/keyd/default.conf` and
`/etc/udev/rules.d/69-keyd-bongocat.rules` with explicit owner and modes. It
does not install keyd, reload udev, change service state, or trigger devices.

Noctalia Bongo Cat explicitly reads `/dev/input/by-id/keyd-virtual-kbd`; current
plugin behavior does not auto-detect it. The rule matches keyd's exact upstream
uinput name and grants the active logind session `uaccess` without a broad
`MODE=` or `input`-group policy. Before explicit activation, know the
`Backspace+Escape+Enter` panic sequence and keep a TTY/alternate login available.
See `system/keyd/README.md` for activation, ACL verification, and recovery.

## Fedora package evidence

Dependency manifests and current package-source uncertainty live under
`bootstrap/fedora/`. Inspect `dnf info`/`dnf repoquery` and the enabled repository
set before proposing a transaction. Never silently add a COPR or third-party
repository, execute a downloaded shell script, or turn desktop configuration
into an updater. Use uv for ordinary Python projects and Pixi when native,
conda, CUDA, or cross-platform scientific dependencies justify it.

## Herdr sessions

Herdr is the persistent workspace/session layer.

- Discover the loaded config and installed schema from `herdr --help` and
  `herdr --default-config`.
- Account for `HERDR_SESSION` and `HERDR_SOCKET_PATH`.
- Keep API snapshots, pane metadata, logs, and sessions private and inspect only
  the bounded fields needed.
- Validate TOML before an explicitly authorized config reload.
- Never stop/delete a session or disrupt panes as a validator.
- Do not edit generated agent integrations; inspect with
  `herdr integration status` and reinstall only when requested.

## Tailscale and connection safety

Tailscale's only selected source is its official stable Fedora RPM repository,
`https://pkgs.tailscale.com/stable/fedora/tailscale.repo`. It is an external
vendor repository, not Fedora, COPR, Flatpak, or a remote shell installer.
Service activation and `sudo tailscale up` are explicit interactive clean-install
steps; no installer enrolls a machine or stores an auth key.

Inspect local version/service state without printing account, peer, hostname, or
address inventories. Never read or synchronize `/var/lib/tailscale`, node keys,
pre-auth keys, credentials, or machine enrollment state. Preference changes,
login/logout, routes, DNS, SSH mode, restarts, and firewall changes require
explicit approval.

## OpenSSH

Only Fedora `openssh-clients` is selected. Device-specific, passphrase-protected
Ed25519 keys, `known_hosts`, local host fragments, sockets, GCR state, and GitHub
CLI tokens remain machine-local. Do not print private key or token contents.
`openssh-server`, `authorized_keys`, agent forwarding, firewall openings, and
Tailscale SSH are absent. GCR must store the key passphrase in the active Secret
Service—GNOME Keyring under Niri and canonical `kdewallet` under Plasma—and pass
a post-restart systemd Git operation before repository synchronization is
enabled.

Fedora 44 Plasma otherwise exports `$XDG_RUNTIME_DIR/ssh-agent.socket` and pulls
`ssh-agent.service` through `plasma-core.target`. The tracked `desktop` package
shadows only that vendor target drop-in and exports `$XDG_RUNTIME_DIR/gcr/ssh`
from Plasma's user environment hook. In a fresh Plasma login, verify the ambient
Bash, Fish, and systemd-manager socket, require the OpenSSH agent service/socket
to be inactive, and run signing without a per-command socket override. An
explicit `SSH_AUTH_SOCK=...` can hide a broken session policy.

Before a potentially disconnecting operation:

1. determine whether access is local, SSH, Tailscale, or Herdr-mediated;
2. map the exact active path;
3. preserve a second recovery route or local access;
4. validate static changes first;
5. perform the disruptive action separately and explicitly.
