#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
DNF="$REPO_DIR/bootstrap/fedora/dnf-packages.tsv"
EXTERNAL="$REPO_DIR/bootstrap/fedora/external-tools.tsv"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/fedora-cutover-test.XXXXXX")"
checks=0
trap 'rm -rf -- "$workspace"' EXIT

fail() {
  printf 'not ok %d - %s\n' "$((checks + 1))" "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$1"
}

for package in openssh-clients gcr xwaylandvideobridge gh git-lfs nodejs22 nodejs22-npm rust cargo gcc gcc-c++ make cmake pkgconf-pkg-config fontconfig gnupg2 tar evtest; do
  [[ "$(awk -F '\t' -v package="$package" '$1 == package { count++ } END { print count+0 }' "$DNF")" == 1 ]] ||
    fail "missing exact Fedora package: $package"
done
for obsolete in openssh-server npm nodejs nodejs-npm typst ruff celluloid; do
  ! awk -F '\t' -v package="$obsolete" '$1 == package { found=1 } END { exit !found }' "$DNF" ||
    fail "non-selected DNF provider remains: $obsolete"
done
awk -F '\t' '$1 == "gcr" && $2 == "feature" && $5 == "user:gcr-ssh-agent.socket" { found=1 } END { exit !found }' \
  "$DNF" || fail 'GCR does not own the selected Niri/GNOME SSH-agent socket'
awk -F '\t' '$1 == "git-lfs" && $2 == "feature" && $3 == "git-lfs" { found=1 } END { exit !found }' \
  "$DNF" || fail 'Git LFS is not a selected Fedora feature'
for ownership in \
  coreutils:id coreutils:stat coreutils:sync coreutils:ln coreutils:nl \
  util-linux:lsblk util-linux:mount util-linux:umount util-linux:chsh \
  systemd:systemd-run systemd:hostnamectl fontconfig:fc-cache xdg-utils:xdg-mime; do
  package="${ownership%%:*}"
  command="${ownership#*:}"
  awk -F '\t' -v package="$package" -v command="$command" '
    $1 == package {
      count=split($3, commands, ",")
      for (i=1; i<=count; i++) if (commands[i] == command) found=1
    }
    END { exit !found }
  ' "$DNF" || fail "clean-install command $command is not owned by $package"
done
pass 'Fedora manifest owns selected SSH GCR LFS development and clean-install commands'

! find "$REPO_DIR/desktop" -type f \
  \( -iname '*ssh*agent*' -o -iname '*ssh*add*' \) -print -quit | grep -q . ||
  fail 'the desktop package still owns SSH-agent or key-loading policy'
for vendor_path in \
  /etc/xdg/plasma-workspace/env/ssh-agent.sh \
  /usr/lib/systemd/user/plasma-core.target.d/ssh-agent.conf; do
  grep -Fq "$vendor_path" "$REPO_DIR/bootstrap/fedora/DESKTOPS.md" ||
    fail "desktop runbook omits Fedora Plasma agent source: $vendor_path"
done
# These variables belong literally to the documented session checks.
# shellcheck disable=SC2016
for session_check in \
  '$XDG_RUNTIME_DIR/gcr/ssh' \
  '$XDG_RUNTIME_DIR/ssh-agent.socket' \
  'ssh-add "$HOME/.ssh/id_ed25519"'; do
  grep -Fq "$session_check" "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
    fail "clean install omits native session-agent check: $session_check"
done
grep -Fq "Retain Fedora's session-native agent selection" \
  "$REPO_DIR/bootstrap/fedora/DESKTOPS.md" ||
  fail 'desktop runbook does not preserve Fedora session-native agents'
grep -Fq 'key-loading autostart; key loading in Plasma is manual' \
  "$REPO_DIR/bootstrap/fedora/DESKTOPS.md" ||
  fail 'desktop runbook does not make Plasma key loading explicitly manual'
pass 'native SSH agents retain manual Plasma key loading without tracked overrides'

video_bridge_autostart="$REPO_DIR/desktop/.config/autostart/org.kde.xwaylandvideobridge.desktop"
[[ -f "$video_bridge_autostart" && ! -L "$video_bridge_autostart" ]] ||
  fail 'XWayland Video Bridge autostart policy is not a regular tracked source'
desktop-file-validate "$video_bridge_autostart" ||
  fail 'XWayland Video Bridge autostart policy is invalid'
