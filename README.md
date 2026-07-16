# Dotfiles

Portable Arch Linux and Hyprland workstation configuration, organized as GNU
Stow packages whose contents mirror their paths under `$HOME`.

<p align="center">
  <a href="assets/screenshots/desktop-overview.png">
    <img src="assets/screenshots/desktop-overview.png" alt="Hyprland desktop with Noctalia, Ghostty, Neovim, Yazi, and Zathura" width="100%">
  </a>
</p>

<p align="center">
  <em>Hyprland · Noctalia · Ghostty Cosmos · Pi Coding Agent · LazyVim · Zathura</em>
</p>

## Install

Run the complete user-level bootstrap:

```bash
./install.sh                    # prompts on a fresh interactive machine
./install.sh --profile desktop
./install.sh --profile laptop
./install.sh --non-interactive  # tracked default when no profile exists
```

It validates prerequisites and the selected profile, serializes against
`sync-all`, enforces clean package-source boundaries, deploys all packages,
initializes machine-local Fish and Pi files when absent, and reloads
user-systemd units. It does not install Arch packages or modify system files.

Equivalent manual Stow command (links only):

```bash
stow --no-folding ghostty fish starship herdr nvim zathura yazi hypr lazygit noctalia pi desktop automation machine
```

Reapply links with `stow --no-folding --restow PACKAGE`, or remove links with
`stow --no-folding --delete PACKAGE`.

`--no-folding` is required: deployed directories stay real, tracked files are
individual symlinks, and generated/private files stay physically outside the
repository. Package `.gitignore` files are source metadata and are not deployed.
Conflicting files or invalid topology stop installation for explicit review.

`desktop` owns portable desktop preferences such as `mimeapps.list`.
`automation` owns the centralized synchronization commands and user systemd
units. Herdr tracks only `~/.config/herdr/config.toml`; logs, sockets, session
history, and other runtime state stay machine-local.

## Synchronization

`./sync.sh` stages all non-ignored dotfile changes, checks whitespace, commits,
fetches/rebases `origin/main`, and pushes. It stops on conflicts rather than
silently choosing a side.

One user timer runs all repository synchronizers:

```bash
sync-control enable          # enable at login and start now
sync-control pause           # stop only for this login session
sync-control resume
sync-control interval 6h
sync-control run             # run immediately
sync-control status
```

The Hyprland scripts launcher exposes the same controls, including a `1min`
testing interval. Prefer `30min` or longer for routine use. The selected
interval is machine-local and ignored by Git. Every machine uses a local
`~/backups` clone with its own Git history and remote.

The `machine` package deploys `~/.config/naldo/machine-profile/`. Its tracked
`default` is `laptop`; an optional machine-local `profile` file overrides it and
must contain `desktop` or `laptop`. Fresh interactive installs choose from this
tracked enum; automation uses `./install.sh --profile PROFILE`.

## Generated themes and machine-local settings

Noctalia's rendered outputs are ignored; all durable template inputs live under
`~/.config/noctalia/templates/`. Ghostty's shader manager similarly keeps its
active config and content-addressed shader outputs machine-local. Missing
outputs degrade safely: Ghostty and
Hyprland skip optional theme fragments, Neovim and Starship use tracked
fallbacks, Yazi and the generated Zathura config fall back to application
defaults, and Pi's extension selects built-in `dark` when
`noctalia.json` is unavailable.

Pi persists `/settings`, model, thinking, and theme selections in its active
machine-local `settings.json`. The tracked `settings.default.json` initializes a
fresh machine without pinning a provider, model, thinking level, theme, or
mutable changelog version; an existing active file is never overwritten. Fish
similarly sources ignored `~/.config/fish/local.fish` after the shared
configuration.
