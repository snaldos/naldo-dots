---
name: mathematical-reasoning
description: Explain, derive, prove, refute, or check mathematics rigorously. Use for calculus, linear algebra, probability, optimization, and ML math.
compatibility: Uses Typst-friendly mathematics and optional Python checks.
---

# Mathematical Reasoning

## Establish the Task Mode

Infer or ask for one of these modes:

- **Explain** — intuition first, then definition and examples.
- **Derive** — expose every nontrivial algebraic or analytic step.
- **Prove/refute** — give a proof with explicit quantifiers, or a minimal counterexample.
- **Check** — preserve the user's approach and identify the first invalid step.
- **Coach** — use progressively stronger hints and do not reveal the full solution prematurely.

An explicit request for a full solution overrides coaching mode.

## Core Workflow

1. Restate the givens and the exact goal.
2. Declare domains, assumptions, regularity conditions, dimensions, and notation.
3. Give the geometric, probabilistic, or operational intuition.
4. Work formally in small justified steps.
5. Check edge cases, signs, units, dimensions, and limiting behavior.
6. Give one concrete example and, when informative, one counterexample.
7. State the final result compactly and explain why it matters.
8. Connect to ML or implementation only when the connection clarifies the mathematics.

## Proof Standard

- Make the direction of implication explicit, especially for `iff` statements.
- Expand hidden quantifiers and specify arbitrary versus chosen objects.
- Name the theorem used and check its hypotheses before applying it.
- Do not divide by a quantity before establishing that it is nonzero.
- Treat boundary cases separately when the argument assumes an interior point.
- In induction, state the proposition $P(n)$, base case, induction hypothesis, and induction step.
- In probability, name the probability space or conditioning assumptions when relevant.
- In optimization, distinguish local from global conclusions and necessary from sufficient conditions.
- A numerical or symbolic check can detect errors but does not replace proof.

## Typst-Friendly Notation

Write math that can be pasted into Typst:

```typst
$sum_(i=1)^n x_i$
$nabla f(x)$
$partial f / partial x$
$integral_a^b f(x) dif x$
$mat(1, 2; 3, 4)$
```

Use quoted words in math, such as `$x " is feasible"$`, and `op("argmin")` for custom textual operators. Avoid raw LaTeX commands unless the target requires LaTeX.

## ML Shape Discipline

For matrix calculus and probabilistic ML, annotate shapes before manipulating expressions. For example:

```text
X: B × D
W: D × K
Y = X W: B × K
```

Check that:

- additions combine equal shapes
- contractions sum over matching axes
- gradients have the shape of the differentiated variable
- scalar objectives specify sum-versus-mean reduction
- transposes are mathematically and programmatically consistent

## Solution Checking

When checking an attempt:

1. Summarize the approach charitably.
2. Mark the first incorrect or unjustified step, not merely the final mismatch.
3. Explain the misconception behind it.
4. Offer the smallest repair.
5. Recheck downstream work only after that repair.
6. Give a nearby transfer question if practice would help.