grep -Fqx 'OnlyShowIn=KDE;GNOME;' "$video_bridge_autostart" ||
  fail 'XWayland Video Bridge is not excluded from the Niri session'
! grep -Eq '^(Hidden=true|NotShowIn=)' "$video_bridge_autostart" ||
  fail 'XWayland Video Bridge policy disables more than the selected session scope'
awk -F '\t' '
  $1 == "xwaylandvideobridge" && $2 == "feature" &&
  $3 == "xwaylandvideobridge" &&
  $4 == "application:org.kde.xwaylandvideobridge.desktop" { found=1 }
  END { exit !found }
' "$DNF" || fail 'XWayland Video Bridge source is not owned by the Fedora manifest'
grep -Fq 'OnlyShowIn=KDE;GNOME;' "$REPO_DIR/bootstrap/fedora/DESKTOPS.md" ||
  fail 'desktop runbook omits the session-scoped video-bridge policy'
pass 'XWayland Video Bridge remains installed for legacy sharing without entering Niri'

for package in fedora-release-workstation gdm gnome-shell \
  gnome-session-wayland-session mutter; do
  awk -F '\t' -v package="$package" '
    $1 == package && ($2 == "session" || $2 == "feature") { found=1 }
    END { exit !found }
  ' "$DNF" || fail "required Workstation anchor is absent: $package"
done
awk -F '\t' '$1 == "gdm" && $2 == "feature" && $5 == "system:gdm.service" { found=1 } END { exit !found }' \
  "$DNF" || fail 'installed rollback GDM is not represented without selecting it as active'

for package in plasma-desktop plasma-workspace kwin xdg-desktop-portal-kde polkit-kde \
  plasma-systemsettings dolphin konsole; do
  awk -F '\t' -v package="$package" '
    $1 == package && ($2 == "session" || $2 == "feature") { found=1 }
    END { exit !found }
  ' "$DNF" || fail "required Plasma anchor is absent: $package"
done
awk -F '\t' '$1 == "plasma-login-manager" && $2 == "session" && $5 == "system:plasmalogin.service" { found=1 } END { exit !found }' \
  "$DNF" || fail 'Plasma Login Manager is not the selected display-manager anchor'
for package in pam-kwallet gnome-keyring-pam; do
  awk -F '\t' -v package="$package" '$1 == package && $2 == "session" { found=1 } END { exit !found }' \
    "$DNF" || fail "selected login PAM package is absent: $package"
done
awk -F '\t' '$1 == "plasma-setup" && $2 == "optional" && $5 == "system:plasma-setup.service" { found=1 } END { exit !found }' \
  "$DNF" || fail 'disabled Plasma OOBE group member is not documented'
grep -Fq 'sudo dnf group install kde-desktop' "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
  fail 'clean install does not install Fedora KDE as a coherent comps group'
grep -Fq 'Keep Fedora Workstation intact and add Niri and KDE' \
  "$REPO_DIR/bootstrap/fedora/DESKTOPS.md" ||
  fail 'desktop runbook does not preserve the Workstation/Niri/KDE composition'
grep -Fq 'sudo systemctl disable plasma-setup.service' "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
  fail 'clean install would leave Plasma OOBE enabled on an existing Workstation'
grep -Fq 'sudo systemctl disable gdm.service' "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
  fail 'clean install never stages the reviewed GDM to PLM cutover'
grep -Fq 'sudo systemctl enable plasmalogin.service' "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
  fail 'clean install never selects Plasma Login Manager'
if rg -n 'gnome_surface_candidates|redundant_workstation_candidates|--setopt=protected_packages=' \
  "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" >/dev/null; then
  fail 'clean install still removes or overrides protection for the Workstation desktop'
fi
grep -Fq 'Do not run a general autoremove' "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
  fail 'clean install does not protect retained cross-desktop dependencies'
pass 'intact Workstation and Fedora KDE group anchor PLM with both PAM integrations'

[[ ! -e "$REPO_DIR/xdg-desktop-portal" ]] ||
  fail 'a user portal-policy Stow package still masks Fedora desktop defaults'
grep -Fq '/usr/share/xdg-desktop-portal/niri-portals.conf' \
  "$REPO_DIR/bootstrap/fedora/DESKTOPS.md" ||
  fail 'Niri package-owned portal policy is not documented'
awk -F '\t' '$1 == "nautilus" && $2 == "session" && $4 == "application:org.gnome.Nautilus.desktop" { found=1 } END { exit !found }' \
  "$DNF" || fail 'Nautilus is not retained as the GNOME portal FileChooser delegate'
