# Fedora Workstation clean installation

This is the single ordered setup path for both machines. Run it from top to
bottom, one code block at a time. Choose `profile=desktop` or `profile=laptop`
once in step 2, then execute shared steps plus only the matching profile blocks.
Stop on any unexpected package, repository, signature, device, mount, service,
or validation result.

This is a human-run checklist, not an unattended installer. The six TSV
manifests are the software/provider source of truth; this document derives
package commands from them instead of duplicating inventories.

| Difference | Desktop | Laptop |
|---|---|---|
| graphics | Fedora Intel stack plus reviewed RPM Fusion NVIDIA packages | Fedora Intel stack only |
| wallpapers | UUID-mounted HDD at `/mnt/data`, exposed as `~/Wallpapers` | direct `~/Wallpapers` SSD worktree |
| wallpaper sync guard | `/mnt/data` | empty |
| SSH key comment | `naldo-fedora-desktop` | `naldo-fedora-laptop` |
| Tailscale hostname | `naldo-desktop` | `naldo-laptop` |

Both profiles target:

```text
Fedora Workstation → GDM → package-provided Niri → Noctalia
```

Machine-local keys, credentials, Git identity, GCR state, Tailscale enrollment,
Noctalia runtime, mount state, and synchronization state are never copied
between machines or committed.

## 1. Install Fedora Workstation

Install the current stable Fedora Workstation through the normal Fedora boot and
Anaconda path. Keep GNOME and GDM as delivered. Before erasing another system,
confirm browser access to GitHub, working 2FA, and offline recovery methods.
Do not assume a private SSH key can be recovered afterward.

Hardware boundaries:

- **Desktop only:** retain the existing secondary HDD filesystem and data. Do not
  format it during the Fedora installation. NVIDIA is configured later.
- **Laptop only:** use the internal SSD and Intel graphics. Do not create
  `/mnt/data` or import desktop NVIDIA configuration.

## 2. Update Fedora and choose one profile

Open a Bash terminal, update Fedora, and reboot:

```bash
sudo dnf upgrade --refresh
sudo systemctl reboot
```

After logging back into GNOME, reopen Bash and verify the audited release. If
this is no longer Fedora 44, stop and review current providers/package names
before continuing.

```bash
cat /etc/fedora-release
test "$(rpm -E %fedora)" = 44
```

Choose exactly one profile for this provisioning shell:

```bash
profile=desktop  # change to profile=laptop on the laptop
case "$profile" in
  desktop|laptop) ;;
  *) printf 'invalid profile: %s\n' "$profile" >&2; exit 2 ;;
esac
printf 'selected profile: %s\n' "$profile"
```

Set and validate `profile` again if a new shell is opened before step 17.

## 3. Create the device identity and clone dotfiles

### Common

Install only the bootstrap tools needed before the manifest checkout exists:

```bash
sudo dnf install git-core openssh-clients gcr fish
systemctl --user enable --now gcr-ssh-agent.socket
```

Generate a new passphrase-protected key with the selected device label. Never
copy another machine's private key:

```bash
install -d -m 0700 "$HOME/.ssh"
ssh-keygen -t ed25519 -a 100 -C "naldo-fedora-$profile"
stat -c '%a %n' "$HOME/.ssh" "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"
```

Expected modes are `700`, `600`, and `644`. Display and upload **only** the
public key to GitHub under a distinct device name:

```bash
cat "$HOME/.ssh/id_ed25519.pub"
```

After adding it to GitHub, configure the one Fedora GCR agent shared by Bash,
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

Clone the portable configuration and return to it for all manifest commands:

```bash
git clone git@github.com:snaldos/naldo-dots.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
```

Do not configure agent forwarding, another SSH agent, `sshd`, or Tailscale SSH.

## 4. Install official Fedora packages

### Common

Read the provider overview and manifest, confirm expected enabled Fedora
repositories, derive all non-optional rows applicable to the selected profile,
and review the printed list before installation:

