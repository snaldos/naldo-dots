# Fedora KDE Plasma Desktop clean installation

This is the only installation sequence for both machines. Run it from top to
bottom in a Bash shell, one code block at a time. Every time you open a new
terminal for this guide—including after logging into Niri—run `bash` before any
other command. A code fence labelled `bash` provides syntax highlighting; it
does not switch your current shell. Choose one profile in step 2,
run every **Common** block, and run only the matching **Desktop only** or
**Laptop only** blocks. Stop on any unexpected provider, signature, device,
mount, service, or validation result.

The TSV manifests are the selected-software source of truth. This guide contains
execution order; the focused runbooks contain rationale and recovery details.
Private keys, tokens, Git identity, mount IDs, GCR/Noctalia/Tailscale state, and
repository paths are machine-local and must never be copied from the desktop to
the laptop or committed.

| Boundary             | Desktop                                                 | Laptop                                |
| -------------------- | ------------------------------------------------------- | ------------------------------------- |
| graphics             | Fedora Intel stack plus RPM Fusion NVIDIA               | Fedora Intel stack only               |
| Wallpapers           | HDD mounted at `/mnt/data`; `~/Wallpapers` is a symlink | direct SSD worktree at `~/Wallpapers` |
| wallpaper sync guard | `/mnt/data`                                             | empty                                 |
| device names         | `naldo-fedora-desktop`, `naldo-desktop`                 | `naldo-fedora-laptop`, `naldo-laptop` |

## 1. Install Fedora KDE Plasma Desktop Edition

Install the current stable Fedora KDE Plasma Desktop Edition directly. This
guide keeps its complete Plasma composition and adds packaged Niri plus every
selected GNOME/GTK integration package that Niri needs; it does not install
GNOME Shell/session or GDM. Before erasing an existing installation, confirm
GitHub browser access, 2FA, and offline recovery methods.

- **Desktop only:** preserve the secondary HDD filesystem; do not format it.
- **Laptop only:** use the internal SSD and do not create `/mnt/data`.

## 2. Update Fedora and select the profile

### Common

Open a terminal, enter Bash, update Fedora, and reboot:

```bash
bash
test -n "$BASH_VERSION"
sudo dnf upgrade --refresh
sudo systemctl reboot
```

After login, open a terminal and enter Bash again. This runbook was audited for
Fedora 44; if the release differs, stop and review package/provider changes
first.

```bash
bash
test -n "$BASH_VERSION"
cat /etc/fedora-release
test "$(rpm -E %fedora)" = 44
test "$(. /etc/os-release; printf %s "$VARIANT_ID")" = kde
rpm -q fedora-release-kde-desktop fedora-release-identity-kde-desktop
```

Select exactly one profile in every new provisioning shell:

```bash
profile=laptop  # use profile=desktop only on the desktop
case "$profile" in
  desktop|laptop) ;;
  *) printf 'invalid profile: %s\n' "$profile" >&2; exit 2 ;;
esac
printf 'selected profile: %s\n' "$profile"
```

## 3. Create the SSH identity and clone dotfiles from Plasma

### Common

Install only the client/bootstrap packages required before the repository is
available. This setup never installs an inbound SSH server.

```bash
sudo dnf install git-core openssh-clients fish helix
```

Create a new passphrase-protected key for this device. Never copy a private key
from the other machine.

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

The initial KDE session uses Fedora's OpenSSH agent. Do not create a global
socket override or ask KWallet to replace this agent:

```bash
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/ssh-agent.socket"
systemctl --user is-active ssh-agent.socket ssh-agent.service
ssh-add "$HOME/.ssh/id_ed25519"
ssh-add -T "$HOME/.ssh/id_ed25519.pub"
git ls-remote git@github.com:snaldos/naldo-dots.git refs/heads/main
git clone git@github.com:snaldos/naldo-dots.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
```

Niri's GNOME Keyring/GCR path is installed from the manifest and enrolled after
the first Niri login. Plasma requires another manual
`ssh-add ~/.ssh/id_ed25519` after each reboot. Do not configure agent
forwarding, `authorized_keys`, `sshd`, or Tailscale SSH.

## 4. Install selected Fedora packages

### Common

Review and reconcile Fedora 44's coherent KDE Plasma desktop group. The KDE
Edition already selects Plasma Login Manager; the group command is idempotent
and ensures the complete release-specific composition:

```bash
dnf group info kde-desktop
sudo dnf group install kde-desktop
sudo systemctl disable plasma-setup.service
test "$(systemctl is-enabled plasma-setup.service 2>/dev/null || true)" = disabled
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
systemctl is-enabled plasmalogin.service
! rpm -q gdm >/dev/null 2>&1
```

Initial account provisioning is complete, so the KDE group's pre-login
out-of-box wizard must not run again. Keep its package as a group member but
keep `plasma-setup.service` disabled.

Then review the manifest, derive non-optional rows for the selected profile,
inspect the printed package list, and install it:

```bash
hx bootstrap/fedora/dnf-packages.tsv
mapfile -t fedora_packages < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $2 != "optional" && ($NF == "all" || $NF == profile) {
    print $1
  }
' bootstrap/fedora/dnf-packages.tsv)
printf '  %s\n' "${fedora_packages[@]}"
sudo dnf install "${fedora_packages[@]}"
```

Make the retained login, keyring, and portal closure explicit in DNF's reason
database. This prevents a future targeted package operation from classifying
GCR or a PAM module as an obsolete GNOME dependency:

