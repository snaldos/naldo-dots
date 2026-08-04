# Fedora laptop: complete ordered setup

Run this file from top to bottom after installing Fedora Workstation on the
laptop. Execute one code block at a time, read its output, and stop on any
unexpected repository, signature, package, device, service, or validation
result. This is a human-run checklist, not an unattended installer.

The target is:

```text
Fedora Workstation → GDM → package-provided Niri → Noctalia
```

The laptop shares the tracked configuration and software policy with the
desktop, but it has its own SSH key, GCR session, Tailscale enrollment, Noctalia
state, and synchronization state. It uses Intel graphics and a direct
`~/Wallpapers` SSD worktree. Never copy desktop private keys, `/mnt/data`, fstab,
NVIDIA, Noctalia runtime, or service state.

The six TSV manifests in this directory remain the package/provider source of
truth. Commands below derive inventories from them instead of maintaining a
second package list.

## 1. Update the fresh Fedora installation

Open a Bash terminal and update Fedora:

```bash
sudo dnf upgrade --refresh
sudo systemctl reboot
```

After logging back into GNOME, reopen a Bash terminal and confirm the audited
Fedora baseline. If this is no longer Fedora 44, stop and review provider/package
changes before continuing.

```bash
cat /etc/fedora-release
test "$(rpm -E %fedora)" = 44
```

## 2. Bootstrap the laptop identity and GitHub access

Install only what is needed to create a device-specific key and clone the
configuration repository:

```bash
sudo dnf install git-core openssh-clients gcr fish
systemctl --user enable --now gcr-ssh-agent.socket
```

Create a new passphrase-protected key. Do not copy the desktop key:

```bash
install -d -m 0700 "$HOME/.ssh"
ssh-keygen -t ed25519 -a 100 -C "naldo-fedora-laptop"
stat -c '%a %n' "$HOME/.ssh" "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"
```

Expected modes are `700`, `600`, and `644`. Display and upload **only** the
public key to GitHub under a distinct laptop device name:

```bash
cat "$HOME/.ssh/id_ed25519.pub"
```

After adding it on GitHub, configure the one Fedora GCR agent used by Bash,
Fish, Git, Pi, and systemd user services:

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

GitHub's successful `ssh -T` greeting normally exits with status 1 because it
does not provide shell access. Prove Git transport independently:

```bash
git ls-remote git@github.com:snaldos/naldo-dots.git refs/heads/main
systemd-run --user --wait --collect \
  --unit=naldo-bootstrap-agent-check.service /usr/bin/ssh-add -l
```

Do not configure agent forwarding, start another SSH agent, enable `sshd`, or
enable Tailscale SSH.

## 3. Clone the configuration and select the laptop profile

```bash
git clone git@github.com:snaldos/naldo-dots.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
profile=laptop
case "$profile" in laptop) ;; *) exit 2 ;; esac
```

Inspect the provider overview and manifests before changing the system:

```bash
hx bootstrap/fedora/README.md
hx bootstrap/fedora/dnf-packages.tsv
hx bootstrap/fedora/external-tools.tsv
hx bootstrap/fedora/flatpaks.tsv
```

## 4. Install the manifest-selected Fedora packages

Confirm only expected Fedora repositories are currently enabled, derive all
required laptop rows, review the printed list, and then install it:

```bash
dnf repolist --enabled
mapfile -t fedora_packages < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $2 != "optional" && ($NF == "all" || $NF == profile) {
    print $1
  }
' bootstrap/fedora/dnf-packages.tsv)
printf '  %s\n' "${fedora_packages[@]}"
sudo dnf install "${fedora_packages[@]}"
```

Optional rows such as Neovim, Orca, and eza are deliberately not installed by
that command. Do not add a fallback provider for a required row.

## 5. Install the reviewed external providers

Print the applicable external source boundaries first:

```bash
awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) {
    print $1 "\t" $3 "\t" $4
  }
' bootstrap/fedora/external-tools.tsv
```

### 5.1 Reviewed COPRs

