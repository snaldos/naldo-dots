# Shells, configuration formats, and applications

## Validation matrix

First resolve the loaded path, Stow source, includes, and generator.

| Target | Durable source | Validation |
|---|---|---|
| Fish | `fish/.config/fish/` | `fish -n FILE` |
| Bash | tracked executable script | `bash -n FILE`; installed ShellCheck |
| Ghostty | tracked behavior plus local generated fragments | `ghostty +validate-config --config-file=PATH` |
| Helix | tracked TOML plus generated base theme | `hx --health LANGUAGE` |
| Starship | tracked seed plus real active config | `STARSHIP_CONFIG=PATH starship print-config` |
| Yazi | tracked behavior plus generated flavor | inspect `yazi --debug` output |
| Pi | tracked defaults/extensions plus private active state | parse JSON; focused extension tests |
| Noctalia | tracked TOML/templates plus private state | `noctalia config validate PATH` |

Do not use update/sync/template-apply commands as validators.

## Bash and Fish

Pi executes Bash. Fish aliases, abbreviations, universal variables, and command
substitutions are unavailable in agent Bash calls. Honor each script's shebang,
quote arrays, avoid parsing `ls`, use temporary files with cleanup traps, and
mock network/Git operations in tests.

Fish's `fish_variables` and `local.fish` remain machine-local. Portable paths use
`fish_add_path --path`; npm, uv/upstream, and Cargo user commands live under
`~/.npm-global/bin`, `~/.local/bin`, and `~/.cargo/bin`. Fedora's Helix command
is `hx`; Fish exports it through `EDITOR` and `VISUAL`, and `install.sh` requires
it before deployment.

## Formats and private state

TOML merge precedence, dotted keys, and arrays of tables matter. JSON validity
does not make a file safe to track. Never replace a maintained source with a
generated export without a reviewed diff. Neovim is optional; when installed it
remains stock and has no tracked package or plugin manager.

## Theme chain

Durable Noctalia templates live under `~/.config/noctalia/templates/`. Generated
outputs include Ghostty, Helix, Niri, Pi, Starship, Yazi, Zathura, and selected
GTK/Qt resources. Absence must remain safe: optional includes are skipped,
Helix has a Nord base fallback, Starship has a behavior seed, Yazi uses defaults,
Zathura has an empty color include, and Pi falls back to built-in `dark`.

## Application notes

### Ghostty

The tracked config optionally loads generated shader/theme fragments. The shader
manager owns `active.ghostty`, content-addressed files, selection, enabled state,
and a generic profile name/ID. It injects only the five
`GHOSTTY_GPU_PROFILE*` constants; each GLSL source independently decides whether
and how that generic profile changes its own tuning. Validate before any
explicitly requested reload; visual shader behavior remains a manual check.

### Helix and Git clients

Helix is invoked as `hx`. The tracked Git include sets core and sequence editors
to `hx` without tracking identity, signing, credentials, or trust. LazyGit uses
its `helix (hx)` preset; Yazi, Herdr, Fish, and Pi use the same command. The
Noctalia-generated base theme stays ignored while the tracked override provides
reviewed compatibility colors.

### Starship and Zathura

Starship's real active config is initialized from the tracked seed, then receives
Noctalia's managed palette. Zathura's tracked behavior sources an ignored local
color fragment. Never point a rendering hook at a tracked seed or symlink.

### Yazi

Yazi is a terminal-only file manager invoked explicitly from a terminal, Fish,
Helix, or Herdr. Do not add a desktop entry or user `inode/directory` override;
Fedora's session-native handlers remain Nautilus in Niri and Dolphin in Plasma.
`yazi --debug` may report missing optional openers while exiting successfully.
Inspect diagnostics. imv, Swappy, Inkscape, and Okular come from Fedora; Sioyek
is the selected community-maintained, unverified Flatpak alternative.

### Pi

`settings.default.json` is a neutral fresh-machine seed with external editor
`hx`. Active `settings.json` remains a real ignored file and is initialized only
when absent. Credentials, trust, sessions, databases, logs, installed packages,
and Herdr-managed generated state never belong in the Stow source.

### Zen

Only the Flatpak `app.zen_browser.zen` is supported. Niri binds `Mod+Z` directly
to `flatpak run app.zen_browser.zen --new-window about:newtab`; MIME handling
uses `app.zen_browser.zen.desktop`. Zen and ordinary Ghostty windows have no
special floating identity or rule. Inspect Niri's actual app ID after
installation rather than inferring it from the Flatpak ID. Browser profiles and
histories remain private.
