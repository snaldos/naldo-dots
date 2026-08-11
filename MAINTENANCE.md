# Fedora KDE system maintenance

Run `naldo-update` manually from a terminal when there is time to review prompts,
release reports, and failures. It updates the normal system providers while
leaving VS Code extension maintenance to VS Code itself. It works on both
profiles because each package manager updates only its locally installed
packages. It never synchronizes repositories, reboots, enables services, removes
software, or installs a missing provider.

Provider order:

1. `sudo dnf upgrade --refresh`
2. `flatpak update --user`
3. `gh extension upgrade --all`, only when `gh` is authenticated and has extensions
4. outdated global npm packages, excluding TypeScript's incompatible next major
5. `npm install --global 'typescript@6'`, only when TypeScript is already installed
6. `uv tool upgrade --all`
7. `cargo install-update -a`
8. `pixi self-update`, only for the official-installer-owned binary
9. read-only release reports for the manually reviewed GitHub tools and font
10. `tuicr update`, only with a valid official-installer receipt
11. `herdr update`, only with a valid stable-channel official-installer receipt

An unavailable/unrecognized provider is reported and skipped. Any attempted
update failure stops the command; a failed read-only release query is reported
without blocking unrelated providers. DNF owns Fedora, COPR, Microsoft VS Code,
Google Chrome, and Tailscale RPMs; all installed RPMs follow the ordinary DNF
transaction. The updater does not replace packages through a generic GitHub
downloader.

Marksman, the two Git-tagged Cargo tools, and the Nerd Font remain deliberate
manual replacements. `naldo-update` reports their selected and latest release
tags but never downloads their assets.

## Manual release report

`naldo-update` makes a read-only GitHub release report for Marksman, Tinymist,
Markdown Oxide, and the JetBrainsMono Nerd Font. It follows each repository's `releases/latest`
redirect and prints one of:

- `CURRENT (manual)` when the selected release equals the latest release;
- `MANUAL UPDATE AVAILABLE` with both release tags when they differ;
- `CHECK FAILED` when GitHub cannot be queried, without failing later providers.

This report downloads no release asset and changes no executable, Cargo package,
or font. For the tagged Cargo tools and font, the selected baselines embedded in
`naldo-update` mirror the manifests; update both together after review. Then
follow the pinned manual procedure below.

## npm and TypeScript

The selected TypeScript Language Server still requires `tsserver`. TypeScript 7
removed that executable, so `typescript@6` is the active compatibility boundary.
`naldo-update` queries outdated packages, updates every other installed global
package, and reifies the latest TypeScript 6 only if TypeScript is already
present. It does not use that command to install TypeScript on an unprovisioned
machine.

Remove the constraint only after a real Helix LSP initialization succeeds with
the replacement TypeScript server architecture—not merely when `tsc` exists.

## uv Python tools

`uv tool upgrade --all` maintains the installed BasedPyright, `ty`, and Ruff
tool environments. It does not add a missing tool; provision missing selections
from `bootstrap/fedora/uv-tools.tsv` through the clean-install procedure.
BasedPyright remains Helix's global default, while projects may opt into `ty` in
`.helix/languages.toml`. Do not enable both type checkers for one buffer.

## VS Code

VS Code is a configured non-primary fallback. Its RPM follows the ordinary DNF
transaction, but `naldo-update` does not inspect or update its extensions.
Maintain those from VS Code itself when you choose to use it.

## GitHub CLI extension

`gh-dash` is managed by GitHub CLI during `naldo-update`; its update requires a
valid keyring-backed `gh auth` login.

## Tuicr direct installation

The reviewed installer places Tuicr at `~/.local/bin/tuicr`. Clean installation
also compares it against a checksum-verified release asset and writes:

```text
${XDG_DATA_HOME:-~/.local/share}/naldo/provider-receipts/tuicr-official-installer
```

`naldo-update` runs `tuicr update` only when that receipt exactly names
`https://tuicr.dev/install.sh` and the resolved binary. A specific known-good
release can be restored manually:

```bash
tuicr update 0.20.0
```

Remove only `~/.local/bin/tuicr` and its receipt when uninstalling; repository
configuration is separate.

## Marksman upstream binary

Marksman is pinned under `~/.local/bin` because Fedora 44 does not provide it in
the enabled repositories. `naldo-update` compares its installed version with the
latest GitHub release but does not replace it. Review a new stable release,
update the release tag and GitHub-published SHA-256 in
`bootstrap/fedora/CLEAN-INSTALL.md`, and repeat its checksum-verified installation
block. Confirm both Markdown scopes afterward:

```bash
marksman --version
(cd "$HOME/dotfiles" && hx --health markdown)
(cd "$HOME/Vaults/state-space" && hx --health markdown)
```

Remove only `~/.local/bin/marksman` when uninstalling; the global and project
Helix configurations are separate.

## Cargo binaries

`22.1.1` is the version of the **cargo-update program**, not the Fedora Cargo
toolchain. The package exports both
`cargo-install-update` and `cargo-install-update-config`; Cargo exposes the first
as the `cargo install-update` subcommand.

`naldo-update` runs exactly `cargo install-update -a` for registry binaries.
It never passes `--git` or its short form `-g`, so Git-originating tools are not
silently moved to a new commit/tag. It reports the latest Tinymist and Markdown
Oxide releases against the selected tags. Update either tagged tool only after
reviewing a new stable release and editing its manifest command:

```bash
cargo install --locked --git https://github.com/Myriad-Dreamin/tinymist.git --tag v0.15.2 tinymist-cli
cargo install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git --tag v0.25.12 markdown-oxide
hx --health typst
hx --health markdown
```

## Herdr direct installation

Herdr's installer writes `~/.local/bin/herdr`; the clean-install procedure adds
a machine-local receipt under
`${XDG_DATA_HOME:-~/.local/share}/naldo/provider-receipts/`.
`naldo-update` runs `herdr update` only when that receipt exactly names the
official installer and resolved binary, and `herdr channel show` reports
`stable`.

A protocol-changing update may require restarting the active Herdr session.
Follow its interactive prompt: stopping the server also exits pane processes.
Remove the binary and receipt together when uninstalling; configuration, logs,
integrations, and session state are separate.

## Pixi

The official installer owns `~/.pixi/bin/pixi`. `naldo-update` runs
`pixi self-update` only when `pixi` resolves to that exact path; it skips a
missing or package-manager-owned Pixi. The official self-updater displays release
notes and replaces only the Pixi binary. Conda is not selected because Pixi
already covers conda-forge/native/CUDA environments without another base
environment, solver, cache, or shell activation layer.

## JetBrainsMono Nerd Font

The selected font is the official Nerd Fonts `v3.5.0` JetBrainsMono release,
installed under `~/.local/share/fonts/JetBrainsMonoNerdFont`. `naldo-update`
reports whether a newer Nerd Fonts release exists but does not replace fonts.
For an occasional reviewed update, verify the release archive, replace only that
directory, run `fc-cache`, and confirm the exact configured family with
`fc-list`/`fc-match`.