Review each COPR page/spec/build history before accepting its prompt. Enable
only these selected repositories:

```bash
sudo dnf copr enable scottames/ghostty
sudo dnf copr enable lihaohong/yazi
sudo dnf copr enable alternateved/keyd
sudo dnf install ghostty yazi keyd

sudo dnf copr enable dejan/lazygit
sudo dnf copr enable atim/starship
sudo dnf install lazygit starship
```

DNF owns all five installations and their updates.

### 5.2 Google Chrome official RPM

Chrome is a selected secondary browser. Download the official RPM, inspect its
signature, and install that reviewed local file:

```bash
curl --proto '=https' --tlsv1.2 --fail --location \
  --output /tmp/google-chrome-stable_current_x86_64.rpm \
  https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
rpm --verbose --checksig -v /tmp/google-chrome-stable_current_x86_64.rpm
sudo dnf install /tmp/google-chrome-stable_current_x86_64.rpm
rm /tmp/google-chrome-stable_current_x86_64.rpm
```

Stop if the signature does not match Google's published signing-key boundary.

### 5.3 Tailscale official stable repository

Install from Tailscale's vendor repository, constrained because Fedora also
publishes a package with the same name. Do not enroll the machine yet:

```bash
sudo dnf config-manager addrepo \
  --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install --from-repo=tailscale-stable tailscale
```

### 5.4 Herdr official installer

Never pipe an installer from the network into a shell. Download it, inspect the
entire local file in Helix, run it, select the stable channel, and create the
machine-local provider receipt used by `naldo-update`:

```bash
herdr_installer="$(mktemp "${TMPDIR:-/tmp}/herdr-install.XXXXXX.sh")"
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$herdr_installer" https://herdr.dev/install.sh
sh -n "$herdr_installer"
hx "$herdr_installer"
sh "$herdr_installer"
rm -f -- "$herdr_installer"

herdr_path="$(readlink -f -- "$(command -v herdr)")"
test "$herdr_path" = "$(readlink -m -- "$HOME/.local/bin/herdr")"
herdr channel set stable
test "$(herdr channel show)" = stable
herdr --version

receipt_dir="${XDG_DATA_HOME:-$HOME/.local/share}/naldo/provider-receipts"
install -d -m 0700 "$receipt_dir"
receipt_tmp="$(mktemp --tmpdir="$receipt_dir" '.herdr-receipt.XXXXXX')"
printf 'source=https://herdr.dev/install.sh\nbinary=%s\n' "$herdr_path" >"$receipt_tmp"
chmod 0600 "$receipt_tmp"
mv -f -- "$receipt_tmp" "$receipt_dir/herdr-official-installer"
```

### 5.5 Pixi official installer

Download and inspect Pixi's installer locally. The tracked Fish configuration
owns PATH, so suppress installer shell edits:

```bash
pixi_installer="$(mktemp "${TMPDIR:-/tmp}/pixi-install.XXXXXX.sh")"
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$pixi_installer" https://pixi.sh/install.sh
sh -n "$pixi_installer"
hx "$pixi_installer"
PIXI_NO_PATH_UPDATE=1 sh "$pixi_installer"
rm -f -- "$pixi_installer"

test -x "$HOME/.pixi/bin/pixi"
test "$(readlink -f -- "$HOME/.pixi/bin/pixi")" = \
  "$(readlink -m -- "$HOME/.pixi/bin/pixi")"
"$HOME/.pixi/bin/pixi" --version
```

### 5.6 JetBrainsMono Nerd Font

Install only the reviewed Nerd Fonts `v3.5.0` base-family TTFs. The expected
archive digest is part of the reviewed release record:

