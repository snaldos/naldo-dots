# Shells, Config Formats, and Applications

## Validation Matrix

First resolve the loaded path, includes, generated ownership, and installed help. These are preferred checks, not permission to reload or update:

| Target | Typical durable source | Validation / inspection |
|---|---|---|
| Fish | `~/.config/fish/config.fish`, `conf.d/*.fish`, functions | `fish -n FILE`; inspect startup side effects before `fish -lc ...` |
| Bash scripts | shebang-selected script | `bash -n FILE`; `shellcheck FILE` only if already installed |
| Ghostty | active `~/.config/ghostty/*` file plus themes/includes | `ghostty +validate-config --config-file=PATH` |
| Neovim/LazyVim | `init.lua`, `lua/config/`, `lua/plugins/` | `luac -p FILE` for syntax; `nvim --headless '+qa'` and a targeted Lua/plugin load |
| Starship | `STARSHIP_CONFIG` or `~/.config/starship.toml` | `STARSHIP_CONFIG=PATH starship print-config >/dev/null`; inspect stderr |
| Fuzzel | `~/.config/fuzzel/fuzzel.ini` plus includes | `fuzzel --check-config --config=PATH` |
| Yazi | `yazi.toml`, `keymap.toml`, `theme.toml`, Lua plugins/flavors | `yazi --debug`; inspect diagnostics, not only exit status; `luac -p` for Lua |
| Herdr/Noctalia | active TOML plus state/overrides | use their application validators described in the other references |

Do not use mutating commands such as `starship config`, `ya pkg`, Lazy sync/update, or theme application as validators.

## Bash and Fish

Pi executes commands with Bash. Do not assume Fish aliases, abbreviations, universal variables, or command substitutions are available in tool calls.

For scripts:

- honor the shebang and whether the file is executed or sourced
- quote expansions; use arrays for argument lists; use NUL-delimited paths when needed
- do not parse `ls`
- do not add `set -euo pipefail` mechanically to sourced files or scripts that intentionally handle nonzero statuses
- use `mktemp` and cleanup traps for multi-file generation
- test the smallest non-destructive code path

For Fish, preserve Fish-native `set`, `if`, `function`, and command-substitution syntax. `fish -n` parses without executing; a login/interactive test can run startup hooks and therefore needs inspection first.

## Lua

Keep host environments distinct:

- Hyprland supplies the embedded global `hl`; use its installed stub and `Hyprland --verify-config`.
- Neovim supplies `vim`; use a headless Neovim test for semantic behavior.
- `luac -p` checks grammar only and does not resolve either host API.

Preserve existing `require` boundaries and local style. Use project `stylua.toml` only when StyLua is already installed, and avoid formatting unrelated files. For LazyVim, add or change focused specs under the existing `lua/plugins/` pattern; do not edit plugin-manager internals or update `lazy-lock.json` unless requested.

## TOML

TOML dotted keys, quoted keys, arrays of tables, duplicate keys, and table redefinition have semantic consequences. Preserve comments/order where practical and validate with the owning program. For tools with merged config, inspect both the user source and effective output; a valid source can still be shadowed by state overrides.

Never use a generated export to overwrite a hand-maintained source without diffing it first and preserving a rollback copy.

## Generated Theme Chain

Noctalia currently owns generated theme material in several targets. Reconfirm from `[theme.templates]` and file markers because beta versions can change paths. Typical examples are:

- Hyprland `noctalia.lua`
- Ghostty theme `themes/noctalia`
- Fuzzel included theme
- Yazi `noctalia` flavor
- the marked Noctalia palette block in `starship.toml`
- Neovim's generated `lua/config/matugen.lua`, sourced from the user template under `~/.config/noctalia/templates/`
- Zen Browser theme output

A file can be partly generated: edit outside marked regions only when the generator guarantees preservation. Validate every rewritten target after an authorized template application.

## Application Notes

### Ghostty

Confirm the active config from process arguments and Ghostty help; this workstation uses a named `config.ghostty`, not necessarily the upstream default filename. Resolve theme and shader paths relative to the active config as Ghostty does. Validate before asking a running terminal to reload; shader changes need a visual smoke test and an easy rollback.

### Neovim/LazyVim

Inspect `init.lua`, `lua/config/lazy.lua`, relevant plugin specs, `lazyvim.json`, and the lockfile status. A bare headless startup is only a baseline; test the module or event changed. Do not launch network installs, Mason updates, or plugin synchronization during validation.

### Starship

`starship print-config` materializes the computed config and catches parse/schema problems. `starship config NAME VALUE` edits the file and is therefore not a check. Preserve Noctalia's marked generated palette while keeping hand-authored module settings outside it.

### Fuzzel

It uses INI with include files. Validate the exact active file and ensure included generated themes exist. Do not launch its Wayland UI merely to parse config when `--check-config` suffices.

### Yazi

`yazi --debug` reports effective configuration and dependency diagnostics but may still exit successfully with missing optional tools; read the output. Keep openers and rules aligned, quote shell arguments safely, and do not run `ya pkg` unless package mutation was requested.

### Zen Browser

Confirm native package versus Flatpak and the exact profile selected before proposing paths. Browser profiles may contain credentials, cookies, history, session tabs, extensions, and sync data. Do not inspect profile databases. Limit work to an explicitly requested `user.js`, `userChrome.css`, policies, desktop entry, flags, or generated theme, and close/restart the browser only with approval.
