# Workstation maintenance

Run `naldo-update` manually from a terminal when there is time to review prompts
and failures. The same workflow works on the desktop and laptop even when their
installed package sets differ: each package manager updates only its locally
installed packages.

`naldo-update` runs the available providers in this order:

1. `sudo dnf upgrade --refresh`
2. `flatpak update --user`
3. `npm update --global`
4. `uv tool upgrade --all`
5. `cargo install-update -a`
6. `herdr update`, only for a stable-channel direct install carrying the
   reviewed official-installer receipt

An unavailable or unrecognized provider is reported and skipped. Any attempted
update failure stops the command with that failure status. The command does not
install missing applications, remove or autoremove packages, enable or restart
services, reboot, synchronize repositories, or use a generic GitHub binary
updater. DNF owns LazyGit and Starship; their upstream-documented third-party
COPRs participate in the ordinary DNF step rather than separate replacement
logic.

## Cargo binaries

`22.1.1` is the version of the **cargo-update program**, not the Fedora Cargo
toolchain version. The `cargo-update` package exports both
`cargo-install-update` and `cargo-install-update-config`; Cargo exposes the first
as the `cargo install-update` subcommand.

The clean-install Cargo inventory records reviewed, known installation routes;
its pins are not the routine update mechanism. `naldo-update` runs exactly
`cargo install-update -a` for locally installed crates.io binaries.
It never passes `--git` or its short form `-g`, so Git-originating packages
remain outside automatic maintenance.

The two Git-tagged editor tools use official upstream tagged sources and remain
deliberate manual exceptions. Their current recoverable installation commands
are:

```bash
cargo install --locked --git https://github.com/Myriad-Dreamin/tinymist.git --tag v0.15.2 tinymist-cli
cargo install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git --tag v0.25.12 markdown-oxide
```

Changing either tag is an occasional maintenance action: inspect the new stable
upstream tag and source, change the command deliberately, reinstall it, and then
check its Helix integration:

```bash
hx --health typst
hx --health markdown
```

## Herdr direct installation

Herdr's official Linux installer and `herdr update` both use the selected stable
channel. The installer writes only `${HERDR_INSTALL_DIR:-~/.local/bin}/herdr`;
it creates no package-manager database, installer state, or ownership marker.
The tracked `[update]` section leaves `channel` unset, whose Linux default is
`stable`. The reviewed clean-install procedure therefore writes a machine-local
receipt at:

```text
${XDG_DATA_HOME:-~/.local/share}/naldo/provider-receipts/herdr-official-installer
```

`naldo-update` runs `herdr update` only when that receipt exactly names the
official installer and the resolved `~/.local/bin/herdr`, and `herdr channel
show` reports `stable`. Installations without the receipt are skipped.
For a direct install, `herdr update` downloads beside the running executable,
checks a manifest SHA-256 when one is supplied, sets executable permissions, and
atomically replaces that executable; it writes no separate update database. The
update remains interactive and any failure propagates.
A protocol-changing update may require restarting the active Herdr session.
Follow Herdr's prompt because stopping a server also exits its pane processes.

Upstream documents installer-managed updates but no dedicated Linux
uninstaller. The exact inverse of the default installer is therefore removal of
`~/.local/bin/herdr`; remove the receipt at the same time. Herdr configuration,
logs, integrations, and persistent session state are separate and must not be
deleted as an implied binary uninstall.

## Pixi

Pixi is development-only and is not selected in the current inventory.
For a future installation made through Pixi's reviewed official installer at
`https://pixi.sh/install.sh`, use `pixi self-update`. Do not use that command for
a package-manager-owned Pixi, and do not add unconditional Pixi behavior to
`naldo-update` while Pixi is absent. The official installer places the binary at
`~/.pixi/bin/pixi`; upstream documents `rm ~/.pixi/bin/pixi` as its Linux
uninstall step.

## JetBrainsMono Nerd Font

The selected font is the official Nerd Fonts `v3.5.0` `JetBrainsMono.zip`
release. The reviewed base-family TTF files are user-owned under:

```text
~/.local/share/fonts/JetBrainsMonoNerdFont
```

For an occasional update, review a newer stable Nerd Fonts release, download
both `JetBrainsMono.zip` and its published `SHA-256.txt`, verify the archive,
inspect the embedded families with `fc-scan`, replace only the dedicated font
directory, and run:

```bash
fc-cache -f "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
```

Verify the exact configured family rather than a fontconfig fallback:

```bash
fc-list --format='%{family}\n' | awk -F ',' '
  { for (i = 1; i <= NF; i++) { value = $i; sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); if (value == "JetBrainsMono Nerd Font") found = 1 } }
  END { exit !found }
'
```

To remove it, delete only
`~/.local/share/fonts/JetBrainsMonoNerdFont` and refresh fontconfig. The font
does not need daily automatic updates.