```bash
font_work="$(mktemp -d "${TMPDIR:-/tmp}/jetbrains-font.XXXXXX")"
font_archive="$font_work/JetBrainsMono.zip"
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$font_archive" \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/JetBrainsMono.zip
printf '%s  %s\n' \
  9577de1ae84ec523df16fc69bac5338b89497a5b4fb91489e2dcb79dc06ac2b5 \
  "$font_archive" | sha256sum --check -

font_stage="$font_work/base-family"
python3 - "$font_archive" "$font_stage" <<'PY'
from pathlib import Path, PurePosixPath
import re
import sys
import zipfile

archive = Path(sys.argv[1])
target = Path(sys.argv[2])
pattern = re.compile(r"JetBrainsMonoNerdFont-[A-Za-z]+(?:Italic)?\.ttf")
target.mkdir()
with zipfile.ZipFile(archive) as source:
    selected = [
        item for item in source.infolist()
        if pattern.fullmatch(PurePosixPath(item.filename).name)
    ]
    if len(selected) != 16:
        raise SystemExit(f"expected 16 base-family TTFs, found {len(selected)}")
    for item in selected:
        name = PurePosixPath(item.filename).name
        (target / name).write_bytes(source.read(item))
PY

font_target="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
rm -rf -- "$font_target"
install -d -m 0755 "$font_target"
install -m 0644 "$font_stage"/*.ttf "$font_target"/
fc-cache -f "$font_target"
rm -rf -- "$font_work"

fc-list --format='%{family}\n' | awk -F ',' '
  {
    for (i = 1; i <= NF; i++) {
      value = $i
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      if (value == "JetBrainsMono Nerd Font") found = 1
    }
  }
  END { exit !found }
'
```

The laptop skips RPM Fusion and every NVIDIA command.

## 6. Install the selected user Flatpaks

Add Flathub only if absent, derive all required laptop IDs, review them, and
install them for the user:

```bash
flatpak remote-add --user --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
mapfile -t flatpak_ids < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $2 != "optional" && ($NF == "all" || $NF == profile) {
    print $1
  }
' bootstrap/fedora/flatpaks.tsv)
printf '  %s\n' "${flatpak_ids[@]}"
flatpak install --user flathub "${flatpak_ids[@]}"
flatpak info --user --show-permissions com.github.ahrm.sioyek
```

Zen remains the default browser. Zathura remains the default PDF handler;
Okular and the community-maintained Sioyek Flatpak are additional handlers.
Vesktop is optional and is not installed by this command. The GPU Screen
Recorder Flatpak is the sole recorder provider.

## 7. Install Helix language tools and development CLIs

Use a user npm prefix—never root npm:

```bash
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
mapfile -t npm_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && ($NF == "all" || $NF == profile) {
    print $1
  }
' bootstrap/fedora/npm-packages.tsv)
printf '  %s\n' "${npm_tools[@]}"
npm install --global "${npm_tools[@]}"
```

Install only active required uv tools:

```bash
mapfile -t uv_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && $4 == "active" &&
    ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/uv-tools.tsv)
printf '  %s\n' "${uv_tools[@]}"
for tool in "${uv_tools[@]}"; do
  uv tool install "$tool"
done
```

Print the locked Cargo commands and review every source/version:

```bash
mapfile -t cargo_commands < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) { print $5 }
' bootstrap/fedora/cargo-tools.tsv)
printf '%s\n' "${cargo_commands[@]}" | nl -ba
```

Then execute each reviewed command one at a time, pressing Enter before each
installation:

```bash
for cargo_command in "${cargo_commands[@]}"; do
  printf '\nNext command:\n  %s\n' "$cargo_command"
  read -r -p 'Press Enter to run it, or Ctrl-C to stop: '
  bash -lc "$cargo_command"
done
```

For this provisioning shell only, expose the user binary locations and verify
all configured commands:

```bash
export PATH="$HOME/.npm-global/bin:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.pixi/bin:$PATH"
while IFS= read -r command; do
  command -v "$command"
done < <(
  awk -F '\t' -v profile="$profile" '
    $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) {
      n = split($2, commands, ",")
      for (i = 1; i <= n; i++) print commands[i]
    }
  ' bootstrap/fedora/cargo-tools.tsv
)
```

Taplo must resolve to Cargo's LSP-capable build, not npm:

```bash
test "$(readlink -f -- "$(command -v taplo)")" = "$HOME/.cargo/bin/taplo"
taplo --version
```

