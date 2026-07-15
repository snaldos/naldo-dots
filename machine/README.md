# Machine profile

This GNU Stow package deploys:

```text
~/.config/naldo/machine-profile/
├── default    # tracked fallback: laptop
├── profiles   # tracked allowed values
└── profile    # optional machine-local override, ignored by Git
```

Resolution is `profile` when it exists, otherwise `default`. A fresh interactive
`./install.sh` prompts using `profiles`; scripts can select explicitly with:

```bash
./install.sh --profile desktop
```

Desktop and laptop can both use the local path `~/backups`: each clone retains
its own independent Git history and machine-specific remote.
