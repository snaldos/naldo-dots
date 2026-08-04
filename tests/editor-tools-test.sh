#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
checks=0

fail() {
  printf 'not ok %d - %s\n' "$((checks + 1))" "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$1"
}

python3 - "$REPO_DIR" <<'PY'
from __future__ import annotations

import csv
from pathlib import Path
import sys
import tomllib

root = Path(sys.argv[1])
bootstrap = root / "bootstrap/fedora"


def rows(name: str) -> list[list[str]]:
    with (bootstrap / name).open(newline="") as handle:
        return [row for row in csv.reader(handle, delimiter="\t") if row and row[0] and not row[0].startswith("#")]


providers: dict[str, tuple[str, str]] = {}

def add(command: str, provider: str, role: str) -> None:
    assert command not in providers, f"duplicate provider for command {command}: {providers[command][0]} and {provider}"
    providers[command] = (provider, role)

for row in rows("dnf-packages.tsv"):
    package, _classification, commands, _desktops, _units, purpose, _profile = row
    if commands != "-":
        for command in commands.split(","):
            add(command, f"dnf:{package}", purpose)
for row in rows("npm-packages.tsv"):
    package, commands, _classification, role, _profile = row
    assert role.strip()
    for command in commands.split(","):
        add(command, f"npm:{package}", role)
for row in rows("uv-tools.tsv"):
    package, commands, _classification, _activation, role, _profile = row
    assert role.strip()
    for command in commands.split(","):
        add(command, f"uv:{package}", role)
cargo_rows = rows("cargo-tools.tsv")
for row in cargo_rows:
    package, commands, _classification, _source, install, _update, _uninstall, role, _profile = row
    assert "cargo install --locked" in install
    assert role.strip()
    for command in commands.split(","):
        add(command, f"cargo:{package}", role)

tinymist_rows = [row for row in cargo_rows if row[0] == "tinymist-cli" or row[1] == "tinymist"]
assert tinymist_rows == [[
    "tinymist-cli",
    "tinymist",
    "feature",
    "https://github.com/Myriad-Dreamin/tinymist",
    "cargo install --locked --git https://github.com/Myriad-Dreamin/tinymist.git --tag v0.15.2 tinymist-cli",
    "audit a new stable upstream tag, update the manifest --tag, and repeat the locked tagged install",
    "cargo uninstall tinymist-cli",
    "Stable Typst language server",
    "all",
]], f"unexpected Tinymist provider row: {tinymist_rows}"

with (root / "helix/.config/helix/languages.toml").open("rb") as handle:
    config = tomllib.load(handle)
servers = config["language-server"]
languages = config["language"]
server_names = {name for language in languages for name in language.get("language-servers", [])}
server_commands = {servers[name]["command"] for name in server_names}
formatter_commands = {
    language["formatter"]["command"] for language in languages if "formatter" in language
}
helix_commands = server_commands | formatter_commands
expected = {
    "basedpyright-langserver", "ruff", "tinymist", "harper-ls", "markdown-oxide",
    "bash-language-server", "taplo", "yaml-language-server",
    "vscode-json-language-server", "vscode-html-language-server",
    "vscode-css-language-server", "typescript-language-server", "typstyle",
    "prettier", "shfmt",
}
assert helix_commands == expected, f"unexpected Helix command set: {sorted(helix_commands ^ expected)}"
for command in helix_commands | {"basedpyright", "ty", "typst", "shellcheck"}:
    assert command in providers, f"{command} has no authoritative provider"

python_language = next(language for language in languages if language["name"] == "python")
assert python_language["language-servers"] == ["basedpyright", "ruff"]
assert servers["basedpyright"]["command"] == "basedpyright-langserver"
assert python_language["formatter"]["command"] == "ruff"
assert servers["basedpyright"]["config"]["basedpyright"]["disableOrganizeImports"] is True
assert "ty" not in server_names and "ty" not in formatter_commands
assert providers["basedpyright"][0] == "uv:basedpyright"
assert providers["basedpyright-langserver"][0] == "uv:basedpyright"
assert providers["ruff"][0] == "uv:ruff"
assert providers["ty"][0] == "uv:ty"
assert providers["taplo"][0] == "cargo:taplo-cli"
toml_language = next(language for language in languages if language["name"] == "toml")
assert toml_language["language-servers"] == ["taplo"]
assert toml_language["formatter"] == {
    "command": "taplo",
    "args": ["format", "--stdin-filepath", "%{buffer_name}", "-"],
}
for command in ["typst", "tinymist", "typstyle", "harper-ls", "markdown-oxide", "taplo"]:
    assert providers[command][0].startswith("cargo:")

for name in ["javascript", "jsx", "typescript", "tsx"]:
    language = next(language for language in languages if language["name"] == name)
    assert language["language-servers"] == ["typescript-language-server"]
    assert language["formatter"] == {
        "command": "prettier",
        "args": ["--stdin-filepath", "%{buffer_name}"],
    }
    assert language["auto-format"] is True
assert servers["typescript-language-server"]["command"] == "typescript-language-server"
assert providers["typescript-language-server"][0] == "npm:typescript-language-server"
assert providers["tsc"][0] == "npm:typescript@6"
assert providers["tsserver"][0] == "npm:typescript@6"