```bash
hx bootstrap/fedora/README.md
hx bootstrap/fedora/dnf-packages.tsv
dnf repolist --enabled
mapfile -t fedora_packages < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $2 != "optional" && ($NF == "all" || $NF == profile) {
    print $1
  }
' bootstrap/fedora/dnf-packages.tsv)
printf '  %s\n' "${fedora_packages[@]}"
sudo dnf install "${fedora_packages[@]}"
```

Fedora supplies Niri, Noctalia, Helix (`hx`), GCR, Git LFS, Flatpak,
PipeWire/WirePlumber, portals, the scientific build toolchain, and selected
applications. Optional rows such as Neovim, Orca, and eza remain absent unless
chosen deliberately later. OpenSSH client tools are selected; an inbound SSH
server is not.

## 5. Install reviewed external providers

### Common provider review

Read the source manifest and print only applicable rows:

```bash
hx bootstrap/fedora/external-tools.tsv
awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) {
    print $1 "\t" $3 "\t" $4
  }
' bootstrap/fedora/external-tools.tsv
```

### Common COPRs

Review each COPR page, spec/source, build history, and signing boundary before
accepting its prompt:

```bash
sudo dnf copr enable scottames/ghostty
sudo dnf copr enable lihaohong/yazi
sudo dnf copr enable alternateved/keyd
sudo dnf install ghostty yazi keyd

sudo dnf copr enable dejan/lazygit
sudo dnf copr enable atim/starship
sudo dnf install lazygit starship
```

LazyGit and Starship use upstream-documented third-party COPRs.
COPR is not an official Fedora package source. DNF owns installation, updates,
and removal for all five selected COPR packages.

### Common Google Chrome RPM

Chrome is a selected secondary browser. Download the official RPM, inspect its
signature against Google's published signing-key boundary, and install only the
reviewed local file:

```bash
curl --proto '=https' --tlsv1.2 --fail --location \
  --output /tmp/google-chrome-stable_current_x86_64.rpm \
  https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
rpm --verbose --checksig -v /tmp/google-chrome-stable_current_x86_64.rpm
sudo dnf install /tmp/google-chrome-stable_current_x86_64.rpm
rm /tmp/google-chrome-stable_current_x86_64.rpm
```

### Common Tailscale repository

Add Tailscale's official stable Fedora repository and constrain installation to
it because Fedora publishes a package with the same name. Enrollment waits until
step 16:

```bash
sudo dnf config-manager addrepo \
  --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install --from-repo=tailscale-stable tailscale
```

### Common Herdr installer

Never pipe downloaded code directly into a shell. Download and inspect the
complete official installer locally, select its stable channel, and create the
machine-local ownership receipt required by `naldo-update`:

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

### Common Pixi installer

Download and inspect Pixi's official installer locally. Fish configuration owns
PATH, so suppress installer shell edits:

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

Only this installer-owned Pixi uses `pixi self-update`.
Do not introduce mise or a generic GitHub binary updater.

### Common JetBrainsMono Nerd Font

Install only the checksum-verified Nerd Fonts `v3.5.0` base-family TTFs:

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

## 6. Install selected Flatpaks

### Common

Add Flathub for the user, derive required IDs, review them, and install them:

```bash
hx bootstrap/fedora/flatpaks.tsv
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

Zen remains the default browser. Zathura remains the default PDF handler, with
Okular and the community-maintained Sioyek Flatpak as alternatives. Vesktop is
optional. `com.dec05eba.gpu_screen_recorder` is the sole recorder provider; do
not install a native duplicate.

## 7. Install npm, uv, and locked Cargo tools

### Common npm tools

Use `~/.npm-global`, never root npm:

```bash
hx bootstrap/fedora/npm-packages.tsv
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

### Common uv tools

Install only active, non-optional tools:

```bash
hx bootstrap/fedora/uv-tools.tsv
mapfile -t uv_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && $4 == "active" &&
    ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/uv-tools.tsv)
printf '  %s\n' "${uv_tools[@]}"
for tool in "${uv_tools[@]}"; do
  uv tool install "$tool"
done
```

