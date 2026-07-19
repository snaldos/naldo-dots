# Naldo's Pi configuration

A quiet, scientific Pi harness for a Tübingen machine-learning master's workflow: mathematics, tutoring, Typst, scientific Python/ML, paper work, neuroscience/cognition, and an Arch Linux workstation.

## Architecture

| Layer | Responsibility | Loaded when |
| --- | --- | --- |
| `AGENTS.md` | Stable personal, mathematical, scientific, and safety defaults | Every session |
| `skills/` | Detailed domain workflows | On a matching task or `/skill:<name>` |
| `prompts/` | Explicit task modes | Only when invoked |
| `extensions/ui.ts` + `extensions/lib/{pi-buddy,terminal-cursor}.ts` | Claude-inspired welcome dashboard, π mascot, hardware-cursor composer, `/pi-buddy`, responsive status, and runtime presentation | TUI startup and `/pi-buddy` |
| `extensions/codex-usage/` | On-demand Codex allowance cache, `/usage`, and deliberate usage reset-card flow | Only `/usage`, reset-card actions, and `/doctor` |
| `extensions/safety-guard.ts` | High-impact and per-sudo approval gate with direct native-terminal authentication and process-scoped YOLO mode | Every tool call |
| `extensions/doctor.ts` | Read-only runtime and integration diagnostics | `/doctor` |
| `extensions/herdr-agent-state.ts` | Herdr-managed lifecycle state | Every Herdr-managed session |
| project `AGENTS.md` / `.pi/` | Repository-specific source-of-truth and deterministic workflows | Only after project trust |

Global extensions do not inspect learning-roadmap files. The learning repository owns `/focus` and `/check`.

## UI

### Startup

`quietStartup` suppresses Pi's version/model/resource inventory. Each session selects one vetted Typst formula and one German/English learning pair; thoughts and other diversions stay on demand in `/pi-buddy`.

At 88 columns and wider, startup uses a centered Claude-inspired dashboard with two-cell outer margins:

```text
  ╭─ π 0.80.7 ───────────────────────────────────────────────────────╮
  │                          │                                      │
  │   Welcome back, Naldo!   │ DEUTSCH  Der Beweis beginnt mit ... │
  │                          │ ENGLISH  The proof begins with ...   │
  │      ███████████         │                                      │
  │     ███■█████■███        │ ──────────────────────────────────── │
  │       █████████          │ TYPST    $nabla_theta L(theta) = 0$  │
  │       ███   ███          │ ──────────────────────────────────── │
  │      ████   ████         │ DISCOVER /usage · /safety · ...     │
  │                          │                                      │
  ╰──────────────────────────────────────────────────────────────────╯
```

The top label contains only Pi and its version. The left column centers a solid `accent`-colored π pet with true-black block eyes and a welcome; the old subject/location labels are gone. The right column aligns one curated German/English pair, one literal compilable Typst expression, and concise discoverability. Outer margins, cell padding, and the column separator are symmetric. Below 88 columns this becomes a compact aligned list.

German pairs are curated together, and header formulas come from a width-safe subset of the validated Typst collection. Both are selected once per session, never during rendering, so the dashboard does not flicker. Runtime information remains in the status line. The terminal title remains `π · <project>`.

### Composer

`ui.ts` installs a custom `CustomEditor` wrapper:

- one full-terminal-width open composer with horizontal rules only
- `π ask`, `π compose`, `π steer`, `π tools`, or `π shell` in the top rule
- no vertical box sides, so copied prompts never include `│` characters
- no prompt glyph inside the typing area and no help text beside the cursor
- terminal-native cursor rendering: Pi's position marker is retained, its reverse-video fake cursor cell is removed while focused, unfocused modal composers suppress the remaining software cursor, and the visible hardware cursor is enabled
- rule color retains thinking-level and bash-mode semantics
- clean multiline input and an integrated open autocomplete section
- a full-width lower rule, preserving a clear input boundary without vertical copy artifacts

Discoverability lives in the header and `/hotkeys`, not inside the composer. Pi's built-in `Ctrl+T` collapses or expands model thinking blocks; `Shift+Tab` still changes the thinking level.

### Pi Buddy

`/pi-buddy` opens one random, curated diversion immediately above the composer. The π pet remains in a left column while the right column presents one of:

- a German sentence or saying, English translation, and language note;
- valid Typst math, its meaning, and a syntax note;
- a carefully qualified concept, theorem, or law from mathematics, statistics, ML, physics, or neuroscience;
- an explicitly unattributed local thought;
- interactive rock–paper–scissors (`r`, `p`, or `s`); or
- an anime recommendation with a short rationale and no claim about current streaming availability.

