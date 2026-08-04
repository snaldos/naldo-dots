# Tailscale, OpenSSH, and machine-local identity

Remote access is intentional on both machines, but enrollment, host
authorization, daemon activation, firewall policy, and private key material are
never dotfile-installer responsibilities.

## Tailscale: official stable Fedora repository only

Tailscale's current official Fedora instructions publish this repository file:

```text
https://pkgs.tailscale.com/stable/fedora/tailscale.repo
```

It enables `repo_gpgcheck=1` and `gpgcheck=1` and names Tailscale's repository
key. Inspect the downloaded repository file and key URL before the explicit
system transaction. This is an **official external vendor RPM repository**, not
a COPR, Flatpak, unstable/RC channel, or generic `curl | sh` installation.
Fedora 44 metadata now also lists a Fedora-built `tailscale` package, but it is
intentionally not selected: this workstation policy follows the requested
Tailscale stable vendor channel, and DNF5 transactions below use `--from-repo`
to prevent provider ambiguity.

Fedora 44 uses DNF5's `addrepo --from-repofile` syntax. Interactive setup is
performed separately on each fresh machine:

```bash
sudo dnf config-manager addrepo \
  --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install --from-repo=tailscale-stable tailscale
sudo systemctl enable --now tailscaled.service
sudo tailscale up
tailscale version
tailscale status
systemctl status tailscaled.service
```

The final `up` authenticates the new Fedora installation as a new device. Never
store a reusable auth/pre-auth key or automate tailnet enrollment. Do not track,
Stow, copy, or synchronize `/var/lib/tailscale`, node keys, daemon state,
tailnet credentials, or machine enrollment. `install-system.sh` does not manage
any of them.

## Fedora OpenSSH packages

Install the official packages `openssh-clients` and `openssh-server`. They
provide `ssh`, `scp`, `sftp`, `ssh-keygen`, `ssh-copy-id`, `ssh-add`, `sshd`, and
`sshd.service`. Installing the server does not mean it should listen yet.
Enable it only on a machine that deliberately accepts inbound connections:

```bash
sudo sshd -t
sudo systemctl enable --now sshd.service
ssh -V
systemctl status sshd.service
```

The dotfiles do not open a firewall port, weaken Fedora defaults, enable root
login, disable password authentication, change server ciphers, create
`authorized_keys`, or enable Tailscale SSH. Normal OpenSSH public-key
authentication over the Tailscale network is preferred. Tailscale SSH is an
optional alternative, not a required replacement.

## Fresh device-specific keys

Before erasing the old installation, ensure browser access to GitHub, working
2FA, and offline recovery methods/codes. Do not assume an old private key can be
recovered afterward and do not copy it to the new installation by default.

Create the directory without exposing existing contents:

```bash
install -d -m 0700 "$HOME/.ssh"
```

Generate a passphrase-protected Ed25519 key independently on each machine:

```bash
# Desktop
ssh-keygen -t ed25519 -a 100 -C "naldo-fedora-desktop"

# Laptop
ssh-keygen -t ed25519 -a 100 -C "naldo-fedora-laptop"
```

The comments are device labels, not hardcoded email identities. Give each public
key a distinct GitHub device title so either machine can be revoked separately.
Display and upload **only** the `.pub` file, then validate:

```bash
cat "$HOME/.ssh/id_ed25519.pub"
ssh -T git@github.com
```

Expected permissions, checked by metadata rather than printing private content:

```bash
stat -c '%a %n' "$HOME/.ssh" "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"
# directory 700; private key 600; public key 644
```

If a portable client config is added later, an OpenSSH-accepted restrictive mode
such as `0600` is appropriate. It may include ignored
`~/.ssh/config.d/*.conf` or `~/.ssh/config.local`; machine-specific hosts belong
there. This repository intentionally does not currently own an SSH Stow package.

Never commit private keys, `id_*` device identity files, PEM keys,
`known_hosts`, `known_hosts.old`, `authorized_keys`, `config.local`, control or
agent sockets, copied host keys, or private certificates. Public keys are not
secret but remain machine-local by default.

## One Fedora GCR agent for Fish and systemd

Use the Fedora `gcr` package's socket-activated agent rather than starting an
agent in Fish, Ghostty, or Pi. Its per-user socket is
`$XDG_RUNTIME_DIR/gcr/ssh`. Enable it and persist only the socket environment,
not key material:

```bash
systemctl --user enable --now gcr-ssh-agent.socket
ssh_socket="$XDG_RUNTIME_DIR/gcr/ssh"
test -S "$ssh_socket"

install -d -m 0700 "$HOME/.config/environment.d"
printf 'SSH_AUTH_SOCK=%s\n' "$ssh_socket" |
  install -m 0600 /dev/stdin \
    "$HOME/.config/environment.d/60-naldo-ssh-agent.conf"
systemctl --user set-environment SSH_AUTH_SOCK="$ssh_socket"
fish -c 'set -Ux SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"'

export SSH_AUTH_SOCK="$ssh_socket"  # current provisioning shell only
ssh-add "$HOME/.ssh/id_ed25519"
ssh-add -l
ssh -T git@github.com
```

`environment.d` is read when the user manager starts; the Fish universal value
is machine-local. Neither belongs in Git. New Fish/Ghostty/Pi processes and
systemd user services then use the same socket. Validate the user-manager path
without creating a persistent test unit:

```bash
systemd-run --user --wait --collect \
  --unit=naldo-ssh-agent-check.service /usr/bin/ssh-add -l
```

Do not configure `ForwardAgent`, a per-shell `ssh-agent`, or Tailscale SSH.

## Authorizing desktop and laptop

After confirming the target host identity and address over Tailscale, copy only
the public key:

```bash
ssh-copy-id USER@VERIFIED_TAILSCALE_HOST
ssh USER@VERIFIED_TAILSCALE_HOST
```

Inspect the host fingerprint through an independent trusted channel before
accepting it. Do not commit `authorized_keys`; repeat authorization explicitly
in the opposite direction only if needed.