### Common Cargo tools

Review each locked command and source before executing it one at a time:

```bash
hx bootstrap/fedora/cargo-tools.tsv
mapfile -t cargo_commands < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) { print $5 }
' bootstrap/fedora/cargo-tools.tsv)
printf '%s\n' "${cargo_commands[@]}" | nl -ba

for cargo_command in "${cargo_commands[@]}"; do
  printf '\nNext command:\n  %s\n' "$cargo_command"
  read -r -p 'Press Enter to run it, or Ctrl-C to stop: '
  bash -lc "$cargo_command"
done
```

Expose user binary locations for this provisioning shell and verify Taplo uses
the LSP-capable Cargo provider rather than the npm build:

```bash
export PATH="$HOME/.npm-global/bin:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.pixi/bin:$PATH"
test "$(readlink -f -- "$(command -v taplo)")" = "$HOME/.cargo/bin/taplo"
taplo --version
```

## 8. Configure graphics for the selected profile

### Desktop only

Review current RPM Fusion NVIDIA and Secure Boot documentation. Enable RPM
Fusion and install the selected driver packages:

```bash
test "$profile" = desktop
sudo dnf install \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
```

Wait for the akmod build to finish before the final reboot. Do not copy old
kernel modules or NVIDIA runtime state.

### Laptop only

Run no command in this subsection. The laptop uses Fedora's Intel graphics stack
and skips RPM Fusion and every NVIDIA package.

## 9. Clone Notes and initialize Git LFS

### Common

```bash
install -d "$HOME/Vaults"
git clone git@github.com:snaldos/second-brain.git \
  "$HOME/Vaults/second-brain"
git -C "$HOME/Vaults/second-brain" lfs install --local
git -C "$HOME/Vaults/second-brain" lfs pull
git -C "$HOME/Vaults/second-brain" lfs fsck
```

Notes may currently contain zero LFS objects but retains narrow future
attachment rules. Never restore the removed credential file or copy another
machine's Git/LFS runtime state.

## 10. Configure profile-specific wallpaper storage

Execute exactly one subsection.

### Desktop only: existing HDD

First inspect physical identity without changing anything:

```bash
test "$profile" = desktop
lsblk -o NAME,MODEL,SERIAL,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
```

Match the intended partition using model, serial, size, filesystem, and existing
data—not a transient `/dev/sdX` letter. Set the verified stable partition path
manually, then test-mount it without formatting:

```bash
hdd_partition=/dev/disk/by-id/REPLACE-WITH-VERIFIED-PARTITION
readlink -f "$hdd_partition"
sudo install -d -m 0755 /mnt/data
sudo mount "$hdd_partition" /mnt/data
findmnt --mountpoint /mnt/data -o TARGET,SOURCE,FSTYPE,UUID,OPTIONS
```

Inspect the data and require the expected filesystem. Record the UUID from this
verified mount:

```bash
test "$(findmnt --mountpoint /mnt/data -no FSTYPE)" = ext4
wallpaper_uuid="$(findmnt --mountpoint /mnt/data -no UUID)"
test -n "$wallpaper_uuid"
printf 'verified UUID: %s\n' "$wallpaper_uuid"
```

Back up `/etc/fstab` and edit it manually:

```bash
backup="/etc/fstab.backup-before-mnt-data-$(date -u +%Y%m%dT%H%M%SZ)"
sudo install -o root -g root -m 0644 /etc/fstab "$backup"
sudoedit /etc/fstab
```

Add exactly one line using the verified UUID value—not the placeholder:

```text
UUID=VERIFIED-HDD-UUID /mnt/data ext4 defaults,nofail,x-systemd.device-timeout=10s,x-systemd.mount-timeout=30s 0 2
```

Validate and prove a real fstab-based remount before cloning:

```bash
sudo findmnt --verify --verbose --tab-file /etc/fstab
sudo systemctl daemon-reload
sync
sudo umount /mnt/data
sudo mount /mnt/data
findmnt --mountpoint /mnt/data -o TARGET,SOURCE,FSTYPE,UUID,OPTIONS
test "$(findmnt --mountpoint /mnt/data -no UUID)" = "$wallpaper_uuid"
systemctl status mnt-data.mount
```

Create only the repository parent with deliberate ownership, clone Wallpapers,
and expose the stable logical path:

```bash
sudo install -d -o "$USER" -g "$(id -gn)" -m 0755 /mnt/data/repos
git clone git@github.com:snaldos/Wallpapers.git /mnt/data/repos/Wallpapers
git -C /mnt/data/repos/Wallpapers lfs install --local
git -C /mnt/data/repos/Wallpapers lfs pull
git -C /mnt/data/repos/Wallpapers lfs fsck
test ! -e "$HOME/Wallpapers"
ln -s /mnt/data/repos/Wallpapers "$HOME/Wallpapers"
test "$(readlink -f "$HOME/Wallpapers")" = /mnt/data/repos/Wallpapers
```

### Laptop only: direct SSD worktree

```bash
test "$profile" = laptop
git clone git@github.com:snaldos/Wallpapers.git "$HOME/Wallpapers"
git -C "$HOME/Wallpapers" lfs install --local
git -C "$HOME/Wallpapers" lfs pull
git -C "$HOME/Wallpapers" lfs fsck
test ! -L "$HOME/Wallpapers"
```

### Common synchronization configuration

Initialize the private configuration once and edit it:

```bash
"$HOME/dotfiles/automation/.local/libexec/naldo/init-sync-config" \
  --config "$HOME/.config/naldo/sync/repositories.conf" \
  --template "$HOME/dotfiles/automation/.config/naldo/sync/repositories.conf.example"
hx "$HOME/.config/naldo/sync/repositories.conf"
chmod 0600 "$HOME/.config/naldo/sync/repositories.conf"
```

Both profiles require:

```text
dotfiles_enabled=true
dotfiles_path=~/dotfiles
notes_enabled=true
notes_path=~/Vaults/second-brain
wallpapers_enabled=true
wallpapers_path=~/Wallpapers
```

Set exactly one machine-local guard:

```text
# Desktop
WALLPAPERS_REQUIRED_MOUNT=/mnt/data

# Laptop
WALLPAPERS_REQUIRED_MOUNT=
```

Verify the selected value:

```bash
case "$profile" in
  desktop)
    grep -Fx 'WALLPAPERS_REQUIRED_MOUNT=/mnt/data' \
      "$HOME/.config/naldo/sync/repositories.conf"
    ;;
  laptop)
    grep -Fx 'WALLPAPERS_REQUIRED_MOUNT=' \
      "$HOME/.config/naldo/sync/repositories.conf"
    ;;
esac
```

## 11. Test, deploy, and verify user configuration

### Common

Run the full repository suite before deployment:

```bash
cd "$HOME/dotfiles"
./tests/run-tests.sh
```

Deploy exactly the selected profile:

```bash
./install.sh --profile "$profile"
```

Run the matching read-only dependency verifier:

```bash
case "$profile" in
  desktop) ./bootstrap/fedora/verify.sh --profile desktop ;;
  laptop) ./bootstrap/fedora/verify.sh --profile laptop ;;
esac
```

Resolve every missing `session` or `feature` dependency. Optional/development
misses may remain. Confirm installation did not enable synchronization:

```bash
sync-control status
test "$(systemctl --user is-active sync-all.timer 2>/dev/null || true)" = inactive
test ! -e "$HOME/.config/systemd/user/timers.target.wants/sync-all.timer"
```

## 12. Configure machine-local Git identity and Fish

### Common

The tracked Git include contains portable behavior only. Set author identity
locally without adding it to the repository:

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

Make Fish the login shell and verify the selected path:

```bash
fish_path="$(command -v fish)"
grep -Fx "$fish_path" /etc/shells
chsh -s "$fish_path"
getent passwd "$USER" | cut -d: -f7
```

