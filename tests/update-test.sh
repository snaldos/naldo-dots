#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
UPDATER="$REPO_DIR/automation/.local/bin/naldo-update"
MAINTENANCE="$REPO_DIR/MAINTENANCE.md"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/naldo-update-test.XXXXXX")"
fake_bin="$workspace/bin"
checks=0
installer_home="$workspace/home"
installer_data="$workspace/data"
installer_bin="$installer_home/.local/bin"
pixi_bin="$installer_home/.pixi/bin"
font_dir="$installer_home/.local/share/fonts/JetBrainsMonoNerdFont"
herdr_receipt="$installer_data/naldo/provider-receipts/herdr-official-installer"
tuicr_receipt="$installer_data/naldo/provider-receipts/tuicr-official-installer"
mkdir -p "$fake_bin" "$workspace/away" "$workspace/empty-bin" "$installer_bin" \
  "$pixi_bin" "$font_dir" "${herdr_receipt%/*}"
trap 'rm -rf -- "$workspace"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$*"
}

[[ -x "$UPDATER" ]] || fail 'naldo-update is not an executable in the automation Stow package'
! rg -n 'bootstrap|cargo-tools[.]tsv|external-tools[.]tsv' "$UPDATER" >/dev/null ||
  fail 'naldo-update depends on the clean-install inventory'
cp "$UPDATER" "$workspace/naldo-update"
chmod 0755 "$workspace/naldo-update"
pass 'naldo-update is a standalone executable in the shared automation package'

for provider in sudo dnf flatpak uv cargo cargo-install-update; do
  cat >"$fake_bin/$provider" <<'EOF'
#!/bin/bash
name="${0##*/}"
printf '%s' "$name" >>"$NALDO_UPDATE_TEST_LOG"
printf ' %s' "$@" >>"$NALDO_UPDATE_TEST_LOG"
printf '\n' >>"$NALDO_UPDATE_TEST_LOG"
if [[ "${NALDO_UPDATE_FAIL:-}" == "$name" ]]; then
  exit "${NALDO_UPDATE_FAIL_STATUS:-23}"
fi
EOF
  chmod 0755 "$fake_bin/$provider"
done
ln -s /usr/bin/readlink "$fake_bin/readlink"
ln -s /usr/bin/mktemp "$fake_bin/mktemp"
ln -s /usr/bin/rm "$fake_bin/rm"
ln -s "$(command -v node)" "$fake_bin/node"
cat >"$fake_bin/npm" <<'EOF'
#!/bin/bash
case "$1 $2 $3 $4" in
"outdated --global --depth=0 --json")
  printf '%s\n' '{"prettier":{"current":"1","latest":"2"},"typescript":{"current":"6","latest":"7"}}'
  exit 1
  ;;
"list --global --depth=0 --json")
  [[ "$5" == typescript ]] && exit "${NALDO_UPDATE_TYPESCRIPT_STATUS:-0}"
  ;;
esac
printf 'npm' >>"$NALDO_UPDATE_TEST_LOG"
printf ' %s' "$@" >>"$NALDO_UPDATE_TEST_LOG"
printf '\n' >>"$NALDO_UPDATE_TEST_LOG"
[[ "${NALDO_UPDATE_FAIL:-}" != npm ]] || exit "${NALDO_UPDATE_FAIL_STATUS:-23}"
EOF
cat >"$fake_bin/gh" <<'EOF'
#!/bin/bash
if [[ "$1 $2" == "auth status" ]]; then
  exit "${NALDO_UPDATE_GH_AUTH_STATUS:-0}"
fi
if [[ "$1 $2" == "extension list" ]]; then
  [[ "${NALDO_UPDATE_GH_EMPTY:-0}" == 1 ]] || printf '%s\n' 'gh dash dlvhdr/gh-dash v4.25.2'
  exit 0
fi
printf 'gh' >>"$NALDO_UPDATE_TEST_LOG"
printf ' %s' "$@" >>"$NALDO_UPDATE_TEST_LOG"
printf '\n' >>"$NALDO_UPDATE_TEST_LOG"
[[ "${NALDO_UPDATE_FAIL:-}" != gh ]] || exit "${NALDO_UPDATE_FAIL_STATUS:-23}"
EOF
cat >"$fake_bin/curl" <<'EOF'
#!/bin/bash
url="${!#}"
repository="${url#https://github.com/}"
repository="${repository%/releases/latest}"
if [[ "${NALDO_UPDATE_RELEASE_CHECK_FAIL:-}" == "$repository" ]]; then
  exit 22