```bash
sudo dnf -y mark user \
  plasma-login-manager pam-kwallet \
  gnome-keyring gnome-keyring-pam gcr \
  xdg-desktop-portal xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk xdg-desktop-portal-kde nautilus \
  niri noctalia plasma-desktop plasma-workspace kwin polkit-kde \
  xwayland-satellite
```

The KDE group and manifest provide full Plasma/KWin, Dolphin, Konsole, System
Settings, KDE portals and PolicyKit; plus Niri, Noctalia, GNOME Keyring/PAM,
GCR, GNOME/GTK portals, Nautilus, PipeWire, GitHub CLI, Thunderbird, Helix, Git
LFS, scientific build tools, and selected applications. Those GNOME-named rows
are explicit because the KDE Edition does not guarantee Niri's integration
closure. The selection does not include GNOME Shell/session, GDM,
`openssh-server`, or Conda. Read [`DESKTOPS.md`](DESKTOPS.md) for the boundaries.

## 5. Install reviewed RPM/COPR providers

### Common COPRs

Review each source page before accepting its prompt:

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
COPR is not an official Fedora package source. DNF owns all selected COPR
packages after installation.

### Common Google Chrome

```bash
curl --proto '=https' --tlsv1.2 --fail --location \
  --output /tmp/google-chrome-stable_current_x86_64.rpm \
  https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
rpm --verbose --checksig -v /tmp/google-chrome-stable_current_x86_64.rpm
sudo dnf install /tmp/google-chrome-stable_current_x86_64.rpm
rm /tmp/google-chrome-stable_current_x86_64.rpm
```

### Common Visual Studio Code

Use Microsoft’s official signed RPM repository, not an unofficial Flatpak:

```bash
provider_work="$(mktemp -d "${TMPDIR:-/tmp}/vscode-provider.XXXXXX")"
trap 'rm -rf -- "$provider_work"' EXIT
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$provider_work/microsoft.asc" \
  https://packages.microsoft.com/keys/microsoft.asc
test "$(gpg --show-keys --with-colons "$provider_work/microsoft.asc" 2>/dev/null |
  awk -F: '$1 == "fpr" { print $10; exit }')" = \
  BC528686B50D79E339D3721CEB3E94ADBE1229CF
cat >"$provider_work/vscode.repo" <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo rpm --import "$provider_work/microsoft.asc"
sudo install -o root -g root -m 0644 \
  "$provider_work/vscode.repo" /etc/yum.repos.d/vscode.repo
sudo dnf install code
rm -rf -- "$provider_work"
trap - EXIT
```

### Common Tailscale repository

Verify and import the vendor key before allowing DNF to accept repository
metadata:

```bash
tailscale_key="$(mktemp "${TMPDIR:-/tmp}/tailscale-key.XXXXXX.gpg")"
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$tailscale_key" https://pkgs.tailscale.com/stable/fedora/repo.gpg
test "$(gpg --show-keys --with-colons "$tailscale_key" 2>/dev/null |
  awk -F: '$1 == "fpr" { print $10; exit }')" = \
  2596A99EAAB33821893C0A79458CA832957F5868
sudo rpm --import "$tailscale_key"
rm -f -- "$tailscale_key"
sudo dnf config-manager addrepo \
  --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf makecache --refresh -y --repo=tailscale-stable
sudo dnf install --from-repo=tailscale-stable tailscale
```

Enrollment waits until step 17.

## 6. Install reviewed user-owned tools and font

First inspect the applicable external inventory:

```bash
hx bootstrap/fedora/external-tools.tsv
awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) {
    print $1 "\t" $3 "\t" $4
  }
' bootstrap/fedora/external-tools.tsv
```

### Common Herdr

Download and inspect the complete installer rather than piping it into a shell:

```bash
herdr_installer="$(mktemp "${TMPDIR:-/tmp}/herdr-install.XXXXXX.sh")"
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$herdr_installer" https://herdr.dev/install.sh
sh -n "$herdr_installer"
hx "$herdr_installer"
sh "$herdr_installer"
rm -f -- "$herdr_installer"
herdr channel set stable
test "$(herdr channel show)" = stable

receipt_dir="${XDG_DATA_HOME:-$HOME/.local/share}/naldo/provider-receipts"
install -d -m 0700 "$receipt_dir"
herdr_path="$(readlink -f -- "$(command -v herdr)")"
test "$herdr_path" = "$(readlink -m -- "$HOME/.local/bin/herdr")"
receipt_tmp="$(mktemp --tmpdir="$receipt_dir" '.herdr-receipt.XXXXXX')"
printf 'source=https://herdr.dev/install.sh\nbinary=%s\n' "$herdr_path" >"$receipt_tmp"
chmod 0600 "$receipt_tmp"
mv -f -- "$receipt_tmp" "$receipt_dir/herdr-official-installer"
```

### Common Pixi

```bash
pixi_installer="$(mktemp "${TMPDIR:-/tmp}/pixi-install.XXXXXX.sh")"
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$pixi_installer" https://pixi.sh/install.sh
sh -n "$pixi_installer"
hx "$pixi_installer"
PIXI_NO_PATH_UPDATE=1 sh "$pixi_installer"
rm -f -- "$pixi_installer"
"$HOME/.pixi/bin/pixi" --version
```

Pixi supplies reproducible conda-forge/native/CUDA environments; do not install
Conda alongside it unless an external workflow explicitly requires the `conda`
command. Do not introduce mise or a generic GitHub binary updater.

### Common Marksman

Fedora 44 does not provide Marksman in the enabled DNF repositories. Install the
reviewed upstream x86-64 release as a user-owned binary and verify GitHub's
published SHA-256 digest before placing it on `PATH`:

