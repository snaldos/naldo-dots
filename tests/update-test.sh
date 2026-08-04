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
herdr_receipt="$installer_data/naldo/provider-receipts/herdr-official-installer"
tuicr_receipt="$installer_data/naldo/provider-receipts/tuicr-official-installer"
mkdir -p "$fake_bin" "$workspace/away" "$workspace/empty-bin" "$installer_bin" "${herdr_receipt%/*}"
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
cat >"$fake_bin/code" <<'EOF'
#!/bin/bash
if [[ "$1" == --list-extensions ]]; then
  [[ "${NALDO_UPDATE_CODE_EMPTY:-0}" == 1 ]] || printf '%s\n' ms-python.python ms-toolsai.jupyter charliermarsh.ruff
  exit 0
fi
printf 'code' >>"$NALDO_UPDATE_TEST_LOG"
printf ' %s' "$@" >>"$NALDO_UPDATE_TEST_LOG"
printf '\n' >>"$NALDO_UPDATE_TEST_LOG"
[[ "${NALDO_UPDATE_FAIL:-}" != code ]] || exit "${NALDO_UPDATE_FAIL_STATUS:-23}"
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
chmod 0755 "$fake_bin/npm" "$fake_bin/code" "$fake_bin/gh"
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
printf 'source=https://herdr.dev/install.sh\nbinary=%s\n' \
  "$(readlink -f "$installer_bin/herdr")" >"$herdr_receipt"
printf 'source=https://tuicr.dev/install.sh\nbinary=%s\n' \
  "$(readlink -f "$installer_bin/tuicr")" >"$tuicr_receipt"
chmod 0600 "$herdr_receipt" "$tuicr_receipt"
provider_path="$installer_bin:$fake_bin"

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
code --update-extensions
gh extension upgrade --all
npm update --global prettier
npm install --global typescript@6
uv tool upgrade --all
cargo install-update -a
tuicr update
herdr update
EOF
diff -u "$workspace/providers.expected" "$workspace/providers.log" ||
  fail 'update providers did not run once in the required order'
for label in 'DNF packages' 'Flatpak applications' 'VS Code extensions' 'GitHub CLI extensions' \
  'global npm packages' 'uv tools' 'Cargo registry binaries' 'Tuicr official installer' \
  'Herdr official installer'; do
  grep -Fq "== $label ==" "$workspace/providers.out" || fail "missing provider section: $label"
done
grep -Fq 'protocol-changing update may require restarting the active Herdr session' "$workspace/providers.out" ||
  fail 'Herdr update did not warn about an active-session protocol change'
pass 'available providers run once in labeled DNF Flatpak VS Code GitHub npm uv Cargo Tuicr and Herdr order'

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

: >"$workspace/skipped.log"
PATH="$workspace/empty-bin" NALDO_UPDATE_TEST_LOG="$workspace/skipped.log" \
  /bin/bash "$workspace/naldo-update" >"$workspace/skipped.out"
[[ ! -s "$workspace/skipped.log" ]] || fail 'an unavailable provider was executed'
[[ "$(grep -c '^SKIP:' "$workspace/skipped.out")" == 9 ]] ||
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

head -n 9 "$workspace/providers.expected" >"$workspace/no-herdr.expected"
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
grep -Fq 'npm list --global --depth=0 --json typescript' "$UPDATER" ||
  fail 'TypeScript major constraint is not guarded by installed-package presence'
[[ "$(grep -Fc "npm install --global 'typescript@6'" "$UPDATER")" == 1 ]] ||
  fail 'TypeScript compatibility update is absent or duplicated'
pass 'naldo-update has no noninteractive removal service reboot sync or automatic Git-update behavior'

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
  'use `pixi self-update`' \
  'official Nerd Fonts `v3.5.0`'; do
  grep -Fq "$policy" "$MAINTENANCE" || fail "maintenance guide omits: $policy"
done
! rg -n 'curl|wget|github.*update' "$UPDATER" >/dev/null ||
  fail 'naldo-update contains a generic network/binary updater'
pass 'permanent maintenance guidance preserves Cargo Herdr Pixi font and local-provider policy'

printf '1..%d\n' "$checks"