`/pi-buddy german|typst|concept|quote|rps|anime` selects a category without creating more slash commands; no argument chooses randomly and avoids repeating the previous random category. `n` advances, Escape closes, and `q` does nothing. Cards leave a constant two-row gap before `π ask`.

Ambient animation is not implemented by Pi. Ghostty owns independently configurable background, cursor, and combined shaders through its machine-local active chain, keeping graphics and animation outside Pi's input/render loop.

### Persistent status

`ui.ts` restores the complete information set from Pi's built-in footer, then adds project and Git context. Subscription allowance is deliberately absent; `/usage` owns it.

```text
π  GPT-5.6-SOL · max  ~/…/learning  main !3 ?1  ctx 18% · 67k/372k  ↑12.4k ↓3.1k R45k W0 CH78% $0.1234
```

At 100 columns and wider the token metrics share the primary line with the other status segments. Narrow terminals retain a second accounting line rather than hiding data. `↑` and `↓` are total input/output tokens on the active branch, `R` and `W` are cache read/write tokens, `CH` is the latest response's cache-hit rate, and `$` is total reported model cost.

- project and full model/thinking identity remain high priority;
- the working directory abbreviates `HOME` to `~` and collapses safely at medium widths;
- `!3` means three tracked changed paths and `?1` means one untracked path;
- context shows both percentage used and current/max tokens;
- context becomes warning-colored at 70% and critical at 85%;
- a session name appears when set;
- reasoning, active tools, and approval state temporarily displace lower-priority segments;
- disabled safety is always visible as a red `YOLO` segment;
- the Nerd Font `` separator gives powerline structure without opaque background blocks.

The footer performs no process or account request while rendering. `extensions/lib/git-status.ts` owns one asynchronous Git snapshot per session: recursive watches on Git metadata react to stage, reset, commit, checkout, stash, rebase, and related actions; every completed agent tool and a delayed user-shell hint request worktree refreshes; and a slow five-second poll recovers from dropped watcher events or external file changes. Updates are debounced, stale command results are discarded, and each changed snapshot explicitly requests a TUI render. Token and context values still come directly from the active session branch.

### Noctalia semantics

`themes/noctalia.json` is generated from `~/.config/noctalia/templates/pi-noctalia.json`. Durable changes belong in the template and are applied after `noctalia msg config-reload` with `noctalia msg templates-apply`.

The revised mapping makes `dim` as readable as Material `on_surface_variant`, strengthens editor/code-block borders, raises user/custom/tool surfaces, and gives blockquotes a visible secondary accent. Important custom UI never uses nearly invisible gray.

| Role | Theme token | Noctalia color |
| --- | --- | --- |
| Identity, frame, normal context | `accent` / `borderAccent` | `#7aa2f7` |
| Primary information | `text` | terminal foreground `#c0caf5` |
| Readable metadata | `muted` | `#9aa5ce` |
| Normal allowance/success | `success` | `#9ece6a` |
| Elevated context/allowance and approval | `warning` | `#bb9af7` |
| Critical context/allowance, denied operations, and YOLO mode | `error` | `#f7768e` |
| Progress-bar remainder only | `border` | `#586691` |

Against the Noctalia background `#1a1b26`, all required text colors have at least 6.46:1 contrast; only nonessential borders use lower-contrast colors.

## Commands and skills

### Global prompt templates

`/coach`, `/derive`, `/proof-review`, `/mental-model`, `/oral-exam`, `/python`, `/data-analysis`, `/experiment`, `/paper`, `/typst-notes`, `/write`, and `/verify` are narrow entry points. They complement rather than duplicate the detailed skills.

The 11 focused skills are:

- mathematics and learning: `mathematical-reasoning`, `study-coach`
- writing and Typst: `typst-math-authoring`, `academic-writing`
- Python, statistics, and ML: `scientific-python`, `statistical-data-analysis`, `ml-experimentation`
- research sources: `paper-reading-reproduction`, `scientific-documents`
- cognition: `computational-neuroscience`
- workstation: `linux-research-workflow`

There is no umbrella research skill, generated project scaffold, custom compaction policy, automatic session naming, or autonomous agent loop.

### Extension commands

| Command | Purpose |
| --- | --- |
| `/usage [refresh\|cached\|verbose\|resets\|reset <n>\|help]` | Inspect subscription allowance and deliberately preview/apply usage reset cards |
| `/pi-buddy [german\|typst\|concept\|quote\|rps\|anime]` | Open one random or selected π-pet learning/game/recommendation card |
| `/safety [on\|off\|toggle\|status]` | Toggle the high-impact gate; no argument toggles and `off` is full YOLO for this Pi process |
| `/doctor [verbose]` | Validate runtime, privacy, tooling, trust, and allowance access; `verbose` lists every resource command |

