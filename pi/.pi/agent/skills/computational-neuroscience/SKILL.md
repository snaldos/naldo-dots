---
name: computational-neuroscience
description: Analyze computational neuroscience, cognition, and brain-inspired ML. Use for neural coding, cognitive models, learning rules, and brain-AI claims.
compatibility: Supports mathematical modeling, paper analysis, and Python simulations.
---

# Computational Neuroscience and Cognition

## Separate Levels of Explanation

For every brain–AI connection, identify:

1. **Computational goal:** what problem is being solved and why?
2. **Algorithm/representation:** what information and update rule are used?
3. **Implementation:** what biological mechanism or hardware realizes it?
4. **Behavior:** what observable behavior is explained or predicted?

Similarity at one level does not imply similarity at the others.

## Evidence Ladder

Label claims as:

- mathematical consequence of a model
- simulation result
- behavioral evidence
- correlational neural evidence
- causal neural evidence
- anatomical/biophysical constraint
- analogy or speculation

Do not use architectural resemblance alone as evidence of biological plausibility.

## Modeling Workflow

1. define state variables, inputs, outputs, and timescale
2. state deterministic/stochastic dynamics
3. identify free parameters and observables
4. derive equilibria, stability, or expected behavior when possible
5. simulate the smallest informative case
6. compare model predictions with the relevant evidence
7. test parameter sensitivity and alternative mechanisms
8. state what observation would falsify the model

Use units and timescales explicitly. Distinguish population-level from single-neuron claims and normative from mechanistic models.

## Brain-Inspired ML Checklist

Ask:

- Is the inspiration a metaphor, inductive bias, objective, architecture, learning rule, or hardware constraint?
- Which biological constraints are retained or discarded?
- Does the idea improve performance, sample efficiency, robustness, interpretability, or scientific explanation?
- What non-neural baseline tests whether the biological ingredient matters?
- Can an ablation isolate the claimed mechanism?

## Communication

Start with an intuitive circuit or dynamical picture, then formalize using Typst-friendly notation, then connect equations to a minimal simulation. Include limitations and competing explanations rather than presenting one cognitive theory as settled fact.