## 8. Clone Notes and Wallpapers with Git LFS

Clone both repositories independently using the new laptop identity:

```bash
install -d "$HOME/Vaults"
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

The laptop uses the real `~/Wallpapers` directory on its SSD—no symlink, fstab
entry, `/mnt/data`, or required-mount guard.

Initialize the private synchronization configuration, inspect it, and require
the exact laptop paths:

```bash
"$HOME/dotfiles/automation/.local/libexec/naldo/init-sync-config" \
  --config "$HOME/.config/naldo/sync/repositories.conf" \
  --template "$HOME/dotfiles/automation/.config/naldo/sync/repositories.conf.example"
hx "$HOME/.config/naldo/sync/repositories.conf"
chmod 0600 "$HOME/.config/naldo/sync/repositories.conf"

grep -Fx 'dotfiles_enabled=true' "$HOME/.config/naldo/sync/repositories.conf"
grep -Fx 'dotfiles_path=~/dotfiles' "$HOME/.config/naldo/sync/repositories.conf"
grep -Fx 'notes_enabled=true' "$HOME/.config/naldo/sync/repositories.conf"
grep -Fx 'notes_path=~/Vaults/second-brain' "$HOME/.config/naldo/sync/repositories.conf"
grep -Fx 'wallpapers_enabled=true' "$HOME/.config/naldo/sync/repositories.conf"
grep -Fx 'wallpapers_path=~/Wallpapers' "$HOME/.config/naldo/sync/repositories.conf"
grep -Fx 'WALLPAPERS_REQUIRED_MOUNT=' "$HOME/.config/naldo/sync/repositories.conf"
```

Never restore the removed Notes credential file or copy Git/LFS runtime state
from the desktop.

## 9. Test and deploy the laptop configuration

Run the complete repository suite before deployment:

```bash
cd "$HOME/dotfiles"
./tests/run-tests.sh
```

Deploy only the laptop profile and confirm that synchronization remains
disabled:

```bash
./install.sh --profile laptop
sync-control status
test "$(systemctl --user is-active sync-all.timer 2>/dev/null || true)" = inactive
test ! -e "$HOME/.config/systemd/user/timers.target.wants/sync-all.timer"
```

Configure machine-local Git author identity without adding it to the repository:

```bash
read -r -p 'Git author name: ' git_author_name
read -r -p 'Git author email: ' git_author_email
test -n "$git_author_name"
test -n "$git_author_email"
git config --global user.name "$git_author_name"
git config --global user.email "$git_author_email"
unset git_author_name git_author_email
git config --global --includes --get core.editor
git config --global --get user.name
git config --global --get user.email
```

Make Fish the login shell, then verify the selected shell path:

```bash
fish_path="$(command -v fish)"
grep -Fx "$fish_path" /etc/shells
chsh -s "$fish_path"
getent passwd "$USER" | cut -d: -f7
```

## 10. Install and activate the reviewed keyd integration

Read the complete recovery guide and memorize keyd's physical
`Backspace+Escape+Enter` panic sequence before activation:

```bash
hx system/keyd/README.md
./install-system.sh --dry-run
sudo ./install-system.sh
sudo udevadm control --reload-rules
sudo systemctl enable keyd.service
sudo systemctl restart keyd.service
```

Verify the stable virtual device and the active user's ACL. Do not use an
`eventN` path in Noctalia and do not add the user to the broad `input` group:

```bash
test -L /dev/input/by-id/keyd-virtual-kbd
udevadm info /dev/input/by-id/keyd-virtual-kbd
readlink -f /dev/input/by-id/keyd-virtual-kbd
getfacl "$(readlink -f /dev/input/by-id/keyd-virtual-kbd)"
systemctl is-enabled keyd.service
systemctl is-active keyd.service
```

## 11. Enter and validate the Niri session

Log out of GNOME. In GDM, choose the package-provided **Niri** session and log
in. Do not replace GDM or create a custom Niri session file.

Open Noctalia Settings → Plugins → Browse Plugins. Materialize the official
**Screen Recorder** and **Bongo Cat** plugins if needed. Keep Screen Recorder in
portal mode and Bongo Cat on:

```text
/dev/input/by-id/keyd-virtual-kbd
```

Plugin payloads, credentials, and generated themes remain machine-local.
World Clock remains uninstalled because the current catalog entry is
incompatible.

Run the desktop/session checks:

```bash
niri validate
noctalia config validate "$HOME/.config/noctalia/config.toml"
ghostty +validate-config --config-file="$HOME/.config/ghostty/config.ghostty"
yazi --debug
systemctl --user status \
  xdg-desktop-portal.service pipewire.service wireplumber.service \
  gcr-ssh-agent.socket
