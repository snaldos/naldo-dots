#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
for command_name in node npm pi tsc; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf 'not ok 1 - required Pi compatibility command is missing: %s\n' "$command_name" >&2
    exit 1
  }
done

npm_root="$(npm root --global)"
pi_root="$npm_root/@earendil-works/pi-coding-agent"
[[ -f "$pi_root/package.json" && -f "$pi_root/dist/index.d.ts" ]] || {
  printf 'not ok 1 - installed Pi package or API declarations are missing\n' >&2
  exit 1
}

cli_version="$(pi --version | head -n 1)"
package_version="$(node -p "require('$pi_root/package.json').version")"
[[ "$cli_version" == "$package_version" ]] || {
  printf 'not ok 1 - Pi CLI/package version mismatch: %s != %s\n' \
    "$cli_version" "$package_version" >&2
  exit 1
}

work="$(mktemp -d "${TMPDIR:-/tmp}/pi-compatibility-test.XXXXXX")"
trap 'rm -rf -- "$work"' EXIT
ln -s "$REPO_DIR/pi/.pi/agent/extensions" "$work/extensions"
cat >"$work/tsconfig.json" <<EOF
{
  "compilerOptions": {
    "target": "ES2023",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "skipLibCheck": true,
    "types": ["node"],
    "typeRoots": ["$pi_root/node_modules/@types"],
    "paths": {
      "@earendil-works/pi-coding-agent": ["$pi_root/dist/index.d.ts"],
      "@earendil-works/*": ["$pi_root/node_modules/@earendil-works/*/dist/index.d.ts"]
    }
  },
  "include": ["extensions/**/*.ts"],
  "exclude": ["extensions/**/*.test.ts", "extensions/herdr-agent-state.ts"]
}
EOF

tsc --project "$work/tsconfig.json"
printf 'ok 1 - Pi %s extensions satisfy the installed strict TypeScript API\n' "$package_version"
printf '1..1\n'
