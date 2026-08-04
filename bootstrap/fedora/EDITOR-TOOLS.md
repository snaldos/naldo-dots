# Helix and scientific editor tooling

Helix (`hx`) is the primary editor. Visual Studio Code is a minimal scientific
fallback with only Python, Jupyter, and Ruff selected directly. Provider rows in
`dnf-packages.tsv`, `npm-packages.tsv`, `uv-tools.tsv`, and `cargo-tools.tsv`
own installation; `helix/.config/helix/languages.toml` owns active LSP and
formatter responsibilities.

## Active responsibilities

| Files | Language intelligence | Formatting |
|---|---|---|
| Python | BasedPyright types/completion/navigation + Ruff lint/fixes/imports | Ruff |
| Typst | Tinymist + Harper prose diagnostics | Typstyle |
| Markdown | Markdown Oxide vault/PKM + Harper prose diagnostics | Prettier |
| JavaScript, JSX, TypeScript, TSX | TypeScript Language Server | Prettier |
| Bash | Bash Language Server | shfmt |
| TOML | Taplo LSP | Taplo |
| JSON/JSONC, YAML, HTML, CSS | selected VS Code-derived language servers | Prettier |

`ty` remains an optional Python experiment and is not active beside
BasedPyright. No Helix debug adapter is selected; VS Code covers occasional
interactive Python/JavaScript debugging without adding another Helix provider.

## User npm prefix

Fedora supplies Node/npm. Install selected npm tools without root:

```bash
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
mapfile -t npm_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && ($NF == "all" || $NF == profile) {
    print $1
  }
' bootstrap/fedora/npm-packages.tsv)
npm install --global "${npm_tools[@]}"
```

Never run `sudo npm install -g`. `vscode-langservers-extracted` is a community
npm repackaging used only for JSON, HTML, and CSS language servers.

### TypeScript compatibility boundary

`typescript-language-server 5.3.0` still starts the `tsserver` API. TypeScript 7
removed that executable, so the selected runtime is `typescript@6`. This is an
active compatibility requirement, not a stale snapshot. `naldo-update` updates
other outdated global npm packages normally and reifies TypeScript only within
major version 6 while it is already installed.

Verify both provider and real LSP availability:

```bash
typescript-language-server --version
tsc --version
command -v tsserver
hx --health javascript
hx --health jsx
hx --health typescript
hx --health tsx
```

## Python tools through uv

Global tools let Helix launch them outside any project:

```bash
mapfile -t uv_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && $4 == "active" &&
    ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/uv-tools.tsv)
for tool in "${uv_tools[@]}"; do
  uv tool install "$tool"
done
```

Projects should declare their own reproducible development dependencies:

```bash
uv add --dev basedpyright ruff
# or use a Pixi environment when native/conda/CUDA dependencies justify it
```

Do not install Conda beside Pixi by default. Pixi already resolves conda-forge
packages, native dependencies, lockfiles, tasks, and PyPI packages. Add Conda
only for an external workflow that genuinely requires the `conda` executable or
a non-Pixi-compatible provider.

## Locked Cargo tools

Print reviewed install commands from the manifest:

```bash
awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) { print $5 }
' bootstrap/fedora/cargo-tools.tsv
```

Run each printed command deliberately. Cargo pins record known installation
routes; routine registry updates use `cargo install-update -a`. Tinymist and
Markdown Oxide come from reviewed upstream tags and remain manual updates.
Taplo must remain the Cargo `taplo-cli` build with its `lsp` feature; the npm
package with the same name does not supply the required LSP build.

## Minimal Visual Studio Code fallback

Visual Studio Code comes from Microsoft's signed RPM repository. Install only
these direct selections:

```bash
for extension in ms-python.python ms-toolsai.jupyter charliermarsh.ruff; do
  code --install-extension "$extension"
done
```

VS Code may install extension dependencies such as debugpy, Pylance, Python
Environments, and Jupyter renderers. Those are dependency closure, not separate
selections. Do not copy a settings profile or add an extension pack unless a
real workflow requires it.

## Complete health check

```bash
hx --health bash
hx --health json
hx --health yaml
hx --health toml
hx --health python
hx --health typst
hx --health markdown
hx --health html
hx --health css
hx --health javascript
hx --health typescript
hx --health jsx
hx --health tsx
```

A missing optional debug adapter does not invalidate LSP, parser, or formatter
health. Investigate only red entries corresponding to selected responsibilities
in the table above.