## 13. Install and activate the reviewed keyd integration

### Common

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

Verify the stable virtual keyboard and active-user ACL. Do not use an `eventN`
path in Noctalia or add the account to the broad `input` group:

```bash
test -L /dev/input/by-id/keyd-virtual-kbd
udevadm info /dev/input/by-id/keyd-virtual-kbd
readlink -f /dev/input/by-id/keyd-virtual-kbd
getfacl "$(readlink -f /dev/input/by-id/keyd-virtual-kbd)"
systemctl is-enabled keyd.service
systemctl is-active keyd.service
```

## 14. Enter Niri through GDM and materialize Noctalia plugins

### Common

Log out of GNOME. In GDM, choose the package-provided **Niri** session and log
in. Do not replace GDM or create a custom session entry. Open Ghostty, enter a
Bash provisioning shell, restore the selected profile, and return to the repo:

```bash
bash
profile=desktop  # change to profile=laptop on the laptop
case "$profile" in desktop|laptop) ;; *) exit 2 ;; esac
cd "$HOME/dotfiles"
```

Niri starts Noctalia, which renders machine-local themes. Open Noctalia Settings
→ Plugins → Browse Plugins and materialize the official **Screen Recorder** and
**Bongo Cat** plugins if needed. Keep:

```text
Screen Recorder video source: portal
Bongo Cat input device: /dev/input/by-id/keyd-virtual-kbd
```

World Clock remains uninstalled because the current catalog entry is
incompatible. Plugin payloads, credentials, generated themes, and settings stay
machine-local.

## 15. Validate the session, applications, and Zen behavior

### Common automated checks

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

Check each configured Helix language family:

```bash
for language in bash json yaml toml python typst markdown html css; do
  hx --health "$language"
done
```

### Common manual checks

1. copy and paste text between applications;
2. copy and paste an image;
3. copy content, close it, then paste again;
4. open Noctalia's clipboard history and select an older item;
5. confirm Bongo Cat reacts to typing;
6. confirm Zathura is the PDF default and Okular/Sioyek are alternatives;
7. test GPU Screen Recorder through Noctalia in portal mode, without enabling
   the recorder's own autostart or global hotkeys;
8. launch ordinary Zen from its desktop/MIME path and confirm it follows Niri's
   normal layout with no Zen-specific rule;
9. use `Mod+Z` → **Zen Browser** and confirm only that new Zen window is floating,
   centered, and `1080×920`, matching launcher Ghostty; and
10. confirm Zen Picture-in-Picture remains floating.

## 16. Enroll Tailscale and keep inbound SSH disabled

### Common

Select the machine hostname from the profile and enroll interactively without a
reusable auth key or Tailscale SSH:

```bash
case "$profile" in
  desktop) machine_hostname=naldo-desktop ;;
  laptop) machine_hostname=naldo-laptop ;;
esac
sudo hostnamectl set-hostname "$machine_hostname"
sudo systemctl enable --now tailscaled.service
sudo tailscale up --hostname="$machine_hostname" --ssh=false
tailscale version
tailscale status
systemctl is-enabled tailscaled.service
systemctl is-active tailscaled.service
test "$(tailscale debug prefs | jq -r '.RunSSH')" = false
```

This setup selects OpenSSH clients only. It does not select or activate an
inbound SSH server, create `authorized_keys`, enable agent forwarding, or enable
Tailscale SSH:

```bash
test "$(systemctl is-active sshd.service 2>/dev/null || true)" = inactive
case "$(systemctl is-enabled sshd.service 2>/dev/null || true)" in
  disabled|not-found) ;;
  *) false ;;
esac
```

## 17. Reboot and prove persistent integration

### Common pre-reboot boundary

Keep synchronization disabled and reboot only after all earlier checks pass:

```bash
sync-control status
test "$(systemctl --user is-active sync-all.timer 2>/dev/null || true)" = inactive
sudo systemctl reboot
```

Log into Niri again. Open Ghostty, enter Bash, restore the profile, and return
to the repository for profile-specific checks:

```bash
bash
profile=desktop  # change to profile=laptop on the laptop
case "$profile" in desktop|laptop) ;; *) exit 2 ;; esac
cd "$HOME/dotfiles"
```

Validate the session, keyd, Tailscale, and GCR inheritance:

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

### Desktop-only persistence checks

```bash
if [[ "$profile" == desktop ]]; then
  findmnt --mountpoint /mnt/data -o TARGET,SOURCE,FSTYPE,UUID,OPTIONS
  test "$(readlink -f "$HOME/Wallpapers")" = /mnt/data/repos/Wallpapers
  systemctl is-active mnt-data.mount
  nvidia-smi
fi
```

### Laptop-only persistence checks

```bash
if [[ "$profile" == laptop ]]; then
  test ! -L "$HOME/Wallpapers"
  test -d "$HOME/Wallpapers/.git"
fi
```

### Common repository and systemd integration checks

```bash
test "$(git -C "$HOME/dotfiles" remote get-url origin)" = \
  git@github.com:snaldos/naldo-dots.git
test "$(git -C "$HOME/Vaults/second-brain" remote get-url origin)" = \
  git@github.com:snaldos/second-brain.git
test "$(git -C "$HOME/Wallpapers" remote get-url origin)" = \
  git@github.com:snaldos/Wallpapers.git
git -C "$HOME/Vaults/second-brain" lfs fsck
git -C "$HOME/Wallpapers" lfs fsck

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

Run the matching verifier again:

```bash
case "$profile" in
  desktop) ./bootstrap/fedora/verify.sh --profile desktop ;;
  laptop) ./bootstrap/fedora/verify.sh --profile laptop ;;
esac
```

Stop here if any required check fails.

## 18. Synchronize each repository manually

### Common

Confirm the timer remains disabled and all repositories are ready:

```bash
sync-control status
test "$(systemctl --user is-active sync-all.timer 2>/dev/null || true)" = inactive
test ! -e "$HOME/.config/systemd/user/timers.target.wants/sync-all.timer"
git -C "$HOME/Vaults/second-brain" lfs fsck
git -C "$HOME/Wallpapers" lfs fsck
```

Run the three mutating tasks sequentially—never in parallel:

```bash
sync-all dotfiles
sync-all notes
sync-all wallpapers
```

Require clean repositories equal to `origin/main`:

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

## 19. Enable and exercise synchronization last

### Common

Only after all three manual tasks pass, enable the timer and run the real oneshot
service through the systemd user manager:

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

If the managed run fails, disable the timer immediately, fix only the concrete
cause, repeat all three manual tasks, and re-enable it only after they pass:

```bash
sync-control disable
```

## 20. Completion boundary

The selected profile is complete only when:

- the profile verifier reports no missing required dependency;
- Niri, Noctalia, keyd, Bongo Cat, GCR, and Tailscale survive reboot;
- ordinary Zen follows default layout and only Mod+Z Zen floats centered;
- Tailscale is online with `RunSSH=false` and inbound `sshd` is absent/inactive;
- Notes and Wallpapers pass Git LFS checks;
- all three repositories are clean and equal to `origin/main`;
- the manual synchronization tasks pass sequentially;
- `sync-all.service` succeeds under systemd; and
- `sync-all.timer` is enabled only after those checks.

Additionally:

- **Desktop:** the UUID HDD mount and NVIDIA driver survive reboot, and
  `~/Wallpapers` resolves below `/mnt/data`.
- **Laptop:** `~/Wallpapers` is a direct SSD worktree, with no `/mnt/data`, RPM
  Fusion, NVIDIA, copied private key, or desktop runtime state.

Use [`EDITOR-TOOLS.md`](EDITOR-TOOLS.md),
[`REMOTE-ACCESS.md`](REMOTE-ACCESS.md), [`WALLPAPERS.md`](WALLPAPERS.md), and
`system/keyd/README.md` for deeper provider rationale and recovery procedures;
all required execution order lives in this file.