pixi --version
flatpak info com.github.ahrm.sioyek
test "$(xdg-mime query default application/pdf)" = org.pwmt.zathura.desktop
noctalia msg plugins list | grep -F 'noctalia/bongocat '
test ! -d "$HOME/.local/state/noctalia/plugins/materialized/official/world_clock"
```

Check every configured Helix language family:

```bash
for language in bash json yaml toml python typst markdown html css; do
  hx --health "$language"
done
```

Confirm manually:

1. Bongo Cat reacts to typing.
2. Text and image clipboard history survives closing the source application.
3. Zathura is the PDF default; Okular and Sioyek are alternatives.
4. GPU Screen Recorder works through Noctalia in portal mode; do not enable its
   own autostart or global hotkeys.
5. An ordinary desktop/MIME Zen launch follows Niri's normal layout with no
   Zen-specific rule.
6. `Mod+Z` → **Zen Browser** creates only one `1080×920` floating, centered Zen
   window, matching launcher Ghostty's geometry.
7. Zen Picture-in-Picture remains floating.

## 12. Enroll ordinary Tailscale connectivity

Set a distinct hostname and enroll interactively without Tailscale SSH:

```bash
sudo hostnamectl set-hostname naldo-laptop
sudo systemctl enable --now tailscaled.service
sudo tailscale up --hostname=naldo-laptop --ssh=false
tailscale version
tailscale status
systemctl is-enabled tailscaled.service
systemctl is-active tailscaled.service
test "$(tailscale debug prefs | jq -r '.RunSSH')" = false
```

Keep inbound OpenSSH disabled in this setup:

```bash
test "$(systemctl is-active sshd.service 2>/dev/null || true)" = inactive
case "$(systemctl is-enabled sshd.service 2>/dev/null || true)" in
  disabled|not-found) ;;
  *) false ;;
esac
```

Do not enable `sshd`, agent forwarding, or Tailscale SSH.

## 13. Reboot and prove persistence before synchronization

Keep the synchronization timer disabled, then reboot:

```bash
sync-control status
test "$(systemctl --user is-active sync-all.timer 2>/dev/null || true)" = inactive
sudo systemctl reboot
```

Log into Niri again and run all post-reboot checks:

```bash
niri validate
noctalia config validate "$HOME/.config/noctalia/config.toml"
systemctl is-active keyd.service
systemctl --user is-active niri.service
systemctl --user is-active gcr-ssh-agent.socket
systemctl is-active tailscaled.service
test -L /dev/input/by-id/keyd-virtual-kbd
getfacl "$(readlink -f /dev/input/by-id/keyd-virtual-kbd)"
test "$(tailscale debug prefs | jq -r '.RunSSH')" = false

test "$(fish -lc 'printf %s "$SSH_AUTH_SOCK"')" = "$XDG_RUNTIME_DIR/gcr/ssh"
test "$(systemctl --user show-environment | awk -F= '
  $1 == "SSH_AUTH_SOCK" { print substr($0, index($0, "=") + 1) }
')" = "$XDG_RUNTIME_DIR/gcr/ssh"
fish -lc 'ssh-add -l'
```

Verify all repositories and LFS state:

```bash
test "$(git -C "$HOME/dotfiles" remote get-url origin)" = \
  git@github.com:snaldos/naldo-dots.git