pass 'package-owned desktop portal policies preserve native Niri GNOME and Plasma behavior'

awk -F '\t' '$1 == "wl-clipboard" && $2 == "feature" && $3 == "wl-copy,wl-paste" { found=1 } END { exit !found }' \
  "$DNF" || fail 'wl-clipboard does not own both CLI copy/paste commands'
awk -F '\t' '$1 == "procps-ng" && $2 == "feature" && $3 == "pkill" { found=1 } END { exit !found }' \
  "$DNF" || fail 'Noctalia recorder process control does not require pkill'
grep -Fq 'clipboard_enabled = true' "$REPO_DIR/noctalia/.config/noctalia/config.toml" ||
  fail 'Noctalia internal clipboard history is not explicit'
grep -Fq 'clipboard_keep_from_closed_apps = true' "$REPO_DIR/noctalia/.config/noctalia/config.toml" ||
  fail 'Noctalia internal clipboard ownership is not explicit'
for step in \
  'copy and paste text between applications' \
  'copy and paste an image' \
  'close it, then paste again' \
  "open Noctalia's clipboard history"; do
  grep -Fq "$step" "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
    fail "first-session clipboard plan omits: $step"
done
pass 'wl-clipboard supplies CLI copy/paste while Noctalia owns history and closed-source persistence'

awk -F '\t' '
  $1 == "openssh-clients" && $3 == "ssh,scp,sftp,ssh-keygen,ssh-copy-id,ssh-add" { client=1 }
  $1 == "openssh-server" { server=1 }
  END { exit !(client && !server) }
' "$DNF" || fail 'OpenSSH client-only policy differs from the authoritative package row'
pass 'OpenSSH client tools are selected while inbound sshd remains absent'

! awk -F '\t' '$1 == "tailscale" { found=1 } END { exit !found }' "$DNF" ||
  fail 'Tailscale was duplicated into the Fedora manifest'
awk -F '\t' '
  $1 == "tailscale" && $3 == "official-vendor-repository" &&
  $4 == "https://pkgs.tailscale.com/stable/fedora/tailscale.repo" &&
  $5 == "tailscale,tailscaled" && $7 == "system:tailscaled.service" &&
  $8 == "sudo dnf upgrade --from-repo=tailscale-stable tailscale" { found=1 }
  END { exit !found }
' "$EXTERNAL" || fail 'Tailscale vendor source commands or unit are incomplete'
pass 'Tailscale has one stable vendor-repository source row'

for runbook in CLEAN-INSTALL.md REMOTE-ACCESS.md; do
  grep -Fq 'sudo dnf config-manager addrepo' "$REPO_DIR/bootstrap/fedora/$runbook" ||
    fail "$runbook does not use the DNF5 addrepo command"
  grep -Fq -- '--from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo' \
    "$REPO_DIR/bootstrap/fedora/$runbook" || fail "$runbook lacks the DNF5 repository-file option"
  grep -Fq 'sudo dnf install --from-repo=tailscale-stable tailscale' \
    "$REPO_DIR/bootstrap/fedora/$runbook" || fail "$runbook does not constrain the duplicate package name to the vendor repository"
done
legacy_dnf_repo_flag='--add-''repo'
! rg -n -- "$legacy_dnf_repo_flag" "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" \
  "$REPO_DIR/bootstrap/fedora/REMOTE-ACCESS.md" || fail 'a Tailscale runbook retains DNF4 repository syntax'
pass 'both Tailscale runbooks use Fedora 44 DNF5 repository syntax'

if rg -n 'tailscale[[:space:]]+up|enable[[:space:]]+--now[[:space:]]+(sshd|tailscaled)|authorized_keys|/var/lib/tailscale' \
  "$REPO_DIR/install.sh" "$REPO_DIR/install-system.sh"; then
  fail 'an installer automates SSH/Tailscale activation authentication or state'
fi
pass 'installers do not activate SSH/Tailscale or manage private remote state'

while IFS= read -r -d '' path; do
  case "$path" in
  */.ssh/id_*|*/.ssh/*.pem|*/.ssh/known_hosts|*/.ssh/known_hosts.old|*/.ssh/authorized_keys|*/.ssh/config.local|*/.ssh/config.d/*|*/.ssh/control-*|*/tailscale/*|*/credentials.toml|*/settings.json|*/auth.json|*/cookies.sqlite|*/places.sqlite)
    fail "private identity or application-state path is tracked: $path"
    ;;
  esac