fi
case "$repository" in
artempyanykh/marksman) latest="${NALDO_UPDATE_MARKSMAN_LATEST:-2026-02-08}" ;;
Myriad-Dreamin/tinymist) latest="${NALDO_UPDATE_TINYMIST_LATEST:-v0.15.2}" ;;
Feel-ix-343/markdown-oxide) latest="${NALDO_UPDATE_MARKDOWN_OXIDE_LATEST:-v0.25.12}" ;;
ryanoasis/nerd-fonts) latest="${NALDO_UPDATE_NERD_FONTS_LATEST:-v3.5.0}" ;;
*) exit 22 ;;
esac
printf 'https://github.com/%s/releases/tag/%s' "$repository" "$latest"
EOF
chmod 0755 "$fake_bin/npm" "$fake_bin/gh" "$fake_bin/curl"
cat >"$installer_bin/tuicr" <<'EOF'
#!/bin/bash
printf 'tuicr' >>"$NALDO_UPDATE_TEST_LOG"
printf ' %s' "$@" >>"$NALDO_UPDATE_TEST_LOG"
printf '\n' >>"$NALDO_UPDATE_TEST_LOG"
[[ "${NALDO_UPDATE_FAIL:-}" != tuicr ]] || exit "${NALDO_UPDATE_FAIL_STATUS:-23}"
EOF
chmod 0755 "$installer_bin/tuicr"
cat >"$installer_bin/herdr" <<'EOF'
#!/bin/bash
if [[ "${1:-}" == channel && "${2:-}" == show ]]; then
  printf '%s\n' "${NALDO_UPDATE_HERDR_CHANNEL:-stable}"
  exit "${NALDO_UPDATE_HERDR_CHANNEL_STATUS:-0}"
fi
printf 'herdr' >>"$NALDO_UPDATE_TEST_LOG"
printf ' %s' "$@" >>"$NALDO_UPDATE_TEST_LOG"
printf '\n' >>"$NALDO_UPDATE_TEST_LOG"
if [[ "${NALDO_UPDATE_FAIL:-}" == herdr ]]; then
  exit "${NALDO_UPDATE_FAIL_STATUS:-23}"
fi
EOF
chmod 0755 "$installer_bin/herdr"
cat >"$pixi_bin/pixi" <<'EOF'
#!/bin/bash
printf 'pixi' >>"$NALDO_UPDATE_TEST_LOG"
printf ' %s' "$@" >>"$NALDO_UPDATE_TEST_LOG"
printf '\n' >>"$NALDO_UPDATE_TEST_LOG"
[[ "${NALDO_UPDATE_FAIL:-}" != pixi ]] || exit "${NALDO_UPDATE_FAIL_STATUS:-23}"
EOF
cat >"$installer_bin/marksman" <<'EOF'
#!/bin/bash
[[ "${1:-}" == --version ]] && printf '%s\n' '2026-02-08'
EOF
for command in tinymist markdown-oxide; do
  printf '%s\n' '#!/bin/bash' 'exit 0' >"$fake_bin/$command"
done
chmod 0755 "$pixi_bin/pixi" "$installer_bin/marksman" \
  "$fake_bin/tinymist" "$fake_bin/markdown-oxide"
printf 'source=https://herdr.dev/install.sh\nbinary=%s\n' \
  "$(readlink -f "$installer_bin/herdr")" >"$herdr_receipt"
printf 'source=https://tuicr.dev/install.sh\nbinary=%s\n' \
  "$(readlink -f "$installer_bin/tuicr")" >"$tuicr_receipt"
chmod 0600 "$herdr_receipt" "$tuicr_receipt"
provider_path="$installer_bin:$pixi_bin:$fake_bin"

: >"$workspace/providers.log"
(
  cd "$workspace/away"
  HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
    NALDO_UPDATE_TEST_LOG="$workspace/providers.log" \
    /bin/bash "$workspace/naldo-update" >"$workspace/providers.out"
)
cat >"$workspace/providers.expected" <<'EOF'
sudo dnf upgrade --refresh
flatpak update --user
gh extension upgrade --all
npm update --global prettier
npm install --global typescript@6
uv tool upgrade --all
cargo install-update -a
pixi self-update --no-config
tuicr update
herdr update
EOF
diff -u "$workspace/providers.expected" "$workspace/providers.log" ||
  fail 'update providers did not run once in the required order'
