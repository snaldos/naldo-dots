#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
tests=(
  tests/repository-policy-test.sh
  tests/desktop-applications-test.sh
  tests/editor-tools-test.sh
  tests/fedora-cutover-test.sh
  tests/fedora-profile-test.sh
  tests/ghostty-shaders-test.sh
  tests/deploy-links-test.sh
  tests/install-test.sh
  tests/update-test.sh
  tests/sync-test.sh
  tests/install-system-test.sh
)

for test_path in "${tests[@]}"; do
  printf '\n### %s\n' "$test_path"
  "$REPO_DIR/$test_path"
done

printf '\n### Pi extension tests\n'
node --test "$REPO_DIR"/pi/.pi/agent/extensions/lib/*.test.ts

printf '\nAll %d shell test scripts and the Pi extension suite passed.\n' "${#tests[@]}"