Use built-in `/hotkeys`, `/model`, `/compact`, and `/reload` for behavior Pi already owns.

## Codex allowance

The installed Codex CLI app-server is started over stdio. Allowance reads use:

```text
account/rateLimits/read
```

A usage reset card is applied only after interactive preview and fresh revalidation with the installed experimental method:

```text
account/rateLimitResetCredit/consume
```

### Presentation

`/usage` renders a centered-width Noctalia card as a widget immediately above the composer. The composer and status bar stay visible, while a transparent one-cell focus proxy captures modal keys. This avoids a detached screen-center dialog and keeps placement constant relative to the input area.

The card shows used and remaining percentages, relative and exact reset times, plan, refresh timestamp, usage reset-card count, and add-on credits when present. Controls are deliberately unambiguous:

- `v` toggles protocol details
- `r` opens usage reset cards
- Escape is the sole normal close/back/cancel key
- Enter is reserved for selecting or applying a reset card
- `q` has no navigation behavior

Allowance is on demand rather than a background footer service:

- `/usage`, `/usage verbose`, `/usage resets`, and `/usage reset <n>` perform a fresh read;
- successful reset-card application performs an immediate follow-up read;
- `/usage cached` reuses only a snapshot already fetched in the current session;
- stale and unavailable states remain explicit inside the card;
- no account request occurs at startup, after normal turns, during rendering, or while typing.

### Usage reset cards

`/usage resets` retrieves a fresh, stable numbered list. `/usage reset <n>` opens the corresponding preview directly. A card is selectable only when its in-memory row is available, unexpired, and has the supported `codexRateLimits` effect.

Before application the integration retrieves another fresh snapshot and confirms the same opaque ID, title, description, grant time, expiry, status, and effect. The preview states that both five-hour and weekly allowance will reset and that consumption is irreversible.

Application uses a fresh UUID idempotency key. A timeout/unavailable/protocol failure receives one safe retry with the same key. `reset` and `alreadyRedeemed` are explicit successful outcomes; `nothingToReset` and `noCredit` are shown as non-success. Double input and concurrent applications are suppressed. After confirmed success, a new rate-limit read updates the allowance card and its current-session cache.

Opaque card IDs and idempotency keys remain only in memory. They are never rendered, logged, cached on disk, or persisted into a session.

### Boundaries

- This is ChatGPT/Codex subscription allowance, not OpenAI API billing.
- It reflects the local Codex CLI login, which can differ from Pi's login.
- Pi 0.80.7 has no dedicated subscription-allowance API.
- The Codex app-server is maintained by OpenAI but currently experimental, so schema, timeout, stale, and unavailable states remain explicit.
- There is no dashboard scraping, credential parsing, secret logging, or on-disk cache.
- The consume method is never called from startup, status rendering, normal `/usage`, tests, or without deliberate interactive confirmation.
- Validation uses fake app-server processes; no real usage reset card is consumed for testing.

## Safety policy

`safety-guard.ts` is intentionally permissive for ordinary work. It does not police ordinary autonomy, workspace scope, or reversibility. The classifier looks for a small set of high-impact boundaries plus explicit privilege elevation. Ordinary matches can be approved once. Non-fixed or interactive sudo invocations, agent-side password routing, sudo timestamp invalidation, and unsupported interactive `doas` authentication are blocked rather than delegated to an untrusted command path.

### Silent normal work

Normal work is silent regardless of whether it stays below the active directory. This includes project and dotfile edits, local cleanup, redirections, permission changes, user services, HTTP requests, project dependency changes, and routine Git inspection/staging/fetching/switching/stashing. `rm`, `curl`, writing outside the repository, and an unresolved path are not prompts by themselves.

Metadata-only inspection of a private path with `stat`, `ls`, `file`, `test`, `readlink`, or a SHA command is also silent. Content access to an actual credential, private key, or private session remains a high-impact boundary. Accepted `/usr/bin/sudo -n` and `/usr/bin/sudoedit -n` invocations are the deliberate exception to keyword-silent operation and receive exact per-tool-call approval.

### Confirmation

One precise confirmation covers one tool call. The default gate asks only for:

- every accepted fixed-binary, noninteractive sudo invocation, even when the credential timestamp is already valid
- mutation of system, boot, kernel, device, authentication, privilege, or package-managed paths
- broad deletion of `/`, the home directory, or the active workspace root
- system/AUR/desktop package install, remove, or upgrade transactions; project-local dependency changes stay silent
- system services, disk/filesystem/boot state, kernel settings/modules, networking/remote-access state, power, or login/desktop termination
- Git history changes, pushes, destructive cleanup/restore, ref/config/worktree metadata changes, or direct mutation below `.git`
- credential/private-session disclosure or mutation, downloaded code piped into a shell, infrastructure mutation, and publication

