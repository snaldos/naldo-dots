---
name: typst-math-authoring
description: Create, edit, structure, or debug Typst documents with native mathematics. Use for .typ notes, derivations, proofs, equations, geometric figures, curves, and ML math.
compatibility: Requires the Typst CLI for validation and uses the official live documentation when network access is available.
---

# Typst Math Authoring

## Guiding Principle

Treat Typst as the medium for real mathematical writing, not as a separate learning exercise. Preserve the mathematical intent, source status, and the user's own reasoning; improve notation and structure without inventing proofs or claims.

## Before Editing

1. Inspect the target `.typ`, nearby imports, the shared `lib.typ`, and the nearest README.
2. Determine the project root and its documented compile command.
3. Check `typst --version` before relying on version-sensitive APIs or packages.
4. Reuse the existing document template and notation before adding helpers.
5. Add a macro only after a visual or semantic pattern genuinely repeats.

## Live Documentation

Use the official live reference at <https://typst.app/docs/reference/> as the primary API source. Start from its navigation, open only pages relevant to the task, and follow related links under `/docs/reference/`, `/docs/guides/`, or `/docs/changelog/` rather than relying on a cached PDF or model memory.

The pages are server-rendered and can be fetched when direct web tooling is unavailable:

```bash
workdir="$(mktemp -d)"
url="https://typst.app/docs/reference/visualize/curve/"
curl -LfsS --max-time 30 "$url" -o "$workdir/page.html"
pandoc -f html -t plain "$workdir/page.html" -o "$workdir/page.txt"
# Inspect page.txt, then remove the temporary directory.
```

If Pandoc is unavailable, inspect the server-rendered HTML directly with text-search and file-reading tools. Check `typst --version` against the live documentation and changelog. The website may document a newer release than the installed CLI; if a feature fails locally, verify version availability rather than rewriting blindly or updating Typst without permission. Cite the exact documentation URLs inspected, do not crawl the whole site, and do not persist documentation copies in a project.

## Document Structure

Use one document title supplied by the shared template; level-1 headings are sections, not a second title. Prefer topic-based filenames such as `elementary-geometry.typ` or `chain-rule-and-gradient-descent.typ`, not source titles or `first-note.typ`.

A mathematical note may contain:

- a motivating question or intuition
- definitions with domains and assumptions
- a proposition or theorem with all hypotheses
- a derivation or proof whose status is explicit
- examples, counterexamples, and edge cases
- geometric diagrams or tensor-shape maps when they clarify the argument
- open questions that are clearly marked as open

This is a menu, not a mandatory outline. Split files only at a real mathematical boundary.

For a project template function, prefer the native whole-document pattern:

```typst
#import "../lib.typ": math-note

#show: math-note.with(
  title: [Descriptive title],
  subtitle: [Optional scope],
)
```

## Typst-Native Mathematics

```typst
$sum_(i=1)^n x_i$
$integral_a^b f(x) dif x$
$nabla_theta cal(L)(theta)$
$partial f / partial x$
$mat(1, 2; 3, 4)$
$vec(x_1, x_2, x_3)$
```

- Use `$...$` inline and `$ ... $` for a displayed equation.
- Quote prose and multi-letter literal text in math: `$x " is feasible"$`.
- Use `op("softmax")`, `op("argmin")`, or another custom operator only when needed.
- Use `&` for alignment points and `\` for equation line breaks.
- Prefer built-in symbols such as `nabla`, `partial`, `integral`, `dif`, `angle`, `RR`, and `NN`.
- Label important equations and refer to them instead of writing brittle manual numbers.
- Do not mechanically transliterate LaTeX; Typst has markup, code, content, and math modes with different syntax.

For ML mathematics, state tensor shapes and reductions near the equations and keep names consistent with code. Distinguish definitions, proved statements, numerical checks, and empirical observations.

## Geometry, Curves, and Figures

Use native `circle`, `ellipse`, `line`, `polygon`, and `curve` for simple drawings. A native curve is built from `curve.move`, `curve.line`, `curve.quad`, `curve.cubic`, and `curve.close` segments. Use CeTZ or a specialized package only when coordinates, axes, labels, transformations, or reusable geometric construction justify the dependency.

Wrap a semantic drawing in a figure and make it understandable beyond its appearance:

```typst
#figure(
  polygon(
    fill: blue.lighten(85%),
    stroke: blue,
    (0%, 2cm), (20%, 0pt), (70%, 0pt), (100%, 2cm),
  ),
  caption: [A trapezoid used in the geometric argument.],
  alt: "A trapezoid with a shorter top edge and a longer bottom edge.",
) <fig:trapezoid>
```

Check the mathematical construction separately from visual plausibility. Keep labels legible, avoid decorative color maps for quantitative data, and inspect the rendered page for clipping and overlap.

## Validation

Compile every changed entry document to temporary output from the intended root:

```bash
out="$(mktemp --suffix=.pdf)"
typst compile --root . path/to/note.typ "$out"
rm -f "$out"
```

Fix the first root diagnostic, then recompile. Render and inspect relevant pages when changing layout, headings, equations, tables, figures, or curves. Before finishing, confirm imports, labels/references, equation fit, figure captions/alternative text, and that no generated PDF entered source control.
