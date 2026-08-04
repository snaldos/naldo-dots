#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
checks=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$*"
}

operational_paths=(
  "$REPO_DIR/install.sh" "$REPO_DIR/deploy-links.sh" "$REPO_DIR/sync.sh"
  "$REPO_DIR/automation" "$REPO_DIR/desktop" "$REPO_DIR/niri/.config/niri/scripts"
  "$REPO_DIR/ghostty/.config/ghostty" "$REPO_DIR/noctalia/.config/noctalia/hooks"
)
legacy_manager_pattern='pac'"man|pa"'ru|ya'"y|ref"'lector'
if grep -RInE --exclude='naldo-update' \
  "(^|[;&|()[:space:]])(sudo[[:space:]]+)?($legacy_manager_pattern|dnf)[[:space:]]|flatpak[[:space:]]+(install|update|upgrade|uninstall)" \
  "${operational_paths[@]}"; then
  fail 'operational user configuration contains hidden package or repository maintenance'
fi
[[ -x "$REPO_DIR/automation/.local/bin/naldo-update" ]] ||
  fail 'the explicit manual update command is missing from the automation package'
pass 'package maintenance is isolated to the explicit naldo-update command'

mapfile -t tasks < <("$REPO_DIR/automation/.local/bin/sync-all" --list-tasks)
[[ "${tasks[*]}" == 'dotfiles notes wallpapers' ]] || fail "unexpected sync tasks: ${tasks[*]}"
for key in dotfiles_enabled dotfiles_path notes_enabled notes_path wallpapers_enabled wallpapers_path WALLPAPERS_REQUIRED_MOUNT; do
  grep -Eq "^${key}=" "$REPO_DIR/automation/.config/naldo/sync/repositories.conf.example" ||
    fail "sync template lacks $key"
done
! rg -n -i 'snapshot|package inventory|/etc backup' "$REPO_DIR/automation" "$REPO_DIR/sync.sh" >/dev/null ||
  fail 'synchronization regained a system-backup responsibility'
pass 'synchronization exposes exactly dotfiles notes and wallpapers'

legacy_hx_helper='ensure-'"hx-command"
legacy_editor_command='heli'"x"
legacy_runtime_pattern='pac'"man|pa"'ru|\\bya'"y\\b|\\bAU"'R\\b|ref'"lector|mirror"'list|mkin'"itcpio"
[[ ! -e "$REPO_DIR/automation/.local/libexec/naldo/$legacy_hx_helper" ]] || fail 'obsolete hx helper remains'
if rg -n -i "$legacy_runtime_pattern|$legacy_hx_helper|command[[:space:]]+-v[[:space:]]+$legacy_editor_command|exec[[:space:]]+$legacy_editor_command" \
  "${operational_paths[@]}"; then
  fail 'active compatibility or legacy-distribution behavior remains'
fi
! rg -n '/etc/os-release|ID_LIKE|\bID=fedora\b|\bID=arch\b' "${operational_paths[@]}" >/dev/null ||
  fail 'unused runtime distribution detection remains'
pass 'runtime has one Fedora-era command contract without distribution branches'

for obsolete_launcher in \
  "$REPO_DIR/desktop/.local/bin/launch-zen" \
  "$REPO_DIR/desktop/.local/libexec/naldo/launch-terminal" \
  "$REPO_DIR/niri/.config/niri/scripts/app_launcher.sh"; do
  [[ ! -e "$obsolete_launcher" ]] || fail "obsolete launcher remains: ${obsolete_launcher#"$REPO_DIR/"}"
done
keybindings="$REPO_DIR/niri/.config/niri/conf.d/keybindings.kdl"
grep -Fq 'Mod+T hotkey-overlay-title="Open a Terminal: Ghostty" {' "$keybindings" ||
  fail 'Mod+T is not the direct Ghostty binding'
grep -Fq '        spawn "ghostty"' "$keybindings" || fail 'Mod+T does not spawn ordinary Ghostty'
grep -Fq 'Mod+Z hotkey-overlay-title="Open a Browser: Zen" {' "$keybindings" ||
  fail 'Mod+Z is not the direct Zen binding'
grep -Fq 'spawn "flatpak" "run" "app.zen_browser.zen" "--new-window" "about:newtab"' "$keybindings" ||
  fail 'Mod+Z does not directly request a new Zen window'
