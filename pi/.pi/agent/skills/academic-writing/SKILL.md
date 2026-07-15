---
name: academic-writing
description: Plan, draft, revise, or critique scientific prose. Use for reports, papers, theses, abstracts, captions, claims, and citations.
compatibility: Prefers Typst for mathematical/scientific documents and requires source-verifiable citations.
---

# Academic and Scientific Writing

## Argument Before Prose

For each section, identify:

- the question it answers
- the claim it advances
- the evidence supporting that claim
- the limitation or scope condition
- the transition to the next claim

Draft from this argument map rather than polishing sentences before the logic is stable.

## Evidence and Citation Hygiene

- Never fabricate references, authors, years, quotations, page numbers, or DOI data.
- Cite the source that actually supports the claim, not a nearby survey by convenience.
- Distinguish primary evidence from review/background material.
- Mark unverified citation placeholders explicitly.
- Avoid stronger causal or generalization language than the design supports.

## Scientific Structure

Use the structure appropriate to the artifact:

- **Abstract:** problem, gap, approach, key result, implication—without unsupported hype.
- **Introduction:** context, precise gap, contribution, scope.
- **Methods:** enough detail to reproduce, including data, splits, models, metrics, and statistics.
- **Results:** observations organized around questions, not a chronological lab diary.
- **Discussion:** interpretation, alternatives, limitations, and next tests.

For mathematical writing, state assumptions before results and keep notation consistent with code and figures.

## Revision Passes

1. **Logic:** does each conclusion follow from evidence?
2. **Structure:** one purpose per paragraph; clear topic and transition sentences.
3. **Precision:** replace vague nouns, dangling comparisons, and undefined terms.
4. **Compression:** remove repetition and throat-clearing.
5. **Figures/tables:** standalone captions, units, uncertainty, and readable labels.
6. **Reproducibility:** exact versions, settings, and evaluation protocol.
7. **Style:** grammar and rhythm only after substantive issues are fixed.

## Typst Workflow

Inspect the existing project and bibliography conventions. Keep content, notation, labels, and references reusable. Compile after edits and inspect the rendered artifact for equation overflow, figure placement, cross-references, and bibliography warnings.

## Review Output

When reviewing a draft, separate:

- blocking scientific/logic issues
- important clarity/structure issues
- local style edits
- optional polish

Give concrete revisions and preserve the author's intended claim when it is supportable.
