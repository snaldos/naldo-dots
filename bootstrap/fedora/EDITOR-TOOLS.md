# Helix and scientific editor tooling

Helix (`hx`) is the primary editor. VS Code is a minimal scientific fallback.
The canonical installation commands are in
[`CLEAN-INSTALL.md`](CLEAN-INSTALL.md); this document records ownership,
compatibility constraints, and health checks without duplicating the setup
sequence.

## Active responsibilities

| Files | Language intelligence | Formatting |
|---|---|---|
| Python | BasedPyright types/completion/navigation + Ruff lint/fixes/imports by default; ty + Ruff per project | Ruff |
| Typst | Tinymist + Harper prose diagnostics | Typstyle |
| Markdown | Marksman links/symbols + Harper prose diagnostics globally; Markdown Oxide + Harper in State Space | Prettier |
| JavaScript, JSX, TypeScript, TSX | TypeScript Language Server | Prettier |
| Bash | Bash Language Server | shfmt |
| TOML | Taplo LSP | Taplo |
| JSON/JSONC, YAML, HTML, CSS | selected VS Code-derived language servers | Prettier |

Both BasedPyright and `ty` are installed. BasedPyright remains the global Python
server; a project may select `ty` instead. They are never activated together.
No Helix debug adapter is selected.

## Provider boundaries

- Fedora owns Helix, Node/npm, uv, shfmt, and the compiler/build prerequisites.
- User-prefix npm owns Pi, Codex, Prettier, and the selected web/shell language
  servers under `~/.npm-global`.
- uv tool environments own BasedPyright, `ty`, and Ruff globally for Helix.
- Cargo owns the pinned Typst, TOML, Markdown Oxide, and prose tools.
- A pinned, checksum-verified upstream release owns Marksman under
  `~/.local/bin`; Fedora 44 has no package for it in the enabled repositories.
- VS Code comes from Microsoft's signed RPM repository; its extension manager
  owns the selected Python, Jupyter, and Ruff extensions.

Every active command has one row in `dnf-packages.tsv`, `npm-packages.tsv`,
`uv-tools.tsv`, `cargo-tools.tsv`, or `external-tools.tsv`. The active Helix
mapping is `helix/.config/helix/languages.toml`.

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

BasedPyright owns type intelligence by default. Ruff owns lint diagnostics, code
actions, import organization, and formatting. To evaluate `ty` in one project,
create `.helix/languages.toml` there without changing the global default:

```toml
[[language]]
name = "python"
language-servers = ["ty", "ruff"]
```

Use only one type checker at a time. If a project runs these tools in CI, lock
its selected checker and Ruff as development dependencies, for example
`uv add --dev ty ruff` or `uv add --dev basedpyright ruff`; the global uv tool
environments exist for editor use.

Use Pixi when native, conda-forge, CUDA, or cross-platform dependencies justify
it. Conda is not installed beside Pixi unless an external workflow requires the
`conda` executable or a provider Pixi cannot support.

## Markdown workspaces

Marksman is the global Markdown server for ordinary repositories and standalone
project work. Harper remains the prose checker and Prettier remains the formatter.
The global configuration also defines Markdown Oxide without activating it so a
project can select it by name.

State Space needs vault-aware wikilinks, backlinks, and note completion. Its
tracked `.helix/languages.toml` replaces the Markdown server list locally:

```toml
[[language]]
name = "markdown"
language-servers = ["markdown-oxide", "harper-ls"]
```

Check both scopes from their roots:

```bash
(cd "$HOME/dotfiles" && hx --health markdown)
(cd "$HOME/Vaults/state-space" && hx --health markdown)
```

## Cargo tools

Cargo rows contain reviewed, locked installation commands. Routine registry
updates use `cargo install-update -a`. Tinymist and Markdown Oxide come from
reviewed upstream tags and therefore remain deliberate manual updates. Marksman
is not Cargo-owned; update its pinned upstream binary and digest through the
clean-install procedure.

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
JavaScript debugger is selected. The VS Code RPM follows normal DNF upgrades,
while extension maintenance is initiated from VS Code itself.

## Health check

```bash
basedpyright --version
ty --version
ruff --version
marksman --version
for language in bash json yaml toml python typst markdown html css \
  javascript typescript jsx tsx; do
  hx --health "$language"
done
(cd "$HOME/Vaults/state-space" && hx --health markdown)
```

The loop reports the global Marksman mapping; the final command reports State
Space's project-local Markdown Oxide mapping. A missing unselected debug adapter
does not invalidate LSP, parser, or formatter health. Investigate red entries
only when they correspond to a responsibility in the table above.