zen_rules="$REPO_DIR/niri/.config/niri/conf.d/rules.kdl"
! grep -Fq 'app.zen_browser.zen' "$zen_rules" || fail 'Zen retains a static Niri window rule'
! rg -n 'com[.]mitchellh[.]ghostty[.]float|ZEN_FLOAT|app_launcher|launch-terminal' \
  "$REPO_DIR/niri" "$REPO_DIR/desktop" >/dev/null ||
  fail 'obsolete Ghostty/Zen floating launcher machinery remains'
scripts_menu="$REPO_DIR/desktop/.local/bin/naldo-scripts-menu"
# The variables belong to the scripts-menu source and must remain literal here.
# shellcheck disable=SC2016
grep -Fq '"$TERMINAL" --wait-after-command -e "$@" &' "$scripts_menu" ||
  fail 'scripts menu does not use an ordinary terminal window'
grep -Fq '󰚰 System maintenance' "$scripts_menu" ||
  fail 'scripts menu does not expose system maintenance'
# The updater variable belongs literally to the scripts-menu source.
# shellcheck disable=SC2016
grep -Fq 'run_terminal "$NALDO_UPDATE"' "$scripts_menu" ||
  fail 'scripts menu does not run naldo-update in a reviewable terminal'
grep -Fq 'match app-id=r#"^app\.zen_browser\.zen$"#' "$REPO_DIR/niri/.config/niri/scripts/theme_launcher.sh" ||
  fail 'Zen opacity rule does not match the live app ID'
while IFS= read -r -d '' script; do
  substantive="$(awk '!/^[[:space:]]*(#|$)/ { count++ } END { print count+0 }' "$script")"
  if ((substantive < 25)) && rg -q '^[[:space:]]*exec[[:space:]]' "$script"; then
    fail "fixed-command forwarding wrapper remains: ${script#"$REPO_DIR/"}"
  fi
done < <(find "$REPO_DIR" -path "$REPO_DIR/.git" -prune -o -type f -perm /111 -print0)
pass 'Mod+T and Mod+Z open ordinary tiled windows without floating identities or wrappers'

# The Home variable belongs literally to the Herdr configuration assertion.
# shellcheck disable=SC2016
for assertion in \
  'fish/.config/fish/config.fish:set -gx EDITOR hx' \
  'fish/.config/fish/config.fish:set -gx VISUAL hx' \
  'git/.config/git/naldo.conf:editor = hx' \
  'lazygit/.config/lazygit/config.yml:editPreset: "helix (hx)"' \
  'yazi/.config/yazi/yazi.toml:run = "hx -- %s"' \
  'herdr/.config/herdr/config.toml:command = "$HOME/.config/herdr/scripts/popup-launcher"' \
  'herdr/.config/herdr/scripts/popup-launcher:exec hx /tmp/helix-scratchpad.typ' \
  'pi/.pi/agent/settings.default.json:"externalEditor": "hx"'; do
  file="${assertion%%:*}"
  text="${assertion#*:}"
  grep -Fq "$text" "$REPO_DIR/$file" || fail "$file does not select hx"
done
pass 'all committed editor consumers select hx'

for forbidden in settings.json auth.json trust.json agent.db sessions git npm bin logs packages credentials; do
  [[ ! -e "$REPO_DIR/pi/.pi/agent/$forbidden" ]] || fail "Pi runtime state exists in source: $forbidden"
