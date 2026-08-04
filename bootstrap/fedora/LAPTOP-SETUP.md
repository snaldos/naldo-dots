# Fedora laptop post-install checklist

Use this checklist after Fedora Workstation is installed on the laptop. It is a
profile-specific execution path through [`CLEAN-INSTALL.md`](CLEAN-INSTALL.md),
not a second package inventory. The six TSV manifests remain authoritative, so
future provider changes are made once and shared by desktop and laptop.

The intended result is GDM → Niri → Noctalia with the same portable dotfiles and
three synchronized repositories as the desktop, but with Intel graphics and a
direct SSD wallpaper worktree. Do not copy machine-local state from the desktop.

## 1. Update the fresh Fedora installation

```bash
sudo dnf upgrade --refresh
reboot
```

After logging back in, use `profile=laptop` for every manifest command:

```bash
profile=laptop
case "$profile" in laptop) ;; *) exit 2 ;; esac
```

## 2. Bootstrap GitHub access with one GCR agent

Install only the small set needed to create the device identity and clone the
configuration repository:

```bash
sudo dnf install git-core openssh-clients gcr fish
systemctl --user enable --now gcr-ssh-agent.socket
```

Create a new passphrase-protected laptop key; do not copy the desktop private
key:

```bash
install -d -m 0700 "$HOME/.ssh"
ssh-keygen -t ed25519 -a 100 -C "naldo-fedora-laptop"
```

Upload only `~/.ssh/id_ed25519.pub` to GitHub with a distinct laptop device
title. Configure the GCR socket for the current shell, future Fish shells, and
the systemd user manager:

```bash
ssh_socket="$XDG_RUNTIME_DIR/gcr/ssh"
test -S "$ssh_socket"
install -d -m 0700 "$HOME/.config/environment.d"
printf 'SSH_AUTH_SOCK=%s\n' "$ssh_socket" |
  install -m 0600 /dev/stdin \
    "$HOME/.config/environment.d/60-naldo-ssh-agent.conf"
systemctl --user set-environment SSH_AUTH_SOCK="$ssh_socket"
fish -c 'set -Ux SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"'
export SSH_AUTH_SOCK="$ssh_socket"
ssh-add "$HOME/.ssh/id_ed25519"
ssh-add -l
ssh -T git@github.com
```

Do not enable agent forwarding, start another agent in shell configuration, or
enable Tailscale SSH.

Clone the portable configuration:

```bash
git clone git@github.com:snaldos/naldo-dots.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
```

## 3. Install the shared laptop package inventory

Read [`README.md`](README.md) and execute sections 3–6 of
[`CLEAN-INSTALL.md`](CLEAN-INSTALL.md) with `profile=laptop`.
Those sections are the canonical commands for all selected software:

1. install every applicable non-optional row from `dnf-packages.tsv`;
2. enable only the reviewed Ghostty, Yazi, keyd, LazyGit, and Starship COPRs;
3. install Chrome from its reviewed official RPM;
4. add only Tailscale's official stable Fedora repository and constrain its
   package transaction to `tailscale-stable`;
5. download, inspect, and locally execute the official Herdr and Pixi installers;
6. install the reviewed JetBrainsMono Nerd Font release;
7. install every required Flatpak, including Sioyek, while leaving Vesktop
   optional;
8. install the manifest-derived npm, uv, and locked Cargo tools.

The laptop skips RPM Fusion and the entire NVIDIA section. Pixi must resolve to
`~/.pixi/bin/pixi`; its installer must run with `PIXI_NO_PATH_UPDATE=1` because
the tracked Fish configuration owns that PATH entry.

Run the read-only dependency verifier before continuing:

```bash
./bootstrap/fedora/verify.sh --profile laptop
```

## 4. Clone Notes and Wallpapers with Git LFS

Fedora's `git-lfs` package is selected in the DNF manifest. Notes currently has
no LFS payloads but keeps narrow future-attachment rules. Wallpapers stores its
compressed image payloads in LFS.

```bash
git clone git@github.com:snaldos/second-brain.git \
  "$HOME/Vaults/second-brain"
git -C "$HOME/Vaults/second-brain" lfs install --local
git -C "$HOME/Vaults/second-brain" lfs pull
git -C "$HOME/Vaults/second-brain" lfs fsck

git clone git@github.com:snaldos/Wallpapers.git "$HOME/Wallpapers"
git -C "$HOME/Wallpapers" lfs install --local
git -C "$HOME/Wallpapers" lfs pull
git -C "$HOME/Wallpapers" lfs fsck
```