```bash
test "$(uname -m)" = x86_64
marksman_version=2026-02-08
marksman_asset=marksman-linux-x64
marksman_sha=be5098e8213219269c47fc0d916a66fa31ce0602ec967475c722260aabf26087
marksman_work="$(mktemp -d "${TMPDIR:-/tmp}/marksman-install.XXXXXX")"
trap 'rm -rf -- "$marksman_work"' EXIT
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$marksman_work/$marksman_asset" \
  "https://github.com/artempyanykh/marksman/releases/download/${marksman_version}/${marksman_asset}"
printf '%s  %s\n' "$marksman_sha" "$marksman_work/$marksman_asset" | sha256sum --check -
install -d -m 0755 "$HOME/.local/bin"
install -m 0755 "$marksman_work/$marksman_asset" "$HOME/.local/bin/marksman"
rm -rf -- "$marksman_work"
trap - EXIT
"$HOME/.local/bin/marksman" --version
```

Marksman is the global Helix Markdown server. The State Space repository uses a
project-local `.helix/languages.toml` to select Markdown Oxide instead.

### Common Tuicr

Install the reviewed `v0.20.0` release through the official installer and prove
that its result matches GitHub’s published release digest:

```bash
tuicr_version=0.20.0
tuicr_asset="tuicr-${tuicr_version}-x86_64-unknown-linux-gnu.tar.gz"
tuicr_asset_sha=1835a289ff4ab32269bf466ca03b6a12a61fedf493c4a54302f4cabc65818587
tuicr_work="$(mktemp -d "${TMPDIR:-/tmp}/tuicr-install.XXXXXX")"
trap 'rm -rf -- "$tuicr_work"' EXIT
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$tuicr_work/install.sh" https://tuicr.dev/install.sh
sh -n "$tuicr_work/install.sh"
hx "$tuicr_work/install.sh"
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$tuicr_work/$tuicr_asset" \
  "https://github.com/agavra/tuicr/releases/download/v${tuicr_version}/${tuicr_asset}"
printf '%s  %s\n' "$tuicr_asset_sha" "$tuicr_work/$tuicr_asset" | sha256sum --check -
mkdir "$tuicr_work/verified"
tar -xzf "$tuicr_work/$tuicr_asset" -C "$tuicr_work/verified"
verified_tuicr="$(find "$tuicr_work/verified" -type f -name tuicr -print -quit)"
test -n "$verified_tuicr"
TUICR_VERSION="$tuicr_version" TUICR_INSTALL_YES=1 sh "$tuicr_work/install.sh"
cmp "$verified_tuicr" "$HOME/.local/bin/tuicr"

tuicr_path="$(readlink -f -- "$(command -v tuicr)")"
test "$tuicr_path" = "$(readlink -m -- "$HOME/.local/bin/tuicr")"
receipt_dir="${XDG_DATA_HOME:-$HOME/.local/share}/naldo/provider-receipts"
install -d -m 0700 "$receipt_dir"
receipt_tmp="$(mktemp --tmpdir="$receipt_dir" '.tuicr-receipt.XXXXXX')"
printf 'source=https://tuicr.dev/install.sh\nbinary=%s\n' "$tuicr_path" >"$receipt_tmp"
chmod 0600 "$receipt_tmp"
mv -f -- "$receipt_tmp" "$receipt_dir/tuicr-official-installer"
tuicr --version
rm -rf -- "$tuicr_work"
trap - EXIT
```

### Common JetBrainsMono Nerd Font

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
import re, sys, zipfile
archive, target = Path(sys.argv[1]), Path(sys.argv[2])
pattern = re.compile(r"JetBrainsMonoNerdFont-[A-Za-z]+(?:Italic)?\.ttf")
target.mkdir()
with zipfile.ZipFile(archive) as source:
    selected = [item for item in source.infolist()
                if pattern.fullmatch(PurePosixPath(item.filename).name)]
    if len(selected) != 16:
        raise SystemExit(f"expected 16 base-family TTFs, found {len(selected)}")
    for item in selected:
        (target / PurePosixPath(item.filename).name).write_bytes(source.read(item))
