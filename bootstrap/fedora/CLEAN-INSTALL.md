# Ordered Fedora Workstation clean installation

This is a human-run checklist, not an installer. Stop on any unexpected package,
signature, repository, device, desktop ID, or validation result. Commands that
change system state are intentionally confined to this documentation.

| Difference | Desktop | Laptop |
|---|---|---|
| installer profile | `desktop` | `laptop` |
| graphics | Fedora Intel stack plus reviewed RPM Fusion NVIDIA packages | Fedora Intel stack only |
| wallpaper storage | manually mounted HDD at `/mnt/data`, physical repo below it, logical symlink and required-mount guard | direct `$HOME/Wallpapers` SSD worktree, empty guard |
| device SSH label | `naldo-fedora-desktop` | `naldo-fedora-laptop` |
| keyd mapping | shared reviewed mapping | shared reviewed mapping |

Manifest commands later in the guide use one explicit profile. Rows marked
`all` apply to either machine; no hardware auto-detection or separate manifest
branch is used.

## 1. Install Fedora Workstation

Install the current stable Fedora Workstation through the normal Fedora boot and
Anaconda path. Keep GNOME/GDM as delivered. The desktop has Intel graphics plus
NVIDIA, an SSD, and a secondary HDD; the laptop has Intel integrated graphics
and one SSD. Do not configure the desktop HDD from a laptop recipe.

Before erasing the old system, verify browser access to GitHub, 2FA, and recovery
codes. Private SSH keys are not copied from the erased installation by default.

## 2. Update Fedora

```bash
sudo dnf upgrade --refresh
reboot
```

After the reboot, choose one profile for the rest of this shell session:

```bash
profile=desktop  # use profile=laptop on the laptop
case "$profile" in
  desktop|laptop) ;;
  *) printf 'invalid profile: %s\n' "$profile" >&2; exit 2 ;;
esac
```

Set and validate it again after opening a new shell.

## 3. Install official Fedora packages

Review `dnf-packages.tsv` and confirm the enabled Fedora repositories first:

```bash
dnf repolist --enabled
mapfile -t fedora_packages < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $2 != "optional" && ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/dnf-packages.tsv)
printf '  %s\n' "${fedora_packages[@]}"
sudo dnf install "${fedora_packages[@]}"
```

Fedora 44 is the audited baseline. It provides Niri, Noctalia, Helix (`hx`),
OpenSSH, Rust/Cargo, the requested desktop applications, and the package names
listed in the manifest. It does not provide the selected Typst CLI/editor tools,
Ghostty, Yazi, or keyd through official Fedora repositories.

## 4. Review and enable only selected external sources

Read `README.md`, `external-tools.tsv`, and each repository's source/spec,
build history, and signing boundary before enabling it. First review only the
rows applicable to this machine:

```bash
awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) { print $1 "\t" $3 "\t" $4 }
' bootstrap/fedora/external-tools.tsv
```

Reviewed community COPRs:

```bash
sudo dnf copr enable scottames/ghostty
sudo dnf copr enable lihaohong/yazi
sudo dnf copr enable alternateved/keyd
sudo dnf install ghostty yazi keyd
```

LazyGit and Starship use separate upstream-documented third-party COPRs. COPR
provides Fedora-hosted build infrastructure.
A COPR is not an official Fedora package source. DNF owns installation, updates,
and removal:

```bash
sudo dnf copr enable dejan/lazygit
sudo dnf copr enable atim/starship
sudo dnf install lazygit starship
```

Google Chrome is an intentionally selected secondary browser. Download the
official RPM as a file, verify it against Google's published signing-key
documentation, and then install that reviewed local file:

```bash
curl --proto '=https' --tlsv1.2 --fail --location \
  --output /tmp/google-chrome-stable_current_x86_64.rpm \
  https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
rpm --verbose --checksig -v /tmp/google-chrome-stable_current_x86_64.rpm
sudo dnf install /tmp/google-chrome-stable_current_x86_64.rpm
rm /tmp/google-chrome-stable_current_x86_64.rpm
```

Tailscale's official stable repository uses current DNF5 syntax here. Fedora 44
also publishes the same package name, so constrain this transaction to the
selected `tailscale-stable` vendor repository. Install the package now but defer
service activation and login to step 17:

```bash
sudo dnf config-manager addrepo \
  --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install --from-repo=tailscale-stable tailscale
```

Desktop only: review RPM Fusion's current Fedora and Secure Boot documentation,
then enable its signed free/nonfree release packages so the NVIDIA step has one
reviewed source:

```bash
sudo dnf install \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
```

The laptop skips RPM Fusion when it has no other selected dependency.

Herdr uses its official upstream installer on the stable channel. Never pipe the
remote script into a shell: download and inspect the complete local file before
execution. Record the local ownership receipt required by `naldo-update` after
the installer succeeds:

```bash
herdr_installer="$(mktemp "${TMPDIR:-/tmp}/herdr-install.XXXXXX.sh")"
curl --proto '=https' --tlsv1.2 --fail --location \
  --output "$herdr_installer" https://herdr.dev/install.sh
hx "$herdr_installer"
sh "$herdr_installer"
rm -f -- "$herdr_installer"

herdr_path="$(readlink -f -- "$(command -v herdr)")"
[[ "$herdr_path" == "$(readlink -m -- "$HOME/.local/bin/herdr")" ]]
herdr channel set stable
[[ "$(herdr channel show)" == stable ]]
herdr --version

receipt_dir="${XDG_DATA_HOME:-$HOME/.local/share}/naldo/provider-receipts"
install -d -m 0700 "$receipt_dir"
receipt_tmp="$(mktemp --tmpdir="$receipt_dir" '.herdr-receipt.XXXXXX')"
printf 'source=https://herdr.dev/install.sh\nbinary=%s\n' "$herdr_path" >"$receipt_tmp"
chmod 0600 "$receipt_tmp"
mv -f -- "$receipt_tmp" "$receipt_dir/herdr-official-installer"
```

Upstream documents `herdr update` for direct installs but currently no dedicated
Linux uninstaller.

Pixi remains development-only and is not selected in this inventory. If it is
needed later, download and inspect `https://pixi.sh/install.sh` locally; only an
official-installer installation at `~/.pixi/bin/pixi` uses `pixi self-update`.
Do not introduce mise or a generic GitHub binary updater.

JetBrainsMono Nerd Font is the reviewed official Nerd Fonts `v3.5.0` release.
Install only the `JetBrainsMonoNerdFont-*.ttf` base-family files from the
checksum-verified `JetBrainsMono.zip` into
`~/.local/share/fonts/JetBrainsMonoNerdFont`, refresh `fc-cache`, and require the
exact family `JetBrainsMono Nerd Font`. See `MAINTENANCE.md` for updating and
removal. Do not duplicate any command from another provider.

## 5. Install default Flatpaks

Review Flathub and the selected IDs first, then install the applicable required
applications:

```bash
mapfile -t flatpak_ids < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $2 != "optional" && ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/flatpaks.tsv)
printf '  %s\n' "${flatpak_ids[@]}"
flatpak remotes --show-details
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub "${flatpak_ids[@]}"
```

Sioyek (`com.github.ahrm.sioyek`) is optional and currently community-maintained
and unverified. Vesktop (`dev.vencord.Vesktop`) is an optional non-default
fallback only. Missing optional Flatpaks does not fail required verification.

`com.dec05eba.gpu_screen_recorder` is the sole GPU Screen Recorder provider. The
official Noctalia `noctalia/screen_recorder` plugin natively detects this Flatpak
and invokes:

```bash
flatpak run --command=gpu-screen-recorder com.dec05eba.gpu_screen_recorder ARGS...
```

No native wrapper or second recorder is needed. Keep the plugin's portal capture
under Niri and use Noctalia's widget or Control Center. Do not enable recorder
autostart or global hotkeys during provisioning.

## 6. Install npm, uv, and Cargo tools

Follow `EDITOR-TOOLS.md`. Use `~/.npm-global`, never root npm:

