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
uv_rows = rows("uv-tools.tsv")
for row in uv_rows:
    package, commands, _classification, _activation, role, _profile = row
    assert role.strip()
    for command in commands.split(","):
        add(command, f"uv:{package}", role)
ty_rows = [row for row in uv_rows if row[0] == "ty"]
assert ty_rows == [[
    "ty",
    "ty",
    "feature",
    "active",
    "Installed Python type checker and Helix language server available for project-local opt-in; BasedPyright remains the global default",
    "all",
]], f"unexpected ty provider row: {ty_rows}"
cargo_rows = rows("cargo-tools.tsv")
for row in cargo_rows:
    package, commands, _classification, _source, install, _update, _uninstall, role, _profile = row
    assert "cargo install --locked" in install
    assert role.strip()
    for command in commands.split(","):
        add(command, f"cargo:{package}", role)
external_rows = rows("external-tools.tsv")
for row in external_rows:
    tool, _classification, _source_class, _source, commands, _desktops, _units, _update, _uninstall, role, _profile = row
    assert role.strip()
    if commands != "-":
        for command in commands.split(","):
            add(command, f"external:{tool}", role)
marksman_rows = [row for row in external_rows if row[0] == "marksman"]
assert len(marksman_rows) == 1, f"unexpected Marksman provider rows: {marksman_rows}"
marksman_row = marksman_rows[0]
assert marksman_row[1:5] == [
    "feature",
    "official-upstream-release",
    "https://github.com/artempyanykh/marksman/releases/tag/2026-02-08",
    "marksman",
]
assert marksman_row[8] == "rm ~/.local/bin/marksman"
assert marksman_row[-1] == "all"

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

with (root / "helix/.config/helix/config.toml").open("rb") as handle:
    editor_config = tomllib.load(handle)
expected_yazi_picker = [
    ":sh rm -f /tmp/helix-yazi-picker",
    ':insert-output yazi "%{buffer_name}" --chooser-file=/tmp/helix-yazi-picker',
    ':sh printf "\\x1b[?1049h\\x1b[?2004h" > /dev/tty',
    ":open %sh{cat /tmp/helix-yazi-picker}",
    ":redraw",
    ":set mouse false",
    ":set mouse true",
]
assert editor_config["keys"]["normal"]["C-y"] == expected_yazi_picker
assert any(
    row[0] == "yazi" and "yazi" in row[4].split(",") and row[-1] == "all"
    for row in rows("external-tools.tsv")
), "Yazi picker has no shared executable provider"

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
    "basedpyright-langserver", "ruff", "tinymist", "harper-ls", "marksman",
    "bash-language-server", "taplo", "yaml-language-server",
    "vscode-json-language-server", "vscode-html-language-server",
    "vscode-css-language-server", "typescript-language-server", "typstyle",
    "prettier", "shfmt",
}
assert helix_commands == expected, f"unexpected Helix command set: {sorted(helix_commands ^ expected)}"
for command in helix_commands | {"basedpyright", "ty", "typst", "shellcheck", "markdown-oxide"}:
    assert command in providers, f"{command} has no authoritative provider"

markdown_language = next(language for language in languages if language["name"] == "markdown")
assert markdown_language["language-servers"] == ["marksman", "harper-ls"]
assert servers["marksman"] == {"command": "marksman", "args": ["server"]}
assert servers["markdown-oxide"] == {"command": "markdown-oxide"}
assert providers["marksman"][0] == "external:marksman"
assert providers["markdown-oxide"][0] == "cargo:markdown-oxide"

python_language = next(language for language in languages if language["name"] == "python")
assert python_language["language-servers"] == ["basedpyright", "ruff"]
assert servers["basedpyright"]["command"] == "basedpyright-langserver"
assert servers["ty"] == {"command": "ty", "args": ["server"]}
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
prettier_role = providers["prettier"][1]
for file_kind in ["JavaScript", "JSX", "TypeScript", "TSX"]:
    assert file_kind in prettier_role, f"Prettier role omits {file_kind}"

# npm and uv are rolling user tools except for the active TypeScript major
# compatibility boundary; Cargo installs retain reviewed explicit versions/tags.
assert all(len(row) == 5 for row in rows("npm-packages.tsv"))
assert all(len(row) == 6 for row in rows("uv-tools.tsv"))
assert all(len(row) == 9 for row in rows("cargo-tools.tsv"))
PY
pass 'every active Helix command and the Yazi picker have installation-source providers'

grep -Fq 'disableOrganizeImports = true' "$REPO_DIR/helix/.config/helix/languages.toml" ||
  fail 'BasedPyright import organization is not disabled in favor of Ruff'
grep -Fq 'language-servers = ["basedpyright", "ruff"]' "$REPO_DIR/helix/.config/helix/languages.toml" ||
  fail 'Python active server responsibilities changed unexpectedly'
grep -Fq '# language-servers = ["ty", "ruff"]' "$REPO_DIR/helix/.config/helix/languages.toml" ||
  fail 'project-local ty override is not documented beside the Python default'
! grep -Eq '^[[:space:]]*language-servers = .*"ty"' "$REPO_DIR/helix/.config/helix/languages.toml" ||
  fail 'ty became active globally beside BasedPyright'
pass 'BasedPyright Ruff and installed project-opt-in ty have non-conflicting roles'

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
pass 'Typst project-local Markdown Oxide prose and TOML tooling retain deliberate stable Cargo providers'

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
health_loop="$(awk '
  /^for language in / { capture=1 }
  capture { print }
  capture && /; do$/ { exit }
' "$REPO_DIR/bootstrap/fedora/EDITOR-TOOLS.md" | tr '\n' ' ')"
for language in bash json yaml toml python typst markdown html css javascript typescript jsx tsx; do
  grep -Eq "(^|[[:space:]])${language}([[:space:]]|;|$)" <<<"$health_loop" ||
    fail "missing documented Helix health check: $language"
done
# The variable belongs to the documented loop and must remain literal here.
# shellcheck disable=SC2016
grep -Fq 'hx --health "$language"' "$REPO_DIR/bootstrap/fedora/EDITOR-TOOLS.md" ||
  fail 'documented Helix health loop does not invoke hx'
# The documented command intentionally retains the user's literal HOME variable.
# shellcheck disable=SC2016
grep -Fq '(cd "$HOME/Vaults/state-space" && hx --health markdown)' \
  "$REPO_DIR/bootstrap/fedora/EDITOR-TOOLS.md" ||
  fail 'State Space project-local Markdown health check is not documented'
grep -Fq 'marksman_sha=be5098e8213219269c47fc0d916a66fa31ce0602ec967475c722260aabf26087' \
  "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" ||
  fail 'Marksman clean-install procedure lacks the reviewed release digest'
pass 'rolling provider metadata and all required health checks are current'

printf '1..%d\n' "$checks"