done
mapfile -d '' ignored_pi_state < <(git -C "$REPO_DIR" ls-files --others --ignored --exclude-standard -z -- pi)
((${#ignored_pi_state[@]} == 0)) || fail 'ignored Pi runtime state exists in package source'
pass 'Pi authentication sessions databases logs and packages remain outside source'

for directory in assets bootstrap system tests; do
  grep -Fq "$directory" "$REPO_DIR/deploy-links.sh" || fail "non-Stow directory is undeclared: $directory"
done
[[ ! -e "$REPO_DIR/machine" ]] || fail 'unused machine-profile Stow package remains'
! rg -n -- '--non-interactive|machine-profile|profile override|tracked default' \
  "$REPO_DIR/install.sh" "$REPO_DIR/deploy-links.sh" >/dev/null ||
  fail 'unused profile indirection remains in deployment'
pass 'deployment keeps one explicit Niri selector without profile branches or packages'

! grep -Eq '(^|[^[:alnum:]_])sudo([[:space:]]|$)' "$REPO_DIR/install.sh" || fail 'install.sh contains sudo'
! grep -Eq '(^|[;&|()[:space:]])(dnf|flatpak|rpm|copr|curl|wget)[[:space:]]' "$REPO_DIR/install.sh" ||
  fail 'install.sh contains provisioning'
legacy_initramfs_command='mkini'"tcpio"
! rg -n "sshd|tailscale|fstab|mount[[:space:]]|firewall|nvidia|bootctl|grub|$legacy_initramfs_command" \
  "$REPO_DIR/install.sh" "$REPO_DIR/install-system.sh" ||
  fail 'an installer crossed a forbidden system boundary'
for system_path in /etc/keyd/default.conf /etc/udev/rules.d/69-keyd-bongocat.rules; do
  grep -Fq "$system_path" "$REPO_DIR/install-system.sh" || fail "system destination missing: $system_path"
done
pass 'installer boundaries are user-only plus the two reviewed keyd system files'

obsolete_repo_word='back'"ups"
obsolete_repo_variable='SYSTEM_BACK'"UP_REPO"
obsolete_login_pattern='gree'"td|noctalia-gree"'ter'
if rg -n -i --hidden --glob '!.git/**' --glob '!assets/**' --glob '!tests/repository-policy-test.sh' \
  "$obsolete_repo_word|$obsolete_repo_variable|$obsolete_login_pattern|systemd-boot|migration-only" "$REPO_DIR"; then
  fail 'discarded repository login boot or migration architecture remains documented'
fi
pass 'tree contains no old backup repository alternate greeter or discarded architecture'

python3 - "$REPO_DIR" <<'PY'
from pathlib import Path
import csv
import sys
root = Path(sys.argv[1])
b = root / "bootstrap/fedora"

def rows(name, columns):
    with (b / name).open(newline="") as handle:
        result = [r for r in csv.reader(handle, delimiter="\t") if r and r[0] and not r[0].startswith("#")]
    assert all(len(r) == columns for r in result), name
    ids = [r[0] for r in result]
    assert len(ids) == len(set(ids)), f"duplicate IDs in {name}"
    return result

def add(values, owner, inventory):
    if values == "-": return
    for value in values.split(","):
        key = value.split(":", 1)[-1] if inventory is not commands else value
        assert key not in inventory, f"duplicate output {key}: {inventory.get(key)} and {owner}"
        inventory[key] = owner

commands, desktops, units = {}, {}, {}
for r in rows("dnf-packages.tsv", 7):
    add(r[2], f"dnf:{r[0]}", commands); add(r[3], f"dnf:{r[0]}", desktops); add(r[4], f"dnf:{r[0]}", units)
flatpak_commands = {}
for r in rows("flatpaks.tsv", 7):
    add("application:" + r[3], f"flatpak:{r[0]}", desktops)
    add(r[4], f"flatpak:{r[0]}", flatpak_commands)
for r in rows("npm-packages.tsv", 5): add(r[1], f"npm:{r[0]}", commands)
for r in rows("uv-tools.tsv", 6): add(r[1], f"uv:{r[0]}", commands)
for r in rows("cargo-tools.tsv", 9): add(r[1], f"cargo:{r[0]}", commands)
for r in rows("external-tools.tsv", 11):
    add(r[4], f"external:{r[0]}", commands); add(r[5], f"external:{r[0]}", desktops); add(r[6], f"external:{r[0]}", units)
for path in (root / "desktop/.local/share/applications").glob("*.desktop"):
    assert path.name not in desktops, f"duplicate local desktop {path.name}"
    desktops[path.name] = "dotfiles:desktop"
for path in (root / "automation/.config/systemd/user").glob("*.service"):
    assert path.name not in units, f"duplicate local unit {path.name}"
    units[path.name] = "dotfiles:automation"
for path in (root / "automation/.config/systemd/user").glob("*.timer"):
    assert path.name not in units, f"duplicate local unit {path.name}"
    units[path.name] = "dotfiles:automation"
PY
pass 'each package tool command Flatpak integration desktop file and unit has one authoritative entry'

printf '1..%d\n' "$checks"