```bash
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
mapfile -t npm_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/npm-packages.tsv)
npm install --global "${npm_tools[@]}"

mapfile -t uv_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && $4 == "active" &&
    ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/uv-tools.tsv)
for tool in "${uv_tools[@]}"; do
  uv tool install "$tool"
done
# Optional experiment only; Helix does not activate it:
uv tool install ty@latest

# Print applicable deliberately pinned Cargo commands. Review and execute each line.
awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) { print $5 }
' bootstrap/fedora/cargo-tools.tsv
```

Only the Cargo manifest retains versions/tags because those commands are
intentional reproducibility constraints. npm and uv tools follow their reviewed
stable channels without stale snapshot metadata.

## 7. Configure NVIDIA on the desktop only

After reviewing the current RPM Fusion NVIDIA page and Secure Boot requirements,
install the current RPM Fusion packages:

```bash
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
```

Wait for the akmod build to finish before rebooting. Validate the built module
and driver with the current RPM Fusion procedure and `nvidia-smi`. The laptop
skips this entire step and uses Fedora's Intel graphics stack.

## 8. Generate a new SSH key and add it to GitHub

Read `REMOTE-ACCESS.md`. Ensure browser account recovery is available, then:

```bash
install -d -m 0700 "$HOME/.ssh"
# Choose exactly one machine-specific comment:
ssh-keygen -t ed25519 -a 100 -C "naldo-fedora-desktop"
ssh-keygen -t ed25519 -a 100 -C "naldo-fedora-laptop"
cat "$HOME/.ssh/id_ed25519.pub"   # public key only
ssh -T git@github.com
```

Use a passphrase and a distinct GitHub device title. Never print or copy the
private key from another machine by default.

## 9. Clone dotfiles and notes

```bash
git clone GIT-DOTFILES-REMOTE "$HOME/dotfiles"
git clone GIT-NOTES-REMOTE "$HOME/Vaults/second-brain"
```

Create machine-local Git identity/signing configuration separately. Do not put
credentials in the dotfiles.

## 10. Desktop: mount the HDD and clone/symlink wallpapers

Follow `WALLPAPERS.md`: identify the HDD with `lsblk`, mount the verified
partition manually at `/mnt/data`, require `findmnt --mountpoint /mnt/data` to
succeed, clone to `/mnt/data/repos/Wallpapers`, and link
`$HOME/Wallpapers` to it. Initialize the private sync file once, then edit it:

```bash
"$HOME/dotfiles/automation/.local/libexec/naldo/init-sync-config" \
  --config "$HOME/.config/naldo/sync/repositories.conf" \
  --template "$HOME/dotfiles/automation/.config/naldo/sync/repositories.conf.example"
hx "$HOME/.config/naldo/sync/repositories.conf"
```

Set:

```text
wallpapers_path=~/Wallpapers
WALLPAPERS_REQUIRED_MOUNT=/mnt/data
```

No dotfiles script creates or mounts this path.

## 11. Laptop: clone wallpapers directly

```bash
git clone GIT-WALLPAPERS-REMOTE "$HOME/Wallpapers"
"$HOME/dotfiles/automation/.local/libexec/naldo/init-sync-config" \
  --config "$HOME/.config/naldo/sync/repositories.conf" \
  --template "$HOME/dotfiles/automation/.config/naldo/sync/repositories.conf.example"
hx "$HOME/.config/naldo/sync/repositories.conf"
```

Keep:

```text
wallpapers_path=~/Wallpapers
WALLPAPERS_REQUIRED_MOUNT=
```

## 12. Deploy user configuration

```bash
cd "$HOME/dotfiles"
./install.sh --profile desktop    # desktop
./install.sh --profile laptop     # laptop
```

This performs only user-owned Stow deployment and machine-local initialization.
Before the first session, it creates safe machine-local fallbacks for Ghostty's
Noctalia theme, Helix's base theme, and Zathura's color include. It does not
provision Fedora, render Noctalia state in the repository, or enable
synchronization.

## 13. Run the Fedora verifier

```bash
./bootstrap/fedora/verify.sh --profile desktop  # desktop
./bootstrap/fedora/verify.sh --profile laptop   # laptop
```

Resolve required misses. Optional Sioyek, Vesktop, `ty`, and other optional rows
may remain absent.

## 14. Install the reviewed keyd configuration

Read `system/keyd/README.md` and know the panic/recovery path first:

```bash
./install-system.sh --dry-run
sudo ./install-system.sh
sudo udevadm control --reload-rules
sudo systemctl restart keyd.service
```

The udev reload and keyd restart are explicit activation steps, not installer
actions. Verify `/dev/input/by-id/keyd-virtual-kbd`, its `uaccess` tag/ACL, and
`keyd monitor` as documented in `system/keyd/README.md`.

## 15. Enter the Niri session through GDM

Run step 12 before the first Niri login. Then log out of GNOME, select the
package-provided Niri session in GDM, and log in. Do not replace GDM or create a
custom session entry.

Niri starts Noctalia, which resolves its palette and renders enabled templates
into ignored machine-local files. This may complete after the session is already
usable. Until then, Niri's Noctalia include is optional, Yazi uses its defaults,
and the installer-created Ghostty, Helix, and Zathura fallbacks are valid. The
audited Ghostty 1.3.1 treats a missing theme as a nonfatal configuration error
and falls back, but it reports the error and fails config validation; the seeded
theme avoids that degraded first launch. Do not copy generated Niri, Ghostty,
Helix, Yazi, or Zathura files between machines;
let the local Noctalia instance replace or create them.

Plugin payloads are machine-local. In **Noctalia Settings → Plugins → Browse
Plugins**, open **Screen Recorder** (`noctalia/screen_recorder`) and choose **Add
to Noctalia** if it has not already materialized from the tracked enabled ID.
Confirm its `video_source` remains `portal`. Noctalia's ordinary static wallpaper
feature and the `~/Wallpapers` directories remain unchanged.

## 16. Validate the desktop session and applications

```bash
niri validate
noctalia config validate "$HOME/.config/noctalia/config.toml"
gsr_location="$(flatpak info --show-location com.dec05eba.gpu_screen_recorder)"
test -x "$gsr_location/files/bin/gpu-screen-recorder"
ghostty +validate-config --config-file="$HOME/.config/ghostty/config.ghostty"
yazi --debug
systemctl --user status xdg-desktop-portal.service pipewire.service wireplumber.service
niri msg -j outputs
niri msg -j windows
hx --health bash
hx --health json
hx --health yaml
hx --health toml
hx --health python
hx --health typst
hx --health markdown
```

### First-session clipboard test

Fedora's `wl-clipboard` supplies `wl-copy` and `wl-paste`; Noctalia owns history
and closed-source persistence. Confirm both CLI commands, then test manually:

1. copy and paste text between applications;
2. copy and paste an image;
3. copy from an application, close it, then paste again;
4. open Noctalia's clipboard history, select an older item, and paste it.

Confirm PipeWire/WirePlumber, portals, PolicyKit, Secret Service, Zen, Firefox,
Chrome, Discord, Obsidian, Thunderbird, Swappy, Ghostty, Yazi, GPU Screen
Recorder as a standalone Flatpak and through Noctalia's portal-mode recorder,
Bongo Cat input reactivity, and the real Zen/Swappy app IDs. Do not configure GPU
Screen Recorder global hotkeys or autostart during this check.
Install Noctalia plugins and credentials only through their machine-local paths.

## 17. Configure Tailscale interactively

On each machine independently:

```bash
sudo systemctl enable --now tailscaled.service
sudo tailscale up
tailscale version
tailscale status
systemctl status tailscaled.service
```

Never reuse an enrollment state or pre-authentication key from the erased system.

## 18. Enable SSH server only when deliberately desired

```bash
sudo sshd -t
sudo systemctl enable --now sshd.service
systemctl status sshd.service
```

Do not automate firewall, authentication-policy, root-login, or Tailscale-SSH
changes. Authorize inter-machine public keys manually with `ssh-copy-id` only
after verifying host identity.

## 19. Test each synchronization task manually

Inspect `~/.config/naldo/sync/repositories.conf`, verify the desktop mount guard
where applicable, then run tasks one at a time. These commands can commit,
rebase, and push:

```bash
sync-all dotfiles
sync-all notes
sync-all wallpapers
sync-control status
```

## 20. Enable the timer last

Only after all three tasks and recovery paths are confirmed:

```bash
sync-control enable
sync-control status
```
