# Machine profile

The active profile is machine-local and lives at:

```text
~/.config/naldo/machine-profile
```

It contains one value listed in `profiles`. `profile.default` is used only when
`install.sh` initializes a machine with no active or legacy profile. Override
that initialization explicitly with, for example:

```bash
MACHINE_PROFILE=desktop ./install.sh
```

Do not track the active file. Desktop and laptop can use the same local
`~/backups` path because each clone retains its own Git history and remote.