for label in 'DNF packages' 'Flatpak applications' 'GitHub CLI extensions' 'global npm packages' \
  'uv tools' 'Cargo registry binaries' 'Pixi official installer' \
  'Manual release report' 'Tuicr official installer' 'Herdr official installer'; do
  grep -Fq "== $label ==" "$workspace/providers.out" || fail "missing provider section: $label"
done
grep -Fq 'protocol-changing update may require restarting the active Herdr session' "$workspace/providers.out" ||
  fail 'Herdr update did not warn about an active-session protocol change'
for report in \
  'CURRENT (manual): Marksman 2026-02-08' \
  'CURRENT (manual): Tinymist tagged source v0.15.2' \
  'CURRENT (manual): Markdown Oxide tagged source v0.25.12' \
  'CURRENT (manual): JetBrainsMono Nerd Font v3.5.0'; do
  grep -Fq "$report" "$workspace/providers.out" || fail "missing manual release report: $report"
done
pass 'available providers run once and manual GitHub releases report in the required order'

: >"$workspace/constrained.log"
HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
  NALDO_UPDATE_TEST_LOG="$workspace/constrained.log" NALDO_UPDATE_TYPESCRIPT_STATUS=1 \
  /bin/bash "$workspace/naldo-update" >"$workspace/constrained.out"
grep -Fv 'npm install --global typescript@6' "$workspace/providers.expected" >"$workspace/constrained.expected"
diff -u "$workspace/constrained.expected" "$workspace/constrained.log" ||
  fail 'absent TypeScript was installed by the compatibility update'

rm -f -- "$tuicr_receipt"
: >"$workspace/no-tuicr.log"
HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
  NALDO_UPDATE_TEST_LOG="$workspace/no-tuicr.log" \
  /bin/bash "$workspace/naldo-update" >"$workspace/no-tuicr.out"
grep -Fv 'tuicr update' "$workspace/providers.expected" >"$workspace/no-tuicr.expected"
diff -u "$workspace/no-tuicr.expected" "$workspace/no-tuicr.log" ||
  fail 'Tuicr ran without an official-installer receipt'
grep -Fq 'official-installer-managed Tuicr is unavailable' "$workspace/no-tuicr.out" ||
  fail 'missing Tuicr receipt was not explained'
printf 'source=https://tuicr.dev/install.sh\nbinary=%s\n' \
  "$(readlink -f "$installer_bin/tuicr")" >"$tuicr_receipt"
chmod 0600 "$tuicr_receipt"
pass 'constrained TypeScript and receipt-owned Tuicr updates cannot install missing providers'

: >"$workspace/manual-report.log"
HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
  NALDO_UPDATE_TEST_LOG="$workspace/manual-report.log" \
  NALDO_UPDATE_MARKSMAN_LATEST=2026-03-01 \
  NALDO_UPDATE_RELEASE_CHECK_FAIL=Feel-ix-343/markdown-oxide \
  /bin/bash "$workspace/naldo-update" >"$workspace/manual-report.out"
diff -u "$workspace/providers.expected" "$workspace/manual-report.log" ||
  fail 'read-only manual release reporting changed the update provider sequence'
grep -Fq 'MANUAL UPDATE AVAILABLE: Marksman selected=2026-02-08 latest=2026-03-01' \
  "$workspace/manual-report.out" || fail 'newer Marksman release was not reported'
grep -Fq 'CHECK FAILED: Markdown Oxide tagged source' "$workspace/manual-report.out" ||
  fail 'failed manual release query was not reported without aborting updates'
pass 'manual release checks distinguish current available and failed reports without mutation'

: >"$workspace/skipped.log"
PATH="$workspace/empty-bin" NALDO_UPDATE_TEST_LOG="$workspace/skipped.log" \
  /bin/bash "$workspace/naldo-update" >"$workspace/skipped.out"
[[ ! -s "$workspace/skipped.log" ]] || fail 'an unavailable provider was executed'
[[ "$(grep -c '^SKIP:' "$workspace/skipped.out")" == 10 ]] ||
  fail 'unavailable providers were not all reported clearly'
pass 'unavailable providers are reported and skipped'