Approval and authentication remain separate. Agent tool calls must spell elevation as `/usr/bin/sudo -n` or `/usr/bin/sudoedit -n`; the absolute path prevents PATH/function substitution and `-n` guarantees that the later tool process cannot read a password. After approval, the extension checks `/usr/bin/sudo -n -v`. If authentication is needed, interactive Pi suspends its TUI and launches the fixed `/usr/bin/sudo -v` binary with inherited terminal I/O. The user types into sudo's native hidden prompt; Pi then resumes and revalidates that the approved noninteractive tool call can reuse the credential. Cancellation, failed authentication, a non-reusable timestamp policy, or a required prompt outside TUI mode blocks the command.

The password never enters model context, tool arguments, JavaScript input strings, environment variables, shell history, Pi sessions, or extension logs. Bare/path-resolved `sudo`, missing `-n`, `sudo -S`/`--stdin`, `sudo -A`/`--askpass`, and `sudo -k`/`-K` timestamp-invalidating forms are blocked while guarded. The extension never configures `NOPASSWD` and never asks the model to carry a secret.

Dialogs show the risk, resolved target when available, expected effect, and exact command. High-impact operations fail closed in print/JSON mode because no confirmation UI exists. Sudo authentication additionally fails closed outside the interactive TUI unless a noninteractive credential is already valid.

### YOLO mode

`/safety` toggles the gate. `/safety off` enables full YOLO for the current Pi process, `/safety on` restores it, and `/safety status` reports it. `--yolo` starts Pi with the gate off; `PI_SAFETY_GUARD=off` is the equivalent environment override. Runtime toggles survive `/reload` and session switches in the same process, but not a fresh Pi launch. A red `YOLO` footer segment remains visible while disabled.

## Herdr

Herdr uses `host_cursor = "native"`, while its forced hidden-cursor reveal remains disabled. Pi's focus-aware hardware-cursor support exposes Ghostty's real cursor in the composer and hides it for modal widgets and popups, preventing a second cursor at the pane's right edge. `herdr-agent-state.ts` remains generated and unchanged. The safety guard is the sole tool-confirmation source. It emits `herdr:blocked` only while an actual approval dialog or native sudo authentication prompt is open; silent work and YOLO mode create no permission-wait noise. A per-tool-call decision cache suppresses duplicate dialogs, and every `finally` path clears Herdr state.

## Runtime and private state

- Default model: `openai-codex/gpt-5.6-sol`, thinking `max`; thinking blocks are visible by default and toggle with `Ctrl+T`.
- Auto-compaction: 65,536-token response reserve and 40,000 recent tokens.
- Project trust default: `ask`.
- Neovim: `Ctrl+G` via `env SHELL=/bin/bash nvim`.
- Fish exports `PI_CACHE_RETENTION=long`.
- Ghostty forwards `Alt+Backspace` for Pi's editor.
- Inline terminal image previews are hidden to avoid invisible reserved rows under post-processing shaders; images remain available to the model (`images.blockImages` stays false).

Machine-local state remains ignored and private:

```text
auth.json
agent.db*
trust.json
sessions/
git/
npm/
logs/
```

Pi state directories are `0700`; credential/database/trust/session files are `0600`. Do not print, copy, commit, or share their contents.

## Project trust and reload

1. Review a repository's `AGENTS.md` and `.pi/` resources.
2. Approve only trusted projects.
3. Restart Pi after a new trust decision.
4. Use `/reload` after later edits to an already trusted project.

For `/home/naldo/projects/learn/learning`, project resources own `/start`, `/exercise`, `/diagnostic`, `/finish`, `/weekly-review`, `/focus`, `/check`, and `learning-workspace`.

## Validation

```bash
jq empty ~/.pi/agent/settings.json \
  ~/.pi/agent/keybindings.json \
  ~/.pi/agent/themes/noctalia.json \
  ~/.pi/agent/trust.json

node --test ~/.pi/agent/extensions/lib/{git-status,safety-classifier,safety-guard}.test.ts
pi --no-approve --list-models
fish -n ~/.config/fish/config.fish
ghostty +validate-config --config-file=~/.config/ghostty/config.ghostty
nvim --headless '+qa'
herdr integration status
```

Use `/doctor`, `/check`, classifier fixtures, and actual narrow/wide TUI captures for integrated validation. No configuration task should rewrite credential/database/session payloads or the Herdr-managed extension.
