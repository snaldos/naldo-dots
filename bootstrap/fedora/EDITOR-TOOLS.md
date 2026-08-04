# Helix and scientific editor tooling

Helix (`hx`) is the primary editor. VS Code is a minimal scientific fallback.
The canonical installation commands are in
[`CLEAN-INSTALL.md`](CLEAN-INSTALL.md); this document records ownership,
compatibility constraints, and health checks without duplicating the setup
sequence.

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

`ty` is an optional Python experiment and is not active beside BasedPyright. No
Helix debug adapter is selected.

## Provider boundaries

- Fedora owns Helix, Node/npm, uv, shfmt, and the compiler/build prerequisites.
- User-prefix npm owns Pi, Codex, Prettier, and the selected web/shell language
  servers under `~/.npm-global`.
- uv tool environments own BasedPyright and Ruff globally for Helix.
- Cargo owns the pinned Typst, TOML, Markdown, and prose tools.
- VS Code comes from Microsoft's signed RPM repository; its extension manager
  owns the selected Python, Jupyter, and Ruff extensions.

Every active command has one row in `dnf-packages.tsv`, `npm-packages.tsv`,
`uv-tools.tsv`, or `cargo-tools.tsv`. The active Helix mapping is
`helix/.config/helix/languages.toml`.

Never run global npm installation through sudo. The selected prefix is
`~/.npm-global`, which Fish adds to `PATH`.

## TypeScript compatibility boundary

The selected TypeScript Language Server still starts the `tsserver` API.
TypeScript 7 removed that executable, so `typescript@6` remains required.
`naldo-update` updates other global npm packages normally and reifies the latest
major-6 TypeScript only when TypeScript is already installed.

Remove this constraint only after a real Helix LSP initialization succeeds with
the replacement server architecture—not merely when `tsc` exists.

```bash
typescript-language-server --version
tsc --version
command -v tsserver
hx --health javascript
hx --health jsx
hx --health typescript
hx --health tsx
```

## Python and scientific environments

BasedPyright owns type intelligence. Ruff owns lint diagnostics, code actions,
import organization, and formatting. Project dependencies belong in a project
lockfile rather than the global tool environments:

```bash
uv add --dev basedpyright ruff
```

Use Pixi when native, conda-forge, CUDA, or cross-platform dependencies justify
it. Conda is not installed beside Pixi unless an external workflow requires the
`conda` executable or a provider Pixi cannot support.

## Cargo tools

Cargo rows contain reviewed, locked installation commands. Routine registry
updates use `cargo install-update -a`. Tinymist and Markdown Oxide come from
reviewed upstream tags and therefore remain deliberate manual updates.

Taplo must remain the Cargo `taplo-cli` build with its `lsp` feature; the npm
package with the same name does not provide the required LSP build.

## Minimal VS Code fallback

Exactly these extensions are selected directly:

```text
ms-python.python
ms-toolsai.jupyter
charliermarsh.ruff
```

VS Code may install dependencies such as debugpy, Pylance, Python Environments,
and Jupyter renderers. They are provider-managed dependency closure, not
additional selections. No settings profile, extension pack, or separate
JavaScript debugger is selected.

## Health check

```bash
for language in bash json yaml toml python typst markdown html css \
  javascript typescript jsx tsx; do
  hx --health "$language"
done
```

A missing unselected debug adapter does not invalidate LSP, parser, or formatter
health. Investigate red entries only when they correspond to a responsibility in
the table above.
