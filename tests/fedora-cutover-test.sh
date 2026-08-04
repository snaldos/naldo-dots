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

for package in openssh-clients openssh-server nodejs22 nodejs22-npm rust cargo gcc gcc-c++ make cmake pkgconf-pkg-config fontconfig evtest; do
  [[ "$(awk -F '\t' -v package="$package" '$1 == package { count++ } END { print count+0 }' "$DNF")" == 1 ]] ||
    fail "missing exact Fedora package: $package"
done
for obsolete in npm nodejs nodejs-npm typst ruff celluloid; do
  ! awk -F '\t' -v package="$obsolete" '$1 == package { found=1 } END { exit !found }' "$DNF" ||
    fail "non-selected DNF provider remains: $obsolete"
done
pass 'Fedora manifest uses exact selected OpenSSH npm Rust build and Bongo Cat packages'

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
  $1 == "openssh-server" && $3 == "sshd" && $5 == "system:sshd.service" { server=1 }
  END { exit !(client && server) }
' "$DNF" || fail 'OpenSSH outputs are not authoritative in their package rows'
pass 'OpenSSH clients server command and unit derive from their DNF rows'

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
awk -F '\t' '
  $1 == "pixi" && $2 == "development" && $3 == "official-upstream-installer" &&
  $4 == "https://pixi.sh/install.sh" && $8 ~ /pixi self-update/ { found=1 }
  END { exit !found }
' "$EXTERNAL" || fail 'Pixi is not a development-only conditional official-installer tool'
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
pass 'configured prompt session font and desktop NVIDIA dependencies remain required'

for removed in commands.tsv desktop-files.tsv services.tsv dnf-packages.txt APPLICATIONS.md DEPENDENCIES.md; do
  [[ ! -e "$REPO_DIR/bootstrap/fedora/$removed" ]] || fail "duplicated bootstrap source remains: $removed"
done
pass 'bootstrap verifier derives expectations from installation-source manifests'

printf '1..%d\n' "$checks"