done < <(git -C "$REPO_DIR" ls-files -z)
if git -C "$REPO_DIR" grep -I -n -E -- '-----BEGIN ([A-Z0-9 ]+ )?PRIVATE KEY-----' >"$workspace/private-headers.log"; then
  cat "$workspace/private-headers.log" >&2
  fail 'private key material is tracked'
fi
[[ ! -d "$REPO_DIR/ssh" ]] || fail 'SSH Stow package unexpectedly owns machine identity'
pass 'SSH Pi Codex Noctalia browser and Tailscale private state remain untracked'

private_home="$workspace/private-home"
mkdir -p "$private_home/.ssh"
printf '%s\n' 'VERIFIER-MUST-NOT-PRINT-PRIVATE-CONTENT' >"$private_home/.ssh/id_ed25519"
chmod 700 "$private_home/.ssh"
chmod 600 "$private_home/.ssh/id_ed25519"
HOME="$private_home" "$REPO_DIR/bootstrap/fedora/verify.sh" --profile desktop >"$workspace/verifier.log" 2>&1 || true
! grep -Fq 'VERIFIER-MUST-NOT-PRINT-PRIVATE-CONTENT' "$workspace/verifier.log" ||
  fail 'Fedora verifier printed private SSH content'
pass 'Fedora verifier does not inspect private key contents'

mkdir -p "$workspace/bin"
cat >"$workspace/bin/fc-list" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'JetBrainsMono Nerd Font,JetBrainsMono NF'
EOF
chmod 0755 "$workspace/bin/fc-list"
PATH="$workspace/bin:$PATH" HOME="$private_home" "$REPO_DIR/bootstrap/fedora/verify.sh" --profile desktop \
  >"$workspace/font-verifier.log" 2>&1 || true
grep -Eq '^PRESENT[[:space:]]+font.*JetBrainsMono Nerd Font' "$workspace/font-verifier.log" ||
  fail 'Fedora verifier does not detect the exact configured font family'
pass 'Fedora verifier derives the required font family from its external source row'

for index in $(seq 1 20); do
  grep -Eq "^## ${index}\\. " "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
    fail "clean-install sequence lacks ordered step $index"
done
pass 'clean-install runbook retains the ordered 20-step release sequence'

clean_guide="$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md"
[[ ! -e "$REPO_DIR/bootstrap/fedora/LAPTOP-SETUP.md" ]] ||
  fail 'a duplicated laptop runbook remains beside the canonical clean-install guide'
for requirement in \
  'profile=desktop' \
  'profile=laptop' \
  '### Desktop only' \
  '### Laptop only' \
  'git@github.com:snaldos/naldo-dots.git' \
  'git@github.com:snaldos/state-space.git' \
  'git@github.com:snaldos/Wallpapers.git' \
  'WALLPAPERS_REQUIRED_MOUNT=' \
  'gcr-ssh-agent.socket' \
  'lfs install --local' \
  'sync-all dotfiles' \
  'sync-control enable'; do
  grep -Fq "$requirement" "$clean_guide" || fail "unified clean-install guide omits: $requirement"
done
python3 - "$clean_guide" <<'PY'
from pathlib import Path
import sys

lines = Path(sys.argv[1]).read_text().splitlines()
sections: list[tuple[str, str]] = []
heading = ""
body: list[str] = []
for line in lines:
    if line.startswith("### "):
        if heading:
            sections.append((heading, "\n".join(body)))
        heading, body = line, []
    elif line.startswith("## "):
        if heading:
            sections.append((heading, "\n".join(body)))
        heading, body = "", []
    elif heading:
        body.append(line)
if heading:
    sections.append((heading, "\n".join(body)))

laptop = "\n".join(body for heading, body in sections if heading.startswith("### Laptop"))
assert laptop
assert "akmod-nvidia" not in laptop
assert "xorg-x11-drv-nvidia" not in laptop
assert "/mnt/data" not in laptop
PY
pass 'one clean-install guide contains isolated desktop and laptop branches without a duplicated runbook'

# The Bash version variable belongs literally to the documented command.
# shellcheck disable=SC2016
[[ "$(grep -Fc 'test -n "$BASH_VERSION"' "$clean_guide")" -ge 4 ]] ||
  fail 'clean-install guide does not verify Bash in every new login shell'
grep -Fq './deploy-links.sh --dry-run' "$clean_guide" ||
  fail 'clean-install guide does not preflight Stow deployment'