PY
font_target="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
rm -rf -- "$font_target"
install -d -m 0755 "$font_target"
install -m 0644 "$font_stage"/*.ttf "$font_target"/
fc-cache -f "$font_target"
rm -rf -- "$font_work"
fc-match 'JetBrainsMono Nerd Font'
```

## 7. Install selected Flatpaks

### Common

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
```

Zen is the default browser. Zathura is the default PDF viewer; Okular and Sioyek
remain alternatives. GPU Screen Recorder is installed only through Flatpak.

## 8. Install npm, uv, and Cargo tools

### Common npm prefix

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

`typescript@6` is intentional: TypeScript 7 removed `tsserver`, which the
selected language server still requires.

### Common uv tools

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

BasedPyright remains Helix's global Python type checker. `ty` is also installed
and can replace BasedPyright in a project's `.helix/languages.toml`; do not run
both type checkers for the same buffer.

### Common locked Cargo tools

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

Expose all user binaries in this provisioning shell:

```bash
export PATH="$HOME/.npm-global/bin:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.pixi/bin:$PATH"
marksman --version
taplo --version
typescript-language-server --version
tsc --version
command -v tsserver
```

`tsserver` is a long-running editor protocol server, not a version-check
command. Do not run `tsserver` or `tsserver --help` interactively: it can wait
indefinitely for protocol input. If it is started accidentally, press `Ctrl-C`.
`command -v tsserver` verifies that the executable is available without
launching it.

## 9. Configure GitHub CLI, VS Code, and Thunderbird

### Common GitHub CLI

Authenticate through the browser and wait until the command itself exits:

```bash
gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web
gh auth status
gh extension install dlvhdr/gh-dash
gh extension list
gh dash --version
```

The token must be reported as stored in the keyring. Do not paste the one-time
device code or the human-readable login transcript into Bash.

### Common minimal scientific VS Code fallback

Install exactly three selected extensions; their provider-managed dependencies
may appear in `code --list-extensions`:

```bash
for extension in ms-python.python ms-toolsai.jupyter charliermarsh.ruff; do
  code --install-extension "$extension"
done
for extension in ms-python.python ms-toolsai.jupyter charliermarsh.ruff; do
  code --list-extensions | grep -Fxi "$extension"
done
```

Helix remains the primary editor. No VS Code extension pack or copied settings
profile is selected.

### Common Thunderbird check

```bash
rpm -q thunderbird
thunderbird --version
```

Add mail/calendar accounts interactively later; account state is private and is
not synchronized.

## 10. Configure profile-specific graphics

### Desktop only

```bash
test "$profile" = desktop
sudo dnf install \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
```

Review RPM Fusion Secure Boot guidance and allow the akmod build to finish before
rebooting.

### Laptop only

Run no command here. The laptop uses Fedora’s Intel graphics stack and does not
add RPM Fusion or NVIDIA packages.

## 11. Clone State Space and configure wallpaper storage

### Common State Space setup

```bash
install -d "$HOME/Vaults"
git clone git@github.com:snaldos/state-space.git "$HOME/Vaults/state-space"
git -C "$HOME/Vaults/state-space" lfs install --local
git -C "$HOME/Vaults/state-space" lfs pull
git -C "$HOME/Vaults/state-space" lfs fsck
```

Never restore the removed credential file.

### Laptop only: direct SSD Wallpapers

```bash
test "$profile" = laptop
git clone git@github.com:snaldos/Wallpapers.git "$HOME/Wallpapers"
git -C "$HOME/Wallpapers" lfs install --local
git -C "$HOME/Wallpapers" lfs pull
git -C "$HOME/Wallpapers" lfs fsck
test ! -L "$HOME/Wallpapers"
```

### Desktop only: existing HDD Wallpapers

Read [`WALLPAPERS.md`](WALLPAPERS.md) before selecting a partition. Identify it
from model, serial, size, filesystem, UUID, and existing data—not `/dev/sdX`:

```bash
test "$profile" = desktop
lsblk -o NAME,MODEL,SERIAL,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
hdd_partition=/dev/disk/by-id/REPLACE-WITH-VERIFIED-PARTITION
readlink -f "$hdd_partition"
sudo install -d -m 0755 /mnt/data
sudo mount "$hdd_partition" /mnt/data
findmnt --mountpoint /mnt/data -o TARGET,SOURCE,FSTYPE,UUID,OPTIONS
test "$(findmnt --mountpoint /mnt/data -no FSTYPE)" = ext4
wallpaper_uuid="$(findmnt --mountpoint /mnt/data -no UUID)"
```

Back up and edit `/etc/fstab`:

```bash
backup="/etc/fstab.backup-before-mnt-data-$(date -u +%Y%m%dT%H%M%SZ)"
sudo install -o root -g root -m 0644 /etc/fstab "$backup"
sudoedit /etc/fstab
```

Add exactly one line with the observed UUID:

```text
UUID=VERIFIED-HDD-UUID /mnt/data ext4 defaults,nofail,x-systemd.device-timeout=10s,x-systemd.mount-timeout=30s 0 2
```

Validate before cloning:

```bash
sudo findmnt --verify --verbose --tab-file /etc/fstab
sudo systemctl daemon-reload
sync
sudo umount /mnt/data
sudo mount /mnt/data
test "$(findmnt --mountpoint /mnt/data -no UUID)" = "$wallpaper_uuid"
sudo install -d -o "$USER" -g "$(id -gn)" -m 0755 /mnt/data/repos
git clone git@github.com:snaldos/Wallpapers.git /mnt/data/repos/Wallpapers
git -C /mnt/data/repos/Wallpapers lfs install --local
git -C /mnt/data/repos/Wallpapers lfs pull
git -C /mnt/data/repos/Wallpapers lfs fsck
test ! -e "$HOME/Wallpapers"
ln -s /mnt/data/repos/Wallpapers "$HOME/Wallpapers"
```

## 12. Configure machine-local synchronization

### Common

```bash
"$HOME/dotfiles/automation/.local/libexec/naldo/init-sync-config" \
  --config "$HOME/.config/naldo/sync/repositories.conf" \
  --template "$HOME/dotfiles/automation/.config/naldo/sync/repositories.conf.example"
hx "$HOME/.config/naldo/sync/repositories.conf"
chmod 0600 "$HOME/.config/naldo/sync/repositories.conf"
```

Set:

```text
dotfiles_enabled=true
dotfiles_path=~/dotfiles
notes_enabled=true
notes_path=~/Vaults/state-space
wallpapers_enabled=true
wallpapers_path=~/Wallpapers
```

Set the matching mount guard:

```text
# Desktop only
WALLPAPERS_REQUIRED_MOUNT=/mnt/data

# Laptop only
WALLPAPERS_REQUIRED_MOUNT=
```

Verify it:

```bash
case "$profile" in
  desktop) grep -Fx 'WALLPAPERS_REQUIRED_MOUNT=/mnt/data' "$HOME/.config/naldo/sync/repositories.conf" ;;
  laptop) grep -Fx 'WALLPAPERS_REQUIRED_MOUNT=' "$HOME/.config/naldo/sync/repositories.conf" ;;
esac
```

## 13. Test and deploy user configuration

### Common

Existing real parent directories such as `~/.config`, `~/.local`, and `~/.pi`
are normal and must not be deleted. Deployment intentionally stops if a regular
file already occupies a path that Stow needs to manage. Do not recursively
remove `~/.config`, glob away its contents, or use `stow --adopt`: it contains
machine-local and private state created in earlier steps.

Run the tests and the non-mutating deployment preflight first:

```bash
cd "$HOME/dotfiles"
./tests/run-tests.sh
./deploy-links.sh --dry-run
```

If the dry run succeeds, continue below. If it reports a conflict such as
`existing target .config/helix/config.toml`, inspect and move only that exact
reported target into a private backup. Replace the example value below, repeat
for each reported conflict, and rerun the dry run until it succeeds:

```bash
stow_conflict=.config/helix/config.toml  # replace with the exact reported path
stow_backup="${stow_backup:-$HOME/pre-stow-backup-$(date -u +%Y%m%dT%H%M%SZ)}"
case "$stow_conflict" in
  .config/*|.local/*|.pi/*) ;;
  *) printf 'unexpected conflict path: %s\n' "$stow_conflict" >&2; exit 2 ;;
esac
if [[ ! -e "$HOME/$stow_conflict" && ! -L "$HOME/$stow_conflict" ]]; then
  printf 'conflict target is absent: %s\n' "$HOME/$stow_conflict" >&2
  exit 2
fi
ls -ld -- "$HOME/$stow_conflict"
install -d -m 0700 "$stow_backup/$(dirname -- "$stow_conflict")"
mv -- "$HOME/$stow_conflict" "$stow_backup/$stow_conflict"
printf 'preserved conflict under %s\n' "$stow_backup"
./deploy-links.sh --dry-run
```

If preflight reports a symlinked target parent rather than a regular-file
conflict, stop and inspect it with `readlink -f`; do not remove the symlink's
destination. The deployment requires real target directories. Once the dry run
passes, deploy and verify:

```bash
./install.sh --profile "$profile"
case "$profile" in
  desktop) ./bootstrap/fedora/verify.sh --profile desktop ;;
  laptop) ./bootstrap/fedora/verify.sh --profile laptop ;;
esac
sync-control status
test "$(systemctl --user is-active sync-all.timer 2>/dev/null || true)" = inactive
test ! -e "$HOME/.config/systemd/user/timers.target.wants/sync-all.timer"
test "$(readlink -f "$HOME/.config/autostart/org.kde.xwaylandvideobridge.desktop")" = \
  "$HOME/dotfiles/desktop/.config/autostart/org.kde.xwaylandvideobridge.desktop"
desktop-file-validate \
  "$HOME/.config/autostart/org.kde.xwaylandvideobridge.desktop"
```

The same-ID XDG autostart entry retains XWayland Video Bridge for legacy X11
screen sharing in KDE but excludes it from Niri with `OnlyShowIn=KDE;`. Native
Niri portal capture does not require the bridge, and no package-owned file is
changed.

The desktop package owns no SSH-agent selection or key-loading policy. Niri and
Plasma inherit their different package-owned agent sockets from a fresh
session.

Set machine-local Git identity:

```bash
read -r -p 'Git author name: ' git_author_name
read -r -p 'Git author email: ' git_author_email
git config --global user.name "$git_author_name"
git config --global user.email "$git_author_email"
unset git_author_name git_author_email
git config --global --get user.name
git config --global --get user.email
```

Select Fish as the login shell:

```bash
fish_path="$(command -v fish)"
grep -Fx "$fish_path" /etc/shells
chsh -s "$fish_path"
```

## 14. Install and activate keyd/Bongo Cat integration

### Common

Read [`../../system/keyd/README.md`](../../system/keyd/README.md) and memorize
keyd’s `Backspace+Escape+Enter` panic sequence first:

```bash
./install-system.sh --dry-run
sudo ./install-system.sh
sudo udevadm control --reload-rules
sudo systemctl enable keyd.service
sudo systemctl restart keyd.service
test -L /dev/input/by-id/keyd-virtual-kbd
udevadm info /dev/input/by-id/keyd-virtual-kbd
getfacl "$(readlink -f /dev/input/by-id/keyd-virtual-kbd)"
```

Do not add the account to the broad `input` group.

## 15. Enter Niri and materialize Noctalia plugins

### Common

Log out. In Plasma Login Manager, select the package-provided **Niri** session.
Open Ghostty, enter Bash, restore the profile, and return to the repository:

```bash
bash
test -n "$BASH_VERSION"
profile=laptop  # use profile=desktop only on the desktop
case "$profile" in desktop|laptop) ;; *) exit 2 ;; esac
cd "$HOME/dotfiles"
test "$(loginctl show-session "$XDG_SESSION_ID" -p Service --value)" = plasmalogin
systemctl --user enable --now gcr-ssh-agent.socket
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/gcr/ssh"
git ls-remote git@github.com:snaldos/naldo-dots.git refs/heads/main
```

When GCR asks, first check **Automatically unlock this key whenever I'm logged
in**, then enter the SSH-key passphrase and click **Unlock**. GNOME Keyring, not
dotfiles, stores it. Restart GCR and require a silent systemd Git operation:

```bash
systemctl --user restart gcr-ssh-agent.service
systemd-run --user --wait --collect \
  --unit=naldo-bootstrap-gcr-check.service \
  /usr/bin/git -C "$HOME/dotfiles" ls-remote origin refs/heads/main
```

If another prompt appears, stop and repair GCR enrollment before enabling
background synchronization.

In Noctalia Settings → Plugins → Browse Plugins, materialize the official
**Screen Recorder** and **Bongo Cat** plugins. Configure:

```text
Screen Recorder video source: portal
Bongo Cat input device: /dev/input/by-id/keyd-virtual-kbd
```

Do not install World Clock while its catalog entry is incompatible.

## 16. Validate editors, applications, and desktop behavior

### Common automated checks

```bash
niri validate
noctalia config validate "$HOME/.config/noctalia/config.toml"
ghostty +validate-config --config-file="$HOME/.config/ghostty/config.ghostty"
yazi --debug
for language in bash json yaml toml python typst markdown html css \
  javascript typescript jsx tsx; do
  hx --health "$language"
done
for command in gh tuicr code thunderbird pixi basedpyright basedpyright-langserver \
  ruff ty taplo typescript-language-server tsc tsserver; do
  command -v "$command"
done
gh auth status
gh extension list
tuicr --version
code --version
test "$(xdg-mime query default x-scheme-handler/mailto)" = \
  net.thunderbird.Thunderbird.desktop
for extension in ms-python.python ms-toolsai.jupyter charliermarsh.ruff; do
  code --list-extensions | grep -Fxi "$extension"
done
test -f /usr/share/wayland-sessions/niri.desktop
test -f /usr/share/wayland-sessions/plasma.desktop
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
test "$(. /etc/os-release; printf %s "$VARIANT_ID")" = kde
! rpm -q gdm gnome-shell gnome-session mutter >/dev/null 2>&1
systemctl --user status \
  xdg-desktop-portal.service xdg-desktop-portal-gnome.service \
  xdg-desktop-portal-gtk.service pipewire.service wireplumber.service \
  gcr-ssh-agent.socket
```

### Common Pi, Herdr, and Codex machine-local setup

Materialize Herdr's generated Pi integration only after the dotfiles are
deployed. Codex CLI allowance access and Pi provider access then use distinct
machine-local logins. Never copy these generated or credential files between
machines:

```bash
herdr integration install pi
herdr_status="$(herdr integration status)"
grep -Eq '^pi: current \(v[0-9]+\)' <<<"$herdr_status"
unset herdr_status
codex login
codex login status
pi
```

Inside Pi:

1. run `/login` and select **ChatGPT Plus/Pro (Codex)**;
2. run `/model` and select `openai-codex/gpt-5.6-sol`;
3. run `/settings` and set the thinking level to `max`;
4. run `/doctor verbose` and require zero failures; and
5. run `/quit`.

Back in Bash, validate only configuration fields and file modes—not credential
contents:

```bash
jq -e '
  .defaultProvider == "openai-codex" and
  .defaultModel == "gpt-5.6-sol" and
  .defaultThinkingLevel == "max"
' "$HOME/.pi/agent/settings.json"
test "$(stat -c '%a' "$HOME/.pi/agent/settings.json")" = 600
test "$(stat -c '%a' "$HOME/.pi/agent/auth.json")" = 600
test "$(stat -c '%a' "$HOME/.codex/auth.json")" = 600
pi --no-approve --list-models >/dev/null
```

`trust.json` is created only after a project trust decision and is validly absent
on a fresh machine.

### Common manual checks

1. copy and paste text between applications;
2. copy and paste an image;
3. copy content, close it, then paste again;
4. open Noctalia's clipboard history and select an older item;
5. verify Bongo Cat reacts to typing;
6. verify Thunderbird opens mail/calendar links;
7. verify VS Code can select a Pixi/uv project interpreter and open a notebook;
8. test the Noctalia recorder in portal mode;
9. press `Mod+T` and `Mod+Z`; confirm ordinary Ghostty and new Zen windows both
   open in Niri’s default tiled layout;
10. log out, select **Plasma** in PLM, and complete the login, display, input,
    network, Bluetooth, audio, lock/unlock, suspend/resume, portal, PolicyKit,
    Dolphin, Konsole, and System Settings baseline in
    [`DESKTOPS.md`](DESKTOPS.md); and
11. log out of Plasma, return to **Niri**, and confirm unchanged Noctalia,
    keyring, clipboard, recording, browser open/save/upload, and portal behavior.

Both selected sessions must pass through the already-active PLM before the first
reboot acceptance gate:

```bash
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
systemctl is-enabled plasmalogin.service
systemctl is-active plasmalogin.service
! rpm -q gdm >/dev/null 2>&1
```

## 17. Enroll Tailscale and keep inbound SSH disabled

### Common

```bash
case "$profile" in
  desktop) machine_hostname=naldo-desktop ;;
  laptop) machine_hostname=naldo-laptop ;;
esac
sudo hostnamectl set-hostname "$machine_hostname"
sudo systemctl enable --now tailscaled.service
sudo tailscale up --hostname="$machine_hostname" --ssh=false
tailscale status
test "$(tailscale debug prefs | jq -r '.RunSSH')" = false
! rpm -q openssh-server >/dev/null 2>&1
test "$(systemctl is-active sshd.service 2>/dev/null || true)" = inactive
```

No reusable auth key, Tailscale SSH, firewall opening, or inbound OpenSSH server
is selected.

## 18. Reboot and accept the final two-session topology

### Common

Keep synchronization disabled, verify the staged boot alias, then reboot:

```bash
sync-control status
test "$(systemctl --user is-active sync-all.timer 2>/dev/null || true)" = inactive
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
sudo systemctl reboot
```

In Plasma Login Manager, select **Niri**. Open Ghostty, enter Bash, and restore
the profile:

```bash
bash
test -n "$BASH_VERSION"
profile=laptop  # use profile=desktop only on the desktop
case "$profile" in desktop|laptop) ;; *) exit 2 ;; esac
cd "$HOME/dotfiles"
```

Prove PLM → Niri and silent GNOME-Keyring/GCR access before any timer is
enabled:

```bash
test "$(loginctl show-session "$XDG_SESSION_ID" -p Service --value)" = plasmalogin
test "$(loginctl show-session "$XDG_SESSION_ID" -p Type --value)" = wayland
systemctl is-active plasmalogin.service
systemctl is-active keyd.service
systemctl is-active tailscaled.service
systemctl --user is-active niri.service
systemctl --user is-active gcr-ssh-agent.socket
test "$(systemctl --user is-active \
  'app-org.kde.xwaylandvideobridge@autostart.service' 2>/dev/null || true)" = inactive
test "$(niri msg -j windows | \
  jq '[.[] | select(.app_id == "xwaylandvideobridge")] | length')" = 0
test "$(fish -lc 'printf %s "$SSH_AUTH_SOCK"')" = "$XDG_RUNTIME_DIR/gcr/ssh"
systemd-run --user --wait --collect \
  --unit=naldo-post-reboot-git-check.service \
  /usr/bin/git -C "$HOME/dotfiles" ls-remote origin refs/heads/main
```

That Git command must not prompt for a passphrase. Verify storage and LFS:

```bash
if [[ "$profile" == desktop ]]; then
  findmnt --mountpoint /mnt/data
  test "$(readlink -f "$HOME/Wallpapers")" = /mnt/data/repos/Wallpapers
  nvidia-smi
else
  test ! -L "$HOME/Wallpapers"
fi
git -C "$HOME/Vaults/state-space" lfs fsck
git -C "$HOME/Wallpapers" lfs fsck
case "$profile" in
  desktop) ./bootstrap/fedora/verify.sh --profile desktop ;;
  laptop) ./bootstrap/fedora/verify.sh --profile laptop ;;
esac
```

Log out, select **Plasma** in PLM, and repeat the Plasma acceptance gate. Do not
manually unlock a wallet at login. In Konsole, enter Bash and verify the
canonical PAM-opened wallet and Fedora's package-owned OpenSSH agent:

```bash
bash
test -n "$BASH_VERSION"
test "$(loginctl show-session "$XDG_SESSION_ID" -p Service --value)" = plasmalogin
test "$(loginctl show-session "$XDG_SESSION_ID" -p Desktop --value)" = KDE
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/ssh-agent.socket"
test "$(fish -lc 'printf %s "$SSH_AUTH_SOCK"')" = \
  "$XDG_RUNTIME_DIR/ssh-agent.socket"
systemctl --user show-environment | \
  grep -Fx "SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket"
systemctl --user is-active ssh-agent.socket ssh-agent.service
systemctl --user is-active \
  'app-org.kde.xwaylandvideobridge@autostart.service'
grep -Fx 'Default Wallet=kdewallet' "$HOME/.config/kwalletrc"
test "$(qdbus-qt6 org.kde.ksecretd /ksecretd org.kde.KWallet.isOpen kdewallet)" = true
! journalctl --user -b --no-pager | \
  grep -F 'Wallet failed to get opened by PAM, error code is -9'
```

OpenSSH keeps an unlocked key only in memory, and no custom key-loading
autostart is installed. After reboot, load the key manually from a Plasma
terminal and prove that the exact key and a user service use the same agent:

```bash
ssh-add "$HOME/.ssh/id_ed25519"
ssh-add -T "$HOME/.ssh/id_ed25519.pub"
systemd-run --user --wait --collect \
  --unit=naldo-plasma-openssh-check.service \
  /usr/bin/git -C "$HOME/dotfiles" ls-remote origin refs/heads/main
```

Repeat the manual `ssh-add` after an agent restart or reboot. KWallet remains
available for Plasma application secrets, but standard OpenSSH-agent use does
not store the SSH passphrase there.

Log out and return to **Niri**. This rechecks the primary path and makes Niri
PLM's remembered default. Open Ghostty, enter Bash, and restore the profile:

```bash
bash
test -n "$BASH_VERSION"
profile=laptop  # use profile=desktop only on the desktop
case "$profile" in desktop|laptop) ;; *) exit 2 ;; esac
cd "$HOME/dotfiles"
test "$(loginctl show-session "$XDG_SESSION_ID" -p Service --value)" = plasmalogin
systemctl --user is-active xdg-desktop-portal.service
systemctl --user is-active xdg-desktop-portal-gnome.service
systemctl --user is-active xdg-desktop-portal-gtk.service
systemctl --user is-active gcr-ssh-agent.socket
```

Both selected sessions are now accepted through PLM. Confirm that the KDE
Edition identity and Niri's explicitly selected GNOME infrastructure survived
the reboot:

```bash
test "$(. /etc/os-release; printf %s "$VARIANT_ID")" = kde
rpm -q fedora-release-kde-desktop fedora-release-identity-kde-desktop
rpm -V fedora-release-identity-kde-desktop
rpm -q \
  niri xwayland-satellite noctalia \
  gnome-keyring gnome-keyring-pam gcr nautilus \
  xdg-desktop-portal xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk xdg-desktop-portal-kde
for package in gdm gnome-shell gnome-session \
  gnome-session-wayland-session gnome-classic-session mutter; do
  ! rpm -q "$package" >/dev/null 2>&1
done
dnf check
```

### Desktop only

Keep Fedora's selected `thermald` package installed. The selected i5-13400F
desktop is not a mobile thermal platform, so disable only its inapplicable
service rather than removing the package:

```bash
test "$profile" = desktop
rpm -q thermald
sudo systemctl disable --now thermald.service
test "$(systemctl is-enabled thermald.service 2>/dev/null || true)" = disabled
```

### Laptop only

Retain and enable Fedora's thermal service on supported laptop hardware:

```bash
test "$profile" = laptop
rpm -q thermald
sudo systemctl enable --now thermald.service
systemctl is-active thermald.service
```

### Common final verification

Do not turn the explicit Niri integration list into a GNOME-name-based cleanup.
Verify the KDE identity, two-session closure, and retained package-owned GNOME
infrastructure:

```bash
rpm -q \
  fedora-release-kde-desktop fedora-release-identity-kde-desktop nautilus \
  niri noctalia plasma-login-manager plasma-desktop plasma-workspace kwin \
  pam-kwallet gnome-keyring gnome-keyring-pam gcr \
  xdg-desktop-portal xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk xdg-desktop-portal-kde
for package in gdm gnome-shell gnome-session \
  gnome-session-wayland-session gnome-classic-session mutter; do
  ! rpm -q "$package" >/dev/null 2>&1
done
for session in niri.desktop plasma.desktop; do
  test -f "/usr/share/wayland-sessions/$session"
done
test ! -e /usr/share/wayland-sessions/gnome.desktop
test ! -e /usr/share/wayland-sessions/gnome-classic.desktop
test ! -e "$HOME/.config/xdg-desktop-portal/portals.conf"
test ! -e "$HOME/.config/xdg-desktop-portal/niri-portals.conf"
rpm -qf /usr/share/xdg-desktop-portal/niri-portals.conf
test "$(readlink -f /etc/systemd/system/display-manager.service)" = \
  /usr/lib/systemd/system/plasmalogin.service
systemctl is-enabled plasmalogin.service
systemctl is-active plasmalogin.service
test "$(systemctl show gdm.service -p LoadState --value 2>/dev/null || true)" = \
  not-found
dnf check
systemd-run --user --wait --collect \
  --unit=naldo-final-agent-check.service \
  /usr/bin/git -C "$HOME/dotfiles" ls-remote origin refs/heads/main
case "$profile" in
  desktop) ./bootstrap/fedora/verify.sh --profile desktop ;;
  laptop) ./bootstrap/fedora/verify.sh --profile laptop ;;
esac
```

## 19. Test synchronization and enable the timer last

### Common

Run the mutating repository tasks sequentially, never in parallel:

```bash
sync-control status
sync-all dotfiles
sync-all notes
sync-all wallpapers
```

Require clean repositories equal to their remotes:

```bash
for repo in "$HOME/dotfiles" "$HOME/Vaults/state-space" "$HOME/Wallpapers"; do
  test -z "$(git -C "$repo" status --porcelain)"
  test "$(git -C "$repo" rev-parse HEAD)" = \
    "$(git -C "$repo" rev-parse origin/main)"
done
```

Enable and exercise the real systemd service only now:

```bash
sync-control enable
systemctl --user start sync-all.service
test "$(systemctl --user is-enabled sync-all.timer)" = enabled
test "$(systemctl --user is-active sync-all.timer)" = active
test "$(systemctl --user show sync-all.service -p Result --value)" = success
test "$(systemctl --user show sync-all.service -p ExecMainStatus --value)" = 0
sync-control status
```

On failure, immediately run `sync-control disable`, fix the concrete cause, and
repeat all three manual tasks before re-enabling.

## 20. Completion boundary

The machine is complete when:

- `/etc/os-release` and the selected release packages identify Fedora KDE
  Plasma Desktop Edition;
- the selected profile verifier has zero missing required items;
- all repository tests pass;
- GCR unlocks silently in Niri, Plasma's OpenSSH key is loaded with `ssh-add`,
  and systemd Git access succeeds in the selected session;
- `gh`, `gh-dash`, Tuicr, Thunderbird, VS Code, and the selected VS Code
  extensions are present;
- Herdr's generated Pi integration is current, Codex CLI and Pi have separate
  working machine-local logins, and Pi doctor has zero failures;
- Helix TypeScript/JavaScript LSP, BasedPyright, project-opt-in `ty`, Ruff, and
  Prettier are healthy;
- Plasma Login Manager offers package-provided Niri and Plasma Wayland
  sessions, remembers Niri as preferred, and GDM/GNOME Shell/session are absent;
- Niri, Noctalia, Plasma, both PAM/keyring paths, retained GNOME/GTK portal
  infrastructure, keyd/Bongo Cat, Tailscale, and storage survive reboot;
- `openssh-server` is absent and Tailscale SSH is false;
- Notes and Wallpapers pass LFS checks;
- all three repositories are clean and synchronized; and
- `sync-all.timer` is enabled only after the manual and systemd runs pass.

For maintenance use [`../../MAINTENANCE.md`](../../MAINTENANCE.md). For detailed
recovery and trust boundaries use [`DESKTOPS.md`](DESKTOPS.md),
[`EDITOR-TOOLS.md`](EDITOR-TOOLS.md), [`REMOTE-ACCESS.md`](REMOTE-ACCESS.md),
[`WALLPAPERS.md`](WALLPAPERS.md), and
[`../../system/keyd/README.md`](../../system/keyd/README.md).
