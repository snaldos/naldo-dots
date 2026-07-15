# Dotfiles

GNU Stow packages whose contents mirror their paths under `$HOME`.

## Install

Deploy every package and initialize machine-local Pi settings with:

```bash
./install.sh
```

Equivalent manual Stow command:

```bash
stow ghostty fish starship herdr nvim zathura yazi fuzzel hypr lazygit noctalia pi desktop automation machine
```

Reapply links with `stow --restow PACKAGE`, or remove a package's links with
`stow --delete PACKAGE`.

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
must contain `desktop` or `laptop`. Set that override during installation with,
for example, `MACHINE_PROFILE=desktop ./install.sh`.

## Generated themes and machine-local settings

Noctalia's rendered outputs are ignored; all durable template inputs live under
`~/.config/noctalia/templates/`. Missing outputs degrade safely: Ghostty and
Hyprland skip optional theme fragments, Neovim and Starship use tracked
fallbacks, Yazi and the generated Fuzzel/Zathura configs fall back to
application defaults, and Pi's extension selects built-in `dark` when
`noctalia.json` is unavailable.

Pi's active `settings.json` is machine-local because changing the live theme
rewrites it. `settings.default.json` is the tracked durable source used by
`install.sh` on a fresh machine.