grep -Fq 'stow_conflict=.config/helix/config.toml' "$clean_guide" ||
  fail 'clean-install guide does not show targeted conflict preservation'
grep -Fq 'command -v tsserver' "$clean_guide" ||
  fail 'clean-install guide does not check tsserver without launching it'
! grep -Eq '^[[:space:]]*tsserver([[:space:]]|$)' "$clean_guide" ||
  fail 'clean-install guide launches the long-running tsserver protocol process'
pass 'clean install enters Bash explicitly, preserves only Stow conflicts, and checks tsserver safely'

for scope in 'reusable, human-run Fedora clean-install guide' 'later clean installations' \
  'not a snapshot of every installed package' 'record of transitive' \
  'system-changing commands remain explicit steps for a human'; do
  grep -Fq "$scope" "$REPO_DIR/bootstrap/fedora/README.md" ||
    fail "Fedora bootstrap scope omits: $scope"
done
removal_pattern='will be remo''ved|scheduled for remo''val'
! rg -n "$removal_pattern" "$REPO_DIR/README.md" "$REPO_DIR/bootstrap/fedora/README.md" >/dev/null ||
  fail 'reusable Fedora guide still has removal language'
! grep -Fq '## Canonical maintenance' "$REPO_DIR/bootstrap/fedora/README.md" ||
  fail 'normal maintenance guidance moved back into the clean-install guide'
pass 'Fedora bootstrap remains a reusable curated guide with human-controlled changes'

awk -F '\t' '$1 == "keyd" && $3 == "reviewed-community-copr" && $4 ~ /alternateved\/keyd/ && $7 == "system:keyd.service" { found=1 } END { exit !found }' \
  "$EXTERNAL" || fail 'keyd source and unit are not authoritative in one COPR row'
! rg -n 'tailscale|ssh-key|authorized_keys|fstab|mount[[:space:]]|nvidia|firewall' "$REPO_DIR/install-system.sh" ||
  fail 'system installer expanded outside keyd/Noctalia input integration'
pass 'system installer remains within the audited keyd integration boundary'