: >"$workspace/failure.log"
set +e
PATH="$fake_bin" NALDO_UPDATE_TEST_LOG="$workspace/failure.log" \
  NALDO_UPDATE_FAIL=flatpak NALDO_UPDATE_FAIL_STATUS=23 \
  /bin/bash "$workspace/naldo-update" >"$workspace/failure.out" 2>&1
failure_status=$?
set -e
[[ "$failure_status" == 23 ]] || fail "provider failure became status $failure_status instead of 23"
cat >"$workspace/failure.expected" <<'EOF'
sudo dnf upgrade --refresh
flatpak update --user
EOF
diff -u "$workspace/failure.expected" "$workspace/failure.log" ||
  fail 'updates continued after a provider failed'
pass 'provider failures propagate immediately without running later providers'

: >"$workspace/pixi-failure.log"
set +e
HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
  NALDO_UPDATE_TEST_LOG="$workspace/pixi-failure.log" \
  NALDO_UPDATE_FAIL=pixi NALDO_UPDATE_FAIL_STATUS=31 \
  /bin/bash "$workspace/naldo-update" >"$workspace/pixi-failure.out" 2>&1
pixi_failure_status=$?
set -e
[[ "$pixi_failure_status" == 31 ]] ||
  fail "Pixi failure became status $pixi_failure_status instead of 31"
head -n 8 "$workspace/providers.expected" >"$workspace/pixi-failure.expected"
diff -u "$workspace/pixi-failure.expected" "$workspace/pixi-failure.log" ||
  fail 'Pixi self-update failure did not stop later providers'
pass 'official-installer-managed Pixi self-update propagates failure'

grep -Fv 'herdr update' "$workspace/providers.expected" >"$workspace/no-herdr.expected"
rm -f -- "$herdr_receipt"
: >"$workspace/no-receipt.log"
HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
  NALDO_UPDATE_TEST_LOG="$workspace/no-receipt.log" \
  /bin/bash "$workspace/naldo-update" >"$workspace/no-receipt.out"
diff -u "$workspace/no-herdr.expected" "$workspace/no-receipt.log" ||
  fail 'Herdr ran without an official-installer receipt'
grep -Fq 'official-installer-managed Herdr is unavailable' "$workspace/no-receipt.out" ||
  fail 'missing Herdr receipt was not explained'

printf 'source=https://example.invalid/install.sh\nbinary=%s\n' \
  "$(readlink -f "$installer_bin/herdr")" >"$herdr_receipt"
chmod 0600 "$herdr_receipt"
: >"$workspace/bad-receipt.log"
HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
  NALDO_UPDATE_TEST_LOG="$workspace/bad-receipt.log" \
  /bin/bash "$workspace/naldo-update" >"$workspace/bad-receipt.out"
diff -u "$workspace/no-herdr.expected" "$workspace/bad-receipt.log" ||
  fail 'Herdr ran with a mismatched installer receipt'
grep -Fq 'does not have a valid official-installer receipt' "$workspace/bad-receipt.out" ||
  fail 'mismatched Herdr receipt was not explained'

printf 'source=https://herdr.dev/install.sh\nbinary=%s\n' \
  "$(readlink -f "$installer_bin/herdr")" >"$herdr_receipt"
chmod 0600 "$herdr_receipt"
: >"$workspace/preview-channel.log"
HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
  NALDO_UPDATE_TEST_LOG="$workspace/preview-channel.log" NALDO_UPDATE_HERDR_CHANNEL=preview \
  /bin/bash "$workspace/naldo-update" >"$workspace/preview-channel.out"
diff -u "$workspace/no-herdr.expected" "$workspace/preview-channel.log" ||
  fail 'Herdr updated from an unselected non-stable channel'
grep -Fq 'preview channel, not the selected stable channel' "$workspace/preview-channel.out" ||
  fail 'non-stable Herdr channel was not explained'
pass 'Herdr runs only with a matching official-installer receipt and stable channel'

: >"$workspace/herdr-failure.log"
set +e
HOME="$installer_home" XDG_DATA_HOME="$installer_data" PATH="$provider_path" \
  NALDO_UPDATE_TEST_LOG="$workspace/herdr-failure.log" \
  NALDO_UPDATE_FAIL=herdr NALDO_UPDATE_FAIL_STATUS=29 \
  /bin/bash "$workspace/naldo-update" >"$workspace/herdr-failure.out" 2>&1
herdr_failure_status=$?
set -e
[[ "$herdr_failure_status" == 29 ]] ||
  fail "Herdr failure became status $herdr_failure_status instead of 29"