test "$(git -C "$HOME/Vaults/second-brain" remote get-url origin)" = \
  git@github.com:snaldos/second-brain.git
test "$(git -C "$HOME/Wallpapers" remote get-url origin)" = \
  git@github.com:snaldos/Wallpapers.git

git -C "$HOME/Vaults/second-brain" lfs fsck
git -C "$HOME/Wallpapers" lfs fsck
git -C "$HOME/dotfiles" status --short
git -C "$HOME/Vaults/second-brain" status --short
git -C "$HOME/Wallpapers" status --short
```

Prove that a systemd user process inherits the same agent and can reach every
repository:

```bash
systemd-run --user --wait --collect \
  --unit=naldo-post-reboot-integration-check.service \
  /usr/bin/bash -lc '
    set -e
    test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/gcr/ssh"
    git -C "$HOME/dotfiles" ls-remote origin refs/heads/main >/dev/null
    git -C "$HOME/Vaults/second-brain" ls-remote origin refs/heads/main >/dev/null
    git -C "$HOME/Wallpapers" ls-remote origin refs/heads/main >/dev/null
    git -C "$HOME/Vaults/second-brain" lfs fsck >/dev/null
    git -C "$HOME/Wallpapers" lfs fsck >/dev/null
  '
```

Run the read-only laptop verifier one final time:

```bash
cd "$HOME/dotfiles"
./bootstrap/fedora/verify.sh --profile laptop
```

Stop here if any required check fails.

## 14. Synchronize each repository, then enable the timer

Confirm the timer is still disabled:

```bash
sync-control status
test "$(systemctl --user is-active sync-all.timer 2>/dev/null || true)" = inactive
test ! -e "$HOME/.config/systemd/user/timers.target.wants/sync-all.timer"
```

Run the three mutating synchronization tasks sequentially. Do not run them in
parallel:

```bash
sync-all dotfiles
sync-all notes
sync-all wallpapers
```

Require clean repositories synchronized with `origin/main`:

```bash
for repo in \
  "$HOME/dotfiles" \
  "$HOME/Vaults/second-brain" \
  "$HOME/Wallpapers"; do
  test -z "$(git -C "$repo" status --porcelain)"
  test "$(git -C "$repo" rev-parse HEAD)" = \
    "$(git -C "$repo" rev-parse origin/main)"
done
```

Only now enable the timer and exercise the real oneshot service under the user
manager:

```bash
sync-control enable
sync-control status
systemctl --user start sync-all.service
systemctl --user show sync-all.service -p Result -p ExecMainStatus
sync-control logs

test "$(systemctl --user is-enabled sync-all.timer)" = enabled
test "$(systemctl --user is-active sync-all.timer)" = active
test "$(systemctl --user show sync-all.service -p Result --value)" = success
test "$(systemctl --user show sync-all.service -p ExecMainStatus --value)" = 0
```

If the managed run fails, immediately disable the timer, fix only the concrete
cause, repeat all three manual synchronization tasks, and re-enable it only
after they pass:

```bash
sync-control disable
```

## 15. Completion boundary

The laptop is complete only when:

- Fedora's laptop verifier has no missing required dependency;
- Niri, Noctalia, keyd, Bongo Cat, GCR, and Tailscale survive reboot;
- Tailscale is online with `RunSSH=false`, while `sshd` remains disabled;
- ordinary Zen follows default layout and only Mod+Z Zen floats centered;
- Notes and Wallpapers pass Git LFS checks;
- all three repositories are clean and equal to `origin/main`;
- the manual synchronization tasks pass sequentially;
- `sync-all.service` succeeds under systemd; and
- `sync-all.timer` is enabled and active only after those checks.

Keep [`CLEAN-INSTALL.md`](CLEAN-INSTALL.md),
[`EDITOR-TOOLS.md`](EDITOR-TOOLS.md), [`REMOTE-ACCESS.md`](REMOTE-ACCESS.md),
[`WALLPAPERS.md`](WALLPAPERS.md), and `system/keyd/README.md` as deeper policy
and recovery references. This file is the laptop's ordered execution path.
