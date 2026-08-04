#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
VERIFIER="$REPO_DIR/bootstrap/fedora/verify.sh"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/fedora-profile-test.XXXXXX")"
fixture_repo="$workspace/repo"
fixture_bootstrap="$fixture_repo/bootstrap/fedora"
fixture_home="$workspace/home"
checks=0
last_status=0
mkdir -p "$fixture_bootstrap" "$fixture_home"
trap 'rm -rf -- "$workspace"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$*"
}

python3 - "$REPO_DIR" <<'PY'
from __future__ import annotations

import csv
from pathlib import Path
import sys

root = Path(sys.argv[1])
bootstrap = root / "bootstrap/fedora"
columns = {
    "dnf-packages.tsv": 7,
    "flatpaks.tsv": 7,
    "npm-packages.tsv": 5,
    "uv-tools.tsv": 6,
    "cargo-tools.tsv": 9,
    "external-tools.tsv": 11,
}
profiled: dict[str, list[tuple[str, str]]] = {"desktop": [], "laptop": []}
for name, expected_columns in columns.items():
    with (bootstrap / name).open(newline="") as handle:
        parsed = list(csv.reader(handle, delimiter="\t"))
    assert parsed[0][-1] == "profile", f"profile is not the final header field in {name}"
    rows = [row for row in parsed if row and not row[0].startswith("#")]
    assert rows, f"empty clean-install manifest: {name}"
    assert all(len(row) == expected_columns for row in rows), f"wrong field count in {name}"
    assert all(row[-1] in {"all", "desktop", "laptop"} for row in rows), f"invalid profile in {name}"
    for row in rows:
        if row[-1] != "all":
            profiled[row[-1]].append((name, row[0]))
assert profiled["desktop"] == [("external-tools.tsv", "nvidia-driver-desktop")], profiled["desktop"]
assert profiled["laptop"] == [], "laptop-only rows require a deliberately selected laptop-specific tool"
PY
pass 'all six manifests use one final all desktop or laptop field with only audited NVIDIA specialization'

for manifest in dnf-packages.tsv flatpaks.tsv npm-packages.tsv uv-tools.tsv cargo-tools.tsv external-tools.tsv; do
  grep -Fq "bootstrap/fedora/$manifest" "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
    fail "clean-install guide does not derive its selection from $manifest"
done
profile_filter="\$NF == \"all\" || \$NF == profile"
[[ "$(grep -Fc "$profile_filter" "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md")" -ge 6 ]] ||
  fail 'manifest-derived clean-install commands do not consistently filter their profile field'
for profile in desktop laptop; do
  grep -Fq "./bootstrap/fedora/verify.sh --profile $profile" \
    "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
    fail "clean-install verifier invocation omits profile: $profile"
done
pass 'clean-install manifest commands and verifier use the explicit selected profile'

cp "$VERIFIER" "$fixture_bootstrap/verify.sh"
for manifest in dnf-packages.tsv flatpaks.tsv npm-packages.tsv uv-tools.tsv cargo-tools.tsv external-tools.tsv; do
  grep '^#' "$REPO_DIR/bootstrap/fedora/$manifest" >"$fixture_bootstrap/$manifest"
done
git -C "$fixture_repo" init -q

set_npm_fixture() {
  local applicability="$1" command_name="$2"
  grep '^#' "$REPO_DIR/bootstrap/fedora/npm-packages.tsv" >"$fixture_bootstrap/npm-packages.tsv"
  printf 'profile-fixture\t%s\tfeature\tSynthetic required profile check\t%s\n' \
    "$command_name" "$applicability" >>"$fixture_bootstrap/npm-packages.tsv"
}

run_fixture() {
  local name="$1"
  shift
  if HOME="$fixture_home" "$fixture_bootstrap/verify.sh" "$@" >"$workspace/$name.log" 2>&1; then
    last_status=0
  else
    last_status=$?
  fi
}

set_npm_fixture all naldo-profile-all-missing
for profile in desktop laptop; do
  run_fixture "all-$profile" --profile "$profile"
  [[ "$last_status" == 1 ]] || fail "all row did not fail required verification for $profile"
  grep -Fq 'naldo-profile-all-missing' "$workspace/all-$profile.log" ||
    fail "all row was not checked for $profile"
done
pass 'all rows apply to both profiles'

set_npm_fixture desktop naldo-profile-desktop-missing
run_fixture desktop-row-desktop --profile desktop
[[ "$last_status" == 1 ]] || fail 'desktop required miss did not fail desktop verification'
grep -Fq 'naldo-profile-desktop-missing' "$workspace/desktop-row-desktop.log" ||
  fail 'desktop row was not checked for desktop'
run_fixture desktop-row-laptop --profile laptop
[[ "$last_status" == 0 ]] || fail 'desktop required miss failed laptop verification'
! grep -Fq 'naldo-profile-desktop-missing' "$workspace/desktop-row-laptop.log" ||
  fail 'desktop row was checked for laptop'
pass 'desktop rows and required misses apply only to desktop'