diff -u "$workspace/providers.expected" "$workspace/herdr-failure.log" ||
  fail 'conditional Herdr failure did not occur after all earlier providers'
pass 'installer-managed Herdr updates remain interactive and propagate failure'

for forbidden in '-y' --assumeyes autoremove '--git' sync-all sync-control systemctl service enable reboot; do
  ! grep -Fq -- "$forbidden" "$UPDATER" || fail "naldo-update contains forbidden behavior: $forbidden"
done
! grep -Eq 'dnf .*install|flatpak .*install|(^|[[:space:]])remove([[:space:]]|$)' "$UPDATER" ||
  fail 'naldo-update installs missing applications or removes software'
grep -Fq 'sudo dnf upgrade --refresh' "$UPDATER" ||
  fail 'naldo-update does not use the ordinary DNF RPM upgrade'
! grep -Fq -- '--exclude=code' "$UPDATER" ||
  fail 'naldo-update unnecessarily excludes the VS Code RPM from DNF upgrades'
! rg -n 'code --(list|update)-extensions' "$UPDATER" >/dev/null ||
  fail 'naldo-update still inspects or updates VS Code extensions'
grep -Fq 'npm list --global --depth=0 --json typescript' "$UPDATER" ||
  fail 'TypeScript major constraint is not guarded by installed-package presence'
[[ "$(grep -Fc "npm install --global 'typescript@6'" "$UPDATER")" == 1 ]] ||
  fail 'TypeScript compatibility update is absent or duplicated'
grep -Fq 'pixi self-update --no-config' "$UPDATER" ||
  fail 'official-installer-managed Pixi is not updated through its self-updater'
# The updater source intentionally retains its runtime repository variable.
# shellcheck disable=SC2016
grep -Fq 'https://github.com/$repository/releases/latest' "$UPDATER" ||
  fail 'manual GitHub release reporting is absent'
grep -Fq -- '--show-error --head' "$UPDATER" ||
  fail 'manual GitHub release reporting does not use metadata-only HEAD requests'
! rg -n 'releases/download|browser_download_url' "$UPDATER" >/dev/null ||
  fail 'manual release reporting can download release assets'
for release_check in \
  "report_manual_release Marksman artempyanykh/marksman \"\$marksman_version\"" \
  "report_manual_release 'Tinymist tagged source' Myriad-Dreamin/tinymist v0.15.2" \
  "report_manual_release 'Markdown Oxide tagged source' Feel-ix-343/markdown-oxide v0.25.12" \
  "report_manual_release 'JetBrainsMono Nerd Font' ryanoasis/nerd-fonts v3.5.0"; do
  grep -Fq "$release_check" "$UPDATER" || fail "missing selected manual release check: $release_check"
done
pass 'naldo-update has no noninteractive removal service reboot sync or automatic Git-binary update behavior'

for command in \
  'cargo install --locked --git https://github.com/Myriad-Dreamin/tinymist.git --tag v0.15.2 tinymist-cli' \
  'cargo install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git --tag v0.25.12 markdown-oxide'; do
  grep -Fq "$command" "$MAINTENANCE" || fail 'permanent maintenance guide lost a reviewed Git-tag install command'
done
grep -Fq 'each package manager updates only its locally' "$MAINTENANCE" ||
  fail 'maintenance guide does not explain differing local package sets'
# Literal Markdown assertions; backticks are documentation, not substitution.
# shellcheck disable=SC2016
for policy in \
  '`22.1.1` is the version of the **cargo-update program**' \
  '`cargo-install-update` and `cargo-install-update-config`' \
  '`cargo install-update -a`' \
  'It never passes `--git` or its short form `-g`' \
  '`herdr update` only when that receipt exactly names the' \
  'protocol-changing update may require restarting the active Herdr session' \
  '`pixi self-update` only when `pixi` resolves to' \
  'read-only GitHub release report for Marksman, Tinymist' \
  '`naldo-update` does not inspect or update its extensions' \
  'official Nerd Fonts `v3.5.0`'; do
  grep -Fq "$policy" "$MAINTENANCE" || fail "maintenance guide omits: $policy"
done
! rg -n 'wget|github.*download|curl.*releases/download' "$UPDATER" >/dev/null ||
  fail 'naldo-update contains a generic network/binary updater'
pass 'permanent maintenance guidance preserves automatic and report-only provider boundaries'

printf '1..%d\n' "$checks"
