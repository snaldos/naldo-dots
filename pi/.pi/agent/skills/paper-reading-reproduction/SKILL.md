---
name: paper-reading-reproduction
description: Read, critique, and reproduce scientific or ML papers. Use for summaries, equations, notation maps, evidence audits, and implementation plans.
compatibility: Can use local PDFs and command-line extraction tools; never fabricates inaccessible sources.
---

# Paper Reading and Reproduction

## Evidence Discipline

State what source material was actually inspected. Never infer exact equations, datasets, numbers, citations, or conclusions from a title or memory alone.

Distinguish:

- what the paper proves
- what its experiments show
- what the authors conjecture
- what you infer independently
- what remains unknown because a source or appendix was unavailable

When possible, attach page, section, figure, table, or equation identifiers to important claims.

## Reading Passes

### Pass 1 — Orientation

Extract the problem, motivation, claimed contribution, evaluation setting, and one-sentence core idea.

### Pass 2 — Formal Core

Build a notation table:

| Symbol | Meaning | Domain/shape | First occurrence | Code analogue |
| --- | --- | --- | --- | --- |

List assumptions and derive the central objective or update rule. Fill omitted algebra explicitly and check dimensions.

### Pass 3 — Experimental Evidence

Record:

- datasets and split protocol
- models and training budgets
- baselines and their tuning fairness
- primary metrics and uncertainty
- ablations and negative results
- whether evidence supports each stated claim

### Pass 4 — Critique

Identify hidden assumptions, likely confounders, scope limits, missing controls, implementation ambiguities, and alternative explanations.

## Local PDF Workflow

If direct PDF reading is unavailable and `pdftotext` exists, extract a searchable copy without modifying the source:

```bash
pdftotext -layout paper.pdf /tmp/paper.txt
rg -n "keyword|Theorem|Algorithm|Ablation" /tmp/paper.txt
```

Use extraction only as an aid; tables, equations, and reading order may be corrupted. Inspect relevant rendered pages when exact layout matters.

## Reproduction Ladder

1. reproduce notation and tensor shapes
2. implement the smallest central mechanism
3. pass unit and toy-data checks
4. reproduce a trivial baseline
5. match one reported setting
6. compare curves and intermediate quantities, not only final metrics
7. document every deviation from the paper
8. run robustness checks or targeted ablations

Define success thresholds before looking at final results. Separate **reproduction** (same setup) from **replication** (independent implementation or setting).

## Output

A high-quality note contains:

- bibliographic/source information
- concise summary and claim-evidence table
- notation and shape map
- central derivation
- algorithm/pseudocode
- experimental protocol
- limitations and unresolved ambiguities
- minimal implementation plan
- follow-up keywords and papers that are clearly marked as verified or merely suggested
