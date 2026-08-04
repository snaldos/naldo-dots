# Helix language servers and formatters

The tracked `languages.toml` names every active server command explicitly so
provider drift is testable. Recheck provider availability for the installed
Fedora release; rolling npm/uv tools are intentionally not snapshot-pinned.

## Source of truth

Provider, classification, command, and role metadata lives once in
`dnf-packages.tsv`, `npm-packages.tsv`, `uv-tools.tsv`, or `cargo-tools.tsv`.
The verifier and policy tests read those rows directly. `languages.toml` is the
authority for which servers and formatters are active; no fallback provider is
configured.

Fedora supplies Helix, ShellCheck, shfmt, uv, Rust, and Cargo. The Typst,
Markdown Oxide, and other selected language-server commands come only from the
manifest source named for them. Set `profile=desktop` or `profile=laptop` as in
`CLEAN-INSTALL.md` before running a manifest-derived command below.

## User npm prefix

Fedora 44's selected packages are `nodejs22` and `nodejs22-npm`. Fish adds
`~/.npm-global/bin` to `PATH`.

```bash
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
mapfile -t npm_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/npm-packages.tsv)
npm install --global "${npm_tools[@]}"
```

`vscode-langservers-extracted` is a community npm repackaging of VS Code's
language-server components, not a Fedora or Microsoft-supported system package.
The audited package exports the exact JSON, HTML, and CSS commands above. Never
use `sudo npm install -g`.

Update after reviewing release notes with `npm update --global PACKAGE` and
remove with `npm uninstall --global PACKAGE`.

## Python tools through uv

Global tools exist so Helix can always launch them:

```bash
mapfile -t uv_tools < <(awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && $3 != "optional" && $4 == "active" &&
    ($NF == "all" || $NF == profile) { print $1 }
' bootstrap/fedora/uv-tools.tsv)
for tool in "${uv_tools[@]}"; do
  uv tool install "$tool"
done
uv tool install ty@latest        # optional; remains inactive in Helix
```

BasedPyright owns type checking, completion, navigation, and type diagnostics.
Its tracked configuration disables import organization. Ruff owns lint
messages, lint fixes, import organization, and formatting. `ty` is not listed as
an active language server, so two full Python type checkers do not compete.

Update with `uv tool upgrade PACKAGE`; remove with `uv tool uninstall PACKAGE`.
For project and CI reproducibility, pin the same responsibilities separately:

```bash
uv add --dev basedpyright ruff
uv add --dev ty                  # optional experiment only
```

## Locked stable Cargo tools

Fish adds `~/.cargo/bin` to `PATH`. These pins are deliberate reproducibility
constraints and are authoritative in `cargo-tools.tsv`; no nightly source is
selected:

```bash
awk -F '\t' -v profile="$profile" '
  $1 !~ /^#/ && NF && ($NF == "all" || $NF == profile) { print $5 }
' bootstrap/fedora/cargo-tools.tsv
```

Review that output, then execute each line exactly. This keeps the locked command
in one authoritative place rather than copying its version into several files.
Taplo is installed as the official `taplo-cli` crate with the `lsp` feature;
the similarly named npm CLI is not selected because its distributed build omits
LSP support. Helix uses the same Cargo binary for TOML language intelligence and
stdin formatting.

Before changing a pin, inspect the stable release/tag and rerun the locked
versioned command. Uninstall with `cargo uninstall PACKAGE`. The `cargo-update`
row installs cargo-update program version `22.1.1`—not Cargo toolchain version
22.1.1—and exports `cargo-install-update` plus
`cargo-install-update-config`. It supplies the reviewed crates.io subcommand used
by the permanent manual maintenance workflow in
[`../../MAINTENANCE.md`](../../MAINTENANCE.md). Do not run the bulk update during
provisioning.

Markdown Oxide is required because Helix is the primary Markdown and
Obsidian-vault editor. Prettier only formats Markdown; Markdown Oxide supplies
PKM semantics and Harper supplies prose diagnostics.

## Post-install health

```bash
hx --health bash
hx --health json
hx --health yaml
hx --health toml
hx --health python
hx --health typst
hx --health markdown
```

HTML and CSS are also explicit in `languages.toml`; inspect them with
`hx --health html` and `hx --health css` when those formats are used.
