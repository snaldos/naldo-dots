---
name: vault-notes
description: Add, update, organize, or clean notes in Naldo's second-brain vault. Use when the user asks to save something learned, add a quick note or reading item, update an ongoing list, or maintain the vault.
compatibility: Vault at ~/Vaults/second-brain; Markdown with optional Typst mathematics.
---

# Vault Notes

## Start

Use `~/Vaults/second-brain` as the vault root. Read its `AGENTS.md`, `README.md`, and `Guides/Vault.md`, then inspect Git status before editing. Preserve existing work and never commit, synchronize, or run `sync.sh` unless explicitly requested.

## Route by purpose

- `Notes/`: durable explanations—what something is or why it works
- `Guides/`: reusable procedures—how to do something
- `Now/Inbox.md`: an ambiguous or unprocessed quick capture
- `Now/Reading/`: material to read and then delete
- `Now/`: finite active state or an outcome with an end
- `Ongoing/`: lists, interests, and responsibilities expected to keep growing
- `Meta/`: vault-owned attachments only

Prefer updating an existing note over creating a near-duplicate.

## Add a quick note

When the user says they learned something and asks to save it:

1. Search for an existing note on the topic.
2. Decide whether the material explains a thing, a procedure, temporary state, or an ongoing area.
3. Add only what the user supplied or what can be checked; never invent a source or stronger claim.
4. Use one level-1 heading matching the filename, concise sections, and a final `Related` section only when links help.
5. Do not add tags, dates, templates, or frontmatter unless they serve a concrete purpose.

Treat existing files in `Now/Reading/` as an opaque, user-owned queue. Do not summarize, rewrite, format, extract, move, or delete one unless the user explicitly asks to process that item. For a new URL, append a descriptive entry to an existing list note when one is clear; otherwise create `Now/Reading/Reading List.md`.

## Finish

Format durable Markdown with Prettier, verify changed links, and compile changed Typst. Report the edited paths and checks performed.