The laptop uses no `/mnt/data` symlink, fstab entry, or mount guard. Initialize
and inspect the private synchronization configuration:

```bash
"$HOME/dotfiles/automation/.local/libexec/naldo/init-sync-config" \
  --config "$HOME/.config/naldo/sync/repositories.conf" \
  --template "$HOME/dotfiles/automation/.config/naldo/sync/repositories.conf.example"
hx "$HOME/.config/naldo/sync/repositories.conf"
chmod 0600 "$HOME/.config/naldo/sync/repositories.conf"
```

Require these laptop values:

```text
dotfiles_path=~/dotfiles
notes_path=~/Vaults/second-brain
wallpapers_path=~/Wallpapers
WALLPAPERS_REQUIRED_MOUNT=
```

Never restore the removed Notes credential file or copy desktop Git, LFS,
Noctalia, Tailscale, SSH-agent, or synchronization runtime state.

## 5. Deploy the laptop profile and reviewed system input files

```bash
cd "$HOME/dotfiles"
./install.sh --profile laptop
./install-system.sh --dry-run
sudo ./install-system.sh
```

Read `system/keyd/README.md`, memorize the physical
`Backspace+Escape+Enter` panic sequence, retain TTY recovery, then activate the
reviewed keyd/udev state:

```bash
sudo udevadm control --reload-rules
sudo systemctl enable --now keyd.service
sudo systemctl restart keyd.service
```

Verify the stable `/dev/input/by-id/keyd-virtual-kbd` path and its user ACL as
documented. Do not use an `eventN` path or add the account to the broad `input`
group.

## 6. Start and validate the Niri session

Log out, choose the package-provided Niri session in GDM, and log in. In
Noctalia, materialize the official Screen Recorder and Bongo Cat plugins if
needed. Keep Screen Recorder in portal mode and Bongo Cat on
`/dev/input/by-id/keyd-virtual-kbd`. Add plugin credentials only to their
machine-local files.

Run the canonical session checks from sections 15–16 of `CLEAN-INSTALL.md`, plus:

```bash
niri validate
noctalia config validate "$HOME/.config/noctalia/config.toml"
pixi --version
flatpak info com.github.ahrm.sioyek
test "$(xdg-mime query default application/pdf)" = org.pwmt.zathura.desktop
fish -lc 'test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/gcr/ssh"; ssh-add -l'
systemd-run --user --wait --collect \
  --unit=naldo-ssh-agent-check.service /usr/bin/ssh-add -l
```

Confirm Bongo Cat reacts to typing, clipboard persistence works, Sioyek and
Okular both appear as PDF alternatives, and Zathura remains the default.

## 7. Authenticate Tailscale without enabling SSH

```bash
sudo systemctl enable --now tailscaled.service
sudo tailscale up
tailscale version
tailscale status
systemctl status tailscaled.service
tailscale debug prefs
```

Confirm the laptop is online and `RunSSH=false`. Do not enable `sshd` or
Tailscale SSH as part of this setup.

## 8. Validate repositories, synchronize, then enable the timer

Keep the timer disabled while testing. Confirm all remotes and LFS objects, then
run each mutating task separately and stop on a real failure:

```bash
git -C "$HOME/dotfiles" remote -v
git -C "$HOME/Vaults/second-brain" remote -v
git -C "$HOME/Wallpapers" remote -v
git -C "$HOME/Vaults/second-brain" lfs fsck
git -C "$HOME/Wallpapers" lfs fsck
sync-control status

sync-all dotfiles
sync-all notes
sync-all wallpapers
```

After all three repositories are clean and equal to `origin/main`, enable and
exercise the timer under user-manager conditions:

```bash
sync-control enable
sync-control status
systemctl --user start sync-all.service
systemctl --user show sync-all.service -p Result -p ExecMainStatus
sync-control logs
```

If that service cannot reach GitHub, LFS, or a repository, immediately run
`sync-control disable`, fix the concrete cause, repeat the three manual tasks,
and only then enable it again.

## 9. Laptop completion boundary

The laptop is complete when the Fedora verifier passes, Niri/Noctalia and keyd
survive a reboot, Bongo Cat reacts, Tailscale is online with SSH disabled, Fish
and systemd share the GCR identity, all LFS checks pass, all repositories are
clean/synchronized, and the timer's user-manager run succeeds.

Do not add desktop NVIDIA packages, RPM Fusion, `/mnt/data`, desktop fstab state,
machine-specific input identifiers, copied private keys, or copied service state
to make the laptop resemble the desktop.