# npm and uv are rolling user tools except for the active TypeScript major
# compatibility boundary; Cargo installs retain reviewed explicit versions/tags.
assert all(len(row) == 5 for row in rows("npm-packages.tsv"))
assert all(len(row) == 6 for row in rows("uv-tools.tsv"))
assert all(len(row) == 9 for row in rows("cargo-tools.tsv"))
PY
pass 'every active Helix command has exactly one installation-source provider'

grep -Fq 'disableOrganizeImports = true' "$REPO_DIR/helix/.config/helix/languages.toml" ||
  fail 'BasedPyright import organization is not disabled in favor of Ruff'
grep -Fq 'language-servers = ["basedpyright", "ruff"]' "$REPO_DIR/helix/.config/helix/languages.toml" ||
  fail 'Python active server responsibilities changed unexpectedly'
! grep -Eq 'language-servers = .*"ty"' "$REPO_DIR/helix/.config/helix/languages.toml" ||
  fail 'experimental ty became an active Python server'
pass 'BasedPyright Ruff and optional ty have non-conflicting roles'

awk -F '\t' '
  $1 == "typescript-language-server" && $2 == "typescript-language-server" && $3 == "feature" { server=1 }
  $1 == "typescript@6" && $2 == "tsc,tsserver" && $3 == "feature" { runtime=1 }
  END { exit !(server && runtime) }
' "$REPO_DIR/bootstrap/fedora/npm-packages.tsv" ||
  fail 'TypeScript language server and compatible tsserver runtime are not selected together'
for language in javascript jsx typescript tsx; do
  grep -A3 -F "name = \"$language\"" "$REPO_DIR/helix/.config/helix/languages.toml" |
    grep -Fq 'language-servers = ["typescript-language-server"]' ||
    fail "$language is not assigned to the selected TypeScript language server"
done
pass 'JavaScript TypeScript JSX and TSX share one compatible LSP and Prettier formatter policy'

for command in typst tinymist typstyle harper-ls markdown-oxide taplo; do
  awk -F '\t' -v command="$command" '$2 == command && $3 == "feature" && $5 ~ /^cargo install --locked/ { found=1 } END { exit !found }' \
    "$REPO_DIR/bootstrap/fedora/cargo-tools.tsv" || fail "$command lacks one locked stable Cargo installation"
done
! rg -n 'nightly' "$REPO_DIR/bootstrap/fedora/cargo-tools.tsv" ||
  fail 'nightly Cargo editor tooling is selected'
awk -F '\t' '
  $1 == "taplo-cli" && $2 == "taplo" && $3 == "feature" &&
  $4 == "https://crates.io/crates/taplo-cli" &&
  $5 == "cargo install --locked --version 0.10.0 --features lsp taplo-cli" &&
  $7 == "cargo uninstall taplo-cli" { found=1 }
  END { exit !found }
' "$REPO_DIR/bootstrap/fedora/cargo-tools.tsv" ||
  fail 'Taplo does not use the locked official Cargo build with LSP support'
! awk -F '\t' '$1 == "@taplo/cli" || $2 == "taplo" { found=1 } END { exit !found }' \
  "$REPO_DIR/bootstrap/fedora/npm-packages.tsv" || fail 'broken npm Taplo provider remains selected'
pass 'Typst Markdown prose and TOML tooling retain deliberate stable Cargo providers'

awk -F '\t' '
  $1 == "cargo-update" && $2 == "cargo-install-update,cargo-install-update-config" &&
  $3 == "feature" && $4 == "https://crates.io/crates/cargo-update" &&
  $5 == "cargo install --locked --version 22.1.1 cargo-update" &&
  $7 == "cargo uninstall cargo-update" { found=1 }
  END { exit !found }
' "$REPO_DIR/bootstrap/fedora/cargo-tools.tsv" ||
  fail 'cargo-update lacks the reviewed locked crates.io provider or exported commands'
pass 'cargo-update supplies both reviewed Cargo maintenance subcommands'

stale_tinymist_provider='crates[.]io/crates/tiny''mist'
stale_tinymist_install='cargo install --locked --version [^[:space:]]+ tiny''mist([[:space:]]|$)'
if git -C "$REPO_DIR" grep -I -n -E -- "$stale_tinymist_provider|$stale_tinymist_install"; then
  fail 'a stale crates.io Tinymist provider or binary install command remains'
fi
pass 'Tinymist uses only the tinymist-cli package from the locked v0.15.2 upstream tag'

! rg -n '@[0-9]+([.][0-9]+)+' "$REPO_DIR/bootstrap/fedora/npm-packages.tsv" \
  "$REPO_DIR/bootstrap/fedora/uv-tools.tsv" >/dev/null ||
  fail 'rolling npm or uv inventory retains a stale snapshot version'
for language in bash json yaml toml python typst markdown javascript typescript jsx tsx; do
  grep -Fq "hx --health $language" "$REPO_DIR/bootstrap/fedora/EDITOR-TOOLS.md" ||
    fail "missing documented Helix health check: $language"
done
pass 'rolling provider metadata and all required health checks are current'

printf '1..%d\n' "$checks"
