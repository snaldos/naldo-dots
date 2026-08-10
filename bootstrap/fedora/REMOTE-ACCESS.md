# GitHub identity, GCR, Tailscale, and inbound-access policy

This workstation uses two independent mechanisms:

- a device-specific OpenSSH key for GitHub Git transport; and
- Tailscale for private network connectivity.

Neither machine accepts inbound SSH. Private keys, GitHub CLI tokens, keyring
items, Tailscale enrollment, host keys, and agent state are machine-local and
must never be committed or copied between the desktop and laptop.

## OpenSSH client only

Install Fedora's `openssh-clients`; do not install `openssh-server`:

```bash
sudo dnf install openssh-clients
rpm -q openssh-clients
! rpm -q openssh-server >/dev/null 2>&1
test "$(systemctl is-active sshd.service 2>/dev/null || true)" = inactive
```

Removing `openssh-server` does not remove `ssh`, `scp`, `sftp`, `ssh-keygen`,
`ssh-add`, or Git-over-SSH support. It removes the unused inbound daemon and
prevents accidental future activation. Agent forwarding, `authorized_keys`,
firewall openings, and Tailscale SSH are outside this setup.

## One independent key per device

Create a passphrase-protected Ed25519 key:

```bash
install -d -m 0700 "$HOME/.ssh"
ssh-keygen -t ed25519 -a 100 -C "naldo-fedora-$profile"
stat -c '%a %n' "$HOME/.ssh" "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"
```

Expected modes are `700`, `600`, and `644`. Upload only the public key to GitHub
under a device-specific title:

```bash
cat "$HOME/.ssh/id_ed25519.pub"
```

Never track private keys, `known_hosts`, `authorized_keys`, SSH config fragments,
control sockets, agent sockets, host keys, certificates, or copied credentials.

## Session-native SSH agents

Retain the key passphrase and let each Fedora desktop select its packaged agent:

- Niri and GNOME use GCR at `$XDG_RUNTIME_DIR/gcr/ssh` and store the passphrase
  in GNOME Keyring.
- Plasma uses OpenSSH `ssh-agent` at `$XDG_RUNTIME_DIR/ssh-agent.socket`.
  KWallet remains Plasma's Secret Service, but it does not persist the key for
  OpenSSH's in-memory agent.

Do not set `SSH_AUTH_SOCK` in `environment.d`, as a Fish universal variable, or
through a tracked Plasma hook. Such global state masks Fedora's session policy
when moving between Niri, GNOME, and Plasma.

For the initial clone from Workstation GNOME or Niri, enable Fedora's GCR socket
and select it only in the current bootstrap shell:

```bash
systemctl --user enable --now gcr-ssh-agent.socket
ssh_socket="$XDG_RUNTIME_DIR/gcr/ssh"
test -S "$ssh_socket"
export SSH_AUTH_SOCK="$ssh_socket"
git ls-remote git@github.com:snaldos/naldo-dots.git refs/heads/main
```

In GCR's dialog, first check **Automatically unlock this key whenever I'm logged
in**, then enter the passphrase and click **Unlock**. Prove GNOME-Keyring
persistence by restarting GCR and using the key from a transient user service:

```bash
systemctl --user restart gcr-ssh-agent.service
systemd-run --user --wait --collect \
  --unit=naldo-gcr-unlock-check.service \
  /usr/bin/git ls-remote \
  git@github.com:snaldos/naldo-dots.git refs/heads/main
```

In a fresh Plasma login, Fedora's package-owned environment hook and target
select and start OpenSSH's agent. No custom key-loading autostart is installed.
After reboot, load the passphrase-protected key manually in a local terminal,
then prove that the exact key and user services use the selected agent:

```bash
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/ssh-agent.socket"
test "$(fish -lc 'printf %s "$SSH_AUTH_SOCK"')" = \
  "$XDG_RUNTIME_DIR/ssh-agent.socket"
systemctl --user is-active ssh-agent.socket ssh-agent.service
ssh-add "$HOME/.ssh/id_ed25519"
ssh-add -T "$HOME/.ssh/id_ed25519.pub"
systemd-run --user --wait --collect \
  --unit=naldo-openssh-agent-check.service \
  /usr/bin/git ls-remote \
  git@github.com:snaldos/naldo-dots.git refs/heads/main
```

OpenSSH does not retain the key across an agent restart or reboot, so repeat the
manual `ssh-add` before expecting unattended synchronization in Plasma. Enable
`sync-all.timer` only after the current session's transient Git check succeeds.

## GitHub CLI authentication

The SSH key authenticates Git transport but does not authorize GitHub's API.
Authenticate `gh` separately through its browser flow:

```bash
gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web
gh auth status
gh extension install dlvhdr/gh-dash
gh extension list
```

Wait until `gh auth login` itself exits. A browser `CanCreateUserNamespace()`
warning is non-fatal if the terminal reports successful authentication. The
one-time device code and status prose are output, not shell commands; never
paste the transcript back into Bash. The resulting token must be stored in the
system keyring and must remain outside Git.

## Tailscale vendor repository and enrollment

Use only Tailscale's stable official Fedora repository:

```bash
sudo dnf config-manager addrepo \
  --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install --from-repo=tailscale-stable tailscale
sudo systemctl enable --now tailscaled.service
sudo tailscale up --hostname="$machine_hostname" --ssh=false
tailscale status
test "$(tailscale debug prefs | jq -r '.RunSSH')" = false
```

The detailed clean-install step verifies the repository signing-key fingerprint
before installation. Enroll each machine interactively as a distinct device;
do not store reusable auth keys or synchronize `/var/lib/tailscale`.

Tailscale provides connectivity only. Revisit inbound access only when a concrete
requirement justifies a separate authentication, firewall, host-key, and recovery
review.
