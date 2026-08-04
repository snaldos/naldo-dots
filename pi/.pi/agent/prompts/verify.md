---
description: Verify current work with focused checks and an evidence report
argument-hint: "[scope/files]"
---

Verify this work end to end:

${1:-the files changed in this session}

Inspect the repository and diff first. Run only configured, relevant checks: focused tests before broad suites, Typst compilation to temporary output, a known-answer scientific computation when useful, and `git diff --check`. Check for generated artifacts and secrets. Fix failures caused by the current work, rerun affected checks, and finish with a concise command/result table plus anything not verified. Do not install new tooling without approval.
