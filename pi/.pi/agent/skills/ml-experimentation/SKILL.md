---
name: ml-experimentation
description: Design, implement, audit, or interpret rigorous ML experiments. Use for hypotheses, splits, baselines, metrics, ablations, and reproducibility.
compatibility: Works with Python ML stacks and local or compute-cluster experiments.
---

# Rigorous ML Experimentation

## Start With the Claim

Write these before choosing a model:

- **Question:** what uncertainty should the experiment reduce?
- **Hypothesis:** what directional result is expected, and why?
- **Disconfirmation:** what outcome would change the belief?
- **Estimand:** exactly what quantity or comparison is being estimated?
- **Unit:** example, subject, sequence, dataset, run, or task?

## Design Checklist

### Data

- provenance, license, inclusion/exclusion rules
- train/validation/test split unit
- duplicates, temporal leakage, subject leakage, preprocessing leakage
- class imbalance and subgroup coverage
- distribution shift expected at deployment

### Comparisons

- trivial or majority baseline
- established classical baseline
- strongest practical baseline
- parameter/compute/data-matched comparison when relevant
- oracle or upper-bound diagnostic if available

Do not give the proposed method privileged tuning or compute.

### Measurement

- primary metric chosen in advance
- secondary/diagnostic metrics
- metric direction and practical effect size
- confidence intervals or variation across independent runs
- aggregation level and treatment of failed runs
- calibration, robustness, or subgroup metrics when relevant

### Ablations and Controls

Each ablation should answer a named causal question. Include negative controls and label/data sanity checks where possible. Avoid a table of component removals with no interpretation plan.

## Implementation Stages

1. deterministic data-path smoke test
2. one-batch forward/backward test
3. tiny-subset overfit
4. end-to-end baseline
5. proposed method at small scale
6. seed sweep and ablations
7. final held-out evaluation exactly once when feasible

Log configuration, code revision, environment, seed, runtime, and metrics in a machine-readable form.

## Interpretation

Separate:

- direct observations
- statistical uncertainty
- mechanism hypotheses
- external-validity claims
- speculation

A null result may indicate no effect, low power, poor measurement, or an implementation failure. Diagnose these alternatives rather than declaring victory or defeat immediately.

## Failure Modes to Audit

- target leakage or test-set feedback
- adaptive metric selection
- weak or under-tuned baselines
- seed cherry-picking
- non-independent samples treated as independent
- preprocessing fitted on all data
- mismatched compute budgets
- silent failed runs
- evaluating a proxy that does not support the stated claim
- claiming biological or cognitive relevance from architectural analogy alone

## Deliverable

Produce a compact experiment card containing hypothesis, data/splits, models, metrics, ablations, seed policy, compute budget, exact commands, expected plots, stop/go criterion, and known risks.
