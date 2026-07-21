# Shells, Config Formats, and Applications

## Validation Matrix

First resolve the loaded path, Stow source, includes/requires, and generator.
These are inspection commands, not permission to reload or update:

| Target | Durable source model | Validation / inspection |
|---|---|---|
| Fish | `fish/.config/fish/` Stow package | `fish -n FILE`; inspect startup side effects before executing Fish |
| Bash scripts | shebang-selected tracked script | `bash -n FILE`; `shellcheck` only when already installed |
| Ghostty | tracked active config plus optional generated theme | `ghostty +validate-config --config-file=PATH` |
| Neovim/LazyVim | tracked `init.lua`, `lua/config/`, `lua/plugins/` | `luac -p`; targeted `nvim --headless` startup/module check |
| Starship | generated active config or tracked base fallback | `STARSHIP_CONFIG=PATH starship print-config >/dev/null` |
| Zathura | tracked behavior config plus generated color include | inspect `zathurarc(5)`; source the config in a running instance when available |
| Yazi | tracked behavior config plus generated selector/flavor | `yazi --debug`; inspect diagnostics, not only exit status |
| Pi | tracked default/extensions plus ignored active settings/theme | parse JSON; test extension selection with a mock or Pi loader |
| Noctalia | tracked config/templates plus machine state | `noctalia config validate PATH` |

Do not use mutating commands such as `starship config`, `ya pkg`, Lazy
sync/update, repository `sync.sh`, or Noctalia template application as validators.

## Bash and Fish

Pi executes tools with Bash. Do not assume Fish aliases, abbreviations,
universal variables, or substitutions are available in tool calls.

For scripts:

- honor the shebang and whether the file is executed or sourced
- quote expansions; use arrays for arguments and NUL-delimited paths when needed
- do not parse `ls`
- do not add strict mode mechanically to sourced or intentionally fault-tolerant files
- use `mktemp` and cleanup traps for multi-file generation
- test the smallest non-destructive path; mock repository/network commands when practical

For Fish, preserve native `set`, `if`, `function`, and substitution syntax.
`fish -n` parses without executing; interactive/login tests can run startup
hooks and require prior inspection. `fish_variables` is generated, ignored
machine state and must not return to Git. Portable PATH entries are declared in
`config.fish` with `fish_add_path --path`, not universal variables. Optional
machine-only overrides belong in `~/.config/fish/local.fish`, which the shared
config sources last. The no-folding installer keeps both local files outside the
Fish package tree as real files on each machine.

## Lua

Keep host environments distinct:

- Hyprland supplies global `hl`; inspect `/usr/share/hypr/stubs/hl.meta.lua`.
- Neovim supplies global `vim`; use a headless Neovim semantic test.
- `luac -p` resolves neither host API.

Preserve `require` boundaries and verify that guarded paths match actual module
locations. A module can be syntactically valid yet never loaded. For LazyVim,
change focused specs under the existing `lua/plugins/` structure; do not update
`lazy-lock.json`, Mason, or plugins unless requested.

## TOML and JSON

Dotted keys, arrays of tables, duplicate tables, and merge precedence matter.
Preserve comments/order where practical and use the owning validator. A valid
source may still be shadowed by state overrides. Never overwrite a maintained
source with a generated export without reviewing a diff and rollback.

Do not assume all JSON is safe to track: Pi's active settings and Noctalia state
can be valid JSON/TOML while containing machine changes or credentials.

## Current Noctalia Theme Chain

All durable user-template inputs are centralized under
`~/.config/noctalia/templates/`. The active `[theme.templates]` table is the
source of truth; currently configured user outputs include:

- Ghostty: optional `~/.config/ghostty/themes/noctalia` fragment
- Neovim: `lua/generated/matugen.lua`
- Pi: `~/.pi/agent/themes/noctalia.json`
- Starship: complete `~/.config/starship.toml`
- Yazi: flavor, syntax theme, and `theme.toml` selector
- Zathura: color fragment `~/.config/zathura/noctaliarc`

Noctalia also owns selected builtin/community outputs such as Hyprland and Zen.
Every rendered output above is ignored. Edit templates or stable consumer logic,
not outputs. See
[dotfiles-sync-backup.md](dotfiles-sync-backup.md) for absence fallbacks and
ownership boundaries.

`noctalia msg templates-apply` rewrites multiple applications and may run hooks.
Use it only with explicit authorization, then validate every affected consumer.

## Application Notes

### Ghostty

The tracked active file is `config.ghostty`. It uses optional config fragments
for generated theme and shader state, so absence must remain valid. The shader
manager writes `shaders/active.ghostty` plus content-addressed files under
`shaders/generated/`; the main config includes the active file through its
canonical home-relative path. Do not make that include source-relative: Ghostty
resolves a Stow symlink to its repository path. Validate the effective config
and confirm the configured shader path changes before sending reload signals.
Shader changes still require a visual check and rollback.

### Neovim/LazyVim

`lua/config/theme.lua` is the explicit backend selector with values
`tokyonight` or `matugen`; the tracked default is `tokyonight`.
Matugen must fall back when its generated module is missing. A bare startup is a
baseline only—assert the active colorscheme or load the changed module.
Neovim's local `.git` metadata is not part of the outer dotfiles repository.

### Starship

Fish sets `STARSHIP_CONFIG` to generated `~/.config/starship.toml` when present
and tracked `~/.config/starship.base.toml` otherwise. Starship has no native
config-include mechanism, so the rendered active file intentionally contains
both portable behavior and its generated palette; keep that behavior aligned
with the tracked base. Validate both. `starship config NAME VALUE` edits a file
and is not a check.

### Zathura

The tracked `zathurarc` owns portable behavior and includes the ignored local
`noctaliarc`, which Noctalia renders with colors only. `install.sh` initializes
an empty real include so a missing render leaves Zathura on application colors.
Relative includes resolve from the file currently being processed. The reload
hook sources `zathurarc`, which in turn reloads the generated color fragment.

### Yazi

`yazi --debug` can exit successfully while reporting missing optional tools or
flavors, so inspect its output. `yazi.toml` is tracked; Noctalia generates the
theme selector and flavor. Missing generated theme files must leave Yazi on its
preset defaults.

### Pi

`settings.default.json` is a neutral tracked seed without provider, model,
thinking, theme, or changelog selections. Active `settings.json` is ignored
because Pi persists `/settings` and extension theme changes there. The Noctalia
theme extension chooses the generated theme only when discovered and otherwise
uses built-in `dark`. Credentials, sessions, databases, and active settings must
remain absent from the Git index.

### Zen Browser

Confirm native package versus Flatpak and selected profile before proposing
paths. Profiles contain credentials, cookies, history, sessions, and extension
state. Do not inspect profile databases. Limit work to explicitly requested CSS,
policies, flags, desktop entries, or generated theme output; restart only with
approval.