while IFS=$'\t' read -r tool classification source_class preferred_source executables desktops units update uninstall purpose profile; do
  [[ -n "$tool" && "$tool" != \#* ]] || continue
  [[ -n "$classification" && -n "$source_class" && -n "$preferred_source" &&
    -n "$executables" && -n "$desktops" && -n "$units" && -n "$update" && -n "$uninstall" &&
    -n "$purpose" && -n "$profile" ]] || fail "external source row is incomplete: $tool"
done <"$EXTERNAL"
pass 'every external source has trust install-output update and uninstall metadata once'

for configured_tool in starship herdr; do
  awk -F '\t' -v tool="$configured_tool" '$1 == tool && $2 == "feature" { found=1 } END { exit !found }' \
    "$EXTERNAL" || fail "$configured_tool is configured but not required"
done
for spec in 'lazygit dejan/lazygit' 'starship atim/starship'; do
  read -r tool copr <<<"$spec"
  awk -F '\t' -v tool="$tool" -v copr="$copr" '
    $1 == tool && $2 == "feature" && $3 == "upstream-documented-third-party-copr" &&
    index($4, copr) && $8 == "sudo dnf upgrade " tool && $9 == "sudo dnf remove " tool { found=1 }
    END { exit !found }
  ' "$EXTERNAL" || fail "$tool does not use its upstream-documented third-party COPR with DNF ownership"
done
for command in \
  'sudo dnf copr enable dejan/lazygit' \
  'sudo dnf copr enable atim/starship' \
  'sudo dnf install lazygit starship'; do
  grep -Fq "$command" "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
    fail "clean-install provider commands omit: $command"
done
awk -F '\t' '
  $1 == "herdr" && $2 == "feature" && $3 == "official-upstream-installer" &&
  $4 == "https://herdr.dev/install.sh" && $8 == "herdr update" { found=1 }
  END { exit !found }
' "$EXTERNAL" || fail 'Herdr does not use its official stable self-managed installer route'
# The profile variable belongs to the documented command and must remain literal.
# shellcheck disable=SC2016
dotfiles_install_line="$(grep -n -m1 -F './install.sh --profile "$profile"' "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" | cut -d: -f1)"
herdr_integration_line="$(grep -n -m1 -F 'herdr integration install pi' "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" | cut -d: -f1)"
[[ -n "$dotfiles_install_line" && -n "$herdr_integration_line" &&
  "$herdr_integration_line" -gt "$dotfiles_install_line" ]] ||
  fail 'Herdr Pi integration is not materialized after dotfile deployment'
pass 'Herdr Pi integration remains machine-local and is installed after deployment'
awk -F '\t' '
  $1 == "pixi" && $2 == "feature" && $3 == "official-upstream-installer" &&
  $4 == "https://pixi.sh/install.sh" && $8 ~ /pixi self-update/ { found=1 }
  END { exit !found }
' "$EXTERNAL" || fail 'Pixi is not a selected official-installer feature'
awk -F '\t' '
  $1 == "tuicr" && $2 == "feature" && $3 == "official-upstream-installer" &&
  $4 == "https://tuicr.dev/install.sh" && $5 == "tuicr" && $8 == "tuicr update" { found=1 }
  END { exit !found }
' "$EXTERNAL" || fail 'Tuicr is not a receipt-owned official-installer feature'
awk -F '\t' '
  $1 == "code" && $2 == "feature" && $3 == "official-vendor-repository" &&
  $4 == "https://packages.microsoft.com/yumrepos/vscode" && $5 == "code" &&
  $6 == "application:code.desktop" { found=1 }
  END { exit !found }
' "$EXTERNAL" || fail 'VS Code is not owned by Microsoft signed RPM policy'
for extension in ms-python.python ms-toolsai.jupyter charliermarsh.ruff; do
  awk -F '\t' -v extension="$extension" '
    $1 == extension && $2 == "feature" && $3 == "official-vscode-extension" { found=1 }
    END { exit !found }
  ' "$EXTERNAL" || fail "selected VS Code extension is absent: $extension"
done
awk -F '\t' '
  $1 == "gh-dash" && $2 == "feature" && $3 == "reviewed-gh-extension" &&
  $4 == "https://github.com/dlvhdr/gh-dash" { found=1 }
  END { exit !found }
' "$EXTERNAL" || fail 'gh-dash is not a reviewed gh-managed extension'
# Literal source assertions; these variables belong to the documented commands.
# shellcheck disable=SC2016
for command in \
  'gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web' \
  'gh extension install dlvhdr/gh-dash' \
  'code --install-extension "$extension"' \
  'TUICR_VERSION="$tuicr_version" TUICR_INSTALL_YES=1 sh "$tuicr_work/install.sh"'; do
  grep -Fq "$command" "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
    fail "clean-install guide omits selected tool command: $command"
done
# shellcheck disable=SC2016
grep -Fq '"$HOME/.pixi/bin"' "$REPO_DIR/fish/.config/fish/config.fish" ||
  fail 'Fish PATH does not include the selected official Pixi installation directory'
# shellcheck disable=SC2016
grep -Fq 'PIXI_NO_PATH_UPDATE=1 sh "$pixi_installer"' "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
  fail 'clean-install guide does not keep Pixi shell changes under tracked Fish ownership'
for wording in \
  'upstream-documented third-party COPRs' \
  'COPR is not an official Fedora package source' \
  'herdr-official-installer' \
  'Do not introduce mise or a generic GitHub binary updater'; do
  grep -Fq "$wording" "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
    fail "clean-install provider policy omits: $wording"
done
awk -F '\t' '$1 == "JetBrainsMono Nerd Font" && $2 == "feature" && $3 == "official-upstream-release" && $4 ~ /v3[.]5[.]0$/ && $NF == "all" { found=1 } END { exit !found }' \
  "$EXTERNAL" || fail 'Ghostty font source does not use the exact shared Nerd Fonts family identity'
awk -F '\t' '$1 == "nvidia-driver-desktop" && $2 == "feature" && $NF == "desktop" { found=1 } END { exit !found }' \
  "$EXTERNAL" || fail 'selected NVIDIA feature is not restricted to the desktop profile'
grep -Fq 'font-family = JetBrainsMono Nerd Font' "$REPO_DIR/ghostty/.config/ghostty/config.ghostty" ||
  fail 'Ghostty does not request the exact manifest font family'
pass 'configured prompt editors review tools font and desktop NVIDIA dependencies remain required'

for removed in commands.tsv desktop-files.tsv services.tsv dnf-packages.txt APPLICATIONS.md DEPENDENCIES.md; do
  [[ ! -e "$REPO_DIR/bootstrap/fedora/$removed" ]] || fail "duplicated bootstrap source remains: $removed"
done
pass 'bootstrap verifier derives expectations from installation-source manifests'

printf '1..%d\n' "$checks"