set_npm_fixture laptop naldo-profile-laptop-missing
run_fixture laptop-row-laptop --profile laptop
[[ "$last_status" == 1 ]] || fail 'laptop required miss did not fail laptop verification'
grep -Fq 'naldo-profile-laptop-missing' "$workspace/laptop-row-laptop.log" ||
  fail 'laptop row was not checked for laptop'
run_fixture laptop-row-desktop --profile desktop
[[ "$last_status" == 0 ]] || fail 'laptop required miss failed desktop verification'
! grep -Fq 'naldo-profile-laptop-missing' "$workspace/laptop-row-desktop.log" ||
  fail 'laptop row was checked for desktop'
pass 'laptop rows and required misses apply only to laptop'

set_npm_fixture all naldo-profile-cli-missing
run_fixture missing-profile
[[ "$last_status" == 2 ]] || fail 'missing verifier profile did not exit 2'
grep -Fq -- '--profile desktop|laptop is required' "$workspace/missing-profile.log" ||
  fail 'missing verifier profile diagnostic is unclear'
run_fixture invalid-profile --profile workstation
[[ "$last_status" == 2 ]] || fail 'invalid verifier profile did not exit 2'
grep -Fq 'invalid profile: workstation' "$workspace/invalid-profile.log" ||
  fail 'invalid verifier profile diagnostic is unclear'
run_fixture duplicate-profile --profile desktop --profile laptop
[[ "$last_status" == 2 ]] || fail 'duplicated verifier profile did not exit 2'
grep -Fq -- '--profile may be specified only once' "$workspace/duplicate-profile.log" ||
  fail 'duplicated verifier profile diagnostic is unclear'
set_npm_fixture workstation naldo-invalid-row-profile
run_fixture invalid-row-profile --profile desktop
[[ "$last_status" == 2 ]] || fail 'invalid manifest profile did not exit 2'
grep -Fq 'invalid profile workstation in npm-packages.tsv' "$workspace/invalid-row-profile.log" ||
  fail 'invalid manifest profile diagnostic is unclear'
pass 'missing invalid duplicated and malformed profiles fail clearly'

# A Flatpak-backed integration command is namespaced to its deployment rather
# than required on the host PATH.
grep '^#' "$REPO_DIR/bootstrap/fedora/npm-packages.tsv" >"$fixture_bootstrap/npm-packages.tsv"
grep '^#' "$REPO_DIR/bootstrap/fedora/flatpaks.tsv" >"$fixture_bootstrap/flatpaks.tsv"
printf 'com.example.Recorder\tfeature\tflathub\tcom.example.Recorder.desktop\tgpu-screen-recorder\tSynthetic Flatpak CLI\tall\n' \
  >>"$fixture_bootstrap/flatpaks.tsv"
flatpak_bin="$workspace/flatpak-bin"
flatpak_location="$workspace/flatpak-deployment"
mkdir -p "$flatpak_bin" "$flatpak_location/files/bin" "$fixture_home/.local/share/applications"
cat >"$flatpak_bin/flatpak" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == info && "${2:-}" == --show-location ]]; then
  printf '%s\n' "$FEDORA_PROFILE_FLATPAK_LOCATION"
  exit 0
fi
if [[ "${1:-}" == info ]]; then
  exit 0
fi
exit 2
EOF
cat >"$flatpak_location/files/bin/gpu-screen-recorder" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
: >"$fixture_home/.local/share/applications/com.example.Recorder.desktop"
chmod 0755 "$flatpak_bin/flatpak" "$flatpak_location/files/bin/gpu-screen-recorder"
if HOME="$fixture_home" PATH="$flatpak_bin:$PATH" \
  FEDORA_PROFILE_FLATPAK_LOCATION="$flatpak_location" \
  "$fixture_bootstrap/verify.sh" --profile desktop >"$workspace/flatpak-cli-present.log" 2>&1; then
  last_status=0
else
  last_status=$?
fi
[[ "$last_status" == 0 ]] || fail 'packaged Flatpak integration command was reported missing'
grep -Fq 'flatpak run --command=gpu-screen-recorder com.example.Recorder' \
  "$workspace/flatpak-cli-present.log" || fail 'Flatpak integration invocation was not reported'
rm -f -- "$flatpak_location/files/bin/gpu-screen-recorder"
if HOME="$fixture_home" PATH="$flatpak_bin:$PATH" \
  FEDORA_PROFILE_FLATPAK_LOCATION="$flatpak_location" \
  "$fixture_bootstrap/verify.sh" --profile desktop >"$workspace/flatpak-cli-missing.log" 2>&1; then
  last_status=0
else
  last_status=$?
fi
[[ "$last_status" == 1 ]] || fail 'missing packaged Flatpak command did not fail required verification'
grep -Eq '^MISSING[[:space:]]+integration.*flatpak run --command=gpu-screen-recorder' \
  "$workspace/flatpak-cli-missing.log" || fail 'missing Flatpak integration diagnostic is unclear'
pass 'verifier checks the Flatpak ID desktop export and packaged integration command without a host wrapper'

printf '1..%d\n' "$checks"
