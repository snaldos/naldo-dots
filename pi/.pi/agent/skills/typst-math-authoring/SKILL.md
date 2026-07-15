---
name: typst-math-authoring
description: Create, edit, structure, or debug Typst documents with native mathematics. Use for .typ notes, derivations, reports, templates, and compile errors.
compatibility: Requires the Typst CLI for validation; optimized for Typst 0.15 or later.
---

# Typst Math Authoring

## Before Editing

1. Inspect the target `.typ` file, nearby imports, and the project's `lib.typ`.
2. Determine the compilation root and the command already documented by the project.
3. Reuse established document styles and notation.
4. Add a macro only after repeated structure makes it worthwhile.

Do not transliterate LaTeX mechanically. Typst has its own syntax and content model.

## Mathematical Syntax

Prefer Typst-native forms:

```typst
$sum_(i=1)^n x_i$
$integral_a^b f(x) dif x$
$nabla_theta cal(L)(theta)$
$partial f / partial x$
$mat(1, 2; 3, 4)$
$vec(x_1, x_2, x_3)$
```

Rules to remember:

- Multi-letter identifiers are interpreted compositionally; quote prose: `$x " is natural"$`.
- Use `op("softmax")`, `op("argmin")`, or another custom operator only when needed.
- Use `&` for alignment points and `\` for equation line breaks.
- Use `$dif x$` for differentials.
- Prefer built-in symbols such as `nabla`, `partial`, `integral`, `in`, `subset`, `RR`, and `NN`.
- Keep notation semantically consistent across prose, equations, figures, and code mappings.

## Document Structure

For study notes, prefer:

1. learning goals or motivating question
2. intuition
3. definitions
4. propositions/theorems with hypotheses
5. derivations or proof sketches
6. examples and counterexamples
7. exercises or active-recall prompts
8. implementation/ML connections when relevant

For a small new project, start with `main.typ`, optionally `lib.typ`, and a short `README.md`. Split files only after the document has a real chapter boundary.

## Macro Discipline

A good macro:

- removes repeated visual/semantic structure
- has a small, predictable interface
- uses content arguments rather than stringly typed markup
- compiles in a minimal example

Avoid a large theorem framework or notation layer for one short note.

## Validation

After every meaningful edit, compile to a temporary output so generated PDFs do not pollute the repository:

```bash
out="$(mktemp --suffix=.pdf)"
typst compile --root . path/to/note.typ "$out"
rm -f "$out"
```

Use the project's documented root if it is not `.`. Read the complete diagnostic, fix the first root cause, and compile again. Also inspect the rendered PDF when layout—not just syntax—matters.

Before finishing, check:

- every changed entry document compiles
- imports resolve from the intended root
- equations fit and align
- references/labels resolve
- quoted words and custom operators render correctly
- no generated PDF was accidentally added to source control
