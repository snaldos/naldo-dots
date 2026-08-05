---
name: vault-notes
description: Add, update, organize, or clean entries in Naldo's State Space knowledge vault. Use when the user asks to save something learned, add a quick note or reading item, update a living list, or maintain the vault.
compatibility: State Space at ~/Vaults/state-space; Markdown with optional Typst mathematics.
---

# State Space Notes

## Start

Use `~/Vaults/state-space` as the vault root. Read its `AGENTS.md`, `README.md`, and `Methods/State Space.md`, then inspect Git status before editing. Preserve existing work and never commit, synchronize, or run `sync.sh` unless explicitly requested.

## Route by purpose

- `Theory/`: durable explanations—what something is or why it works
- `Methods/`: reusable procedures—how to do something
- `State/Inbox.md`: an ambiguous or unprocessed quick capture
- `State/Today.md`: tasks intended only for today; reset after routing unfinished or reusable material
- `State/Reading/`: material to read and then delete
- `State/`: finite active state or an outcome with an end
- `Dynamics/`: lists, interests, and responsibilities expected to keep growing
- `Meta/`: attachments owned by State Space only

Prefer updating an existing entry over creating a near-duplicate.

## Add a quick note

When the user says they learned something and asks to save it:

1. Search for an existing entry on the topic.
2. Decide whether the material is an explanation, a method, temporary state, or a living process.
3. Add only what the user supplied or what can be checked; never invent a source or stronger claim.
4. Use one level-1 heading matching the filename, concise sections, and a final `Related` section only when links help.
5. Do not add tags, dates, templates, or frontmatter unless they serve a concrete purpose.

Treat existing files in `State/Reading/` as an opaque, user-owned queue. Do not summarize, rewrite, format, extract, move, or delete one unless the user explicitly asks to process that item. For a new URL, append a descriptive entry to an existing list note when one is clear; otherwise create `State/Reading/Reading List.md`.

## Finish

Format durable Markdown with Prettier, verify changed links, and compile changed Typst. Report the edited paths and checks performed.
