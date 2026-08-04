---
name: statistical-data-analysis
description: Plan or perform rigorous statistical analysis. Use for datasets, EDA, estimands, uncertainty, regression, tests, missing data, and observational studies.
compatibility: Uses scientific Python and Typst-friendly statistical notation.
---

# Statistical Data Analysis

## Start With the Data-Generating Process

Before plotting or fitting a model, state:

- scientific question and decision to inform
- observational unit and sampling mechanism
- outcome, predictors, treatment/exposure, and possible confounders
- temporal order and dependence structure
- target population and estimand
- what causal language, if any, the design can support

Do not treat rows as independent merely because they are stored separately.

## Data Audit

Inspect and report:

- schema, units, ranges, dtypes, and category coding
- provenance, collection period, and inclusion/exclusion rules
- duplicate entities and repeated measurements
- missingness patterns and plausible mechanisms
- impossible values, censoring, truncation, and measurement error
- preprocessing learned from data and potential leakage

Preserve raw data. Make cleaning deterministic and auditable.

## Exploratory Analysis

Use plots and summaries to understand structure, not to manufacture a hypothesis after seeing outcomes. Prefer distributions, paired/within-group views, uncertainty, and raw observations over decorative aggregates.

For each plot, include labels, units, sample size/aggregation level, and uncertainty where appropriate. Distinguish a pattern in the observed sample from a population claim.

## Inference

- Define the estimand before selecting a test/model.
- Check model/test assumptions and practical robustness, not only a p-value.
- Report effect sizes and uncertainty intervals.
- Account for clustering, repeated measures, selection, and multiple comparisons.
- Distinguish confirmatory analyses from exploratory ones.
- Run sensitivity analyses for consequential modeling choices.
- Avoid causal conclusions from associational designs without explicit identification assumptions.

## Predictive Analysis

Use leakage-safe splits at the correct entity/time/group level. Fit preprocessing only on training data. Compare against a simple baseline and evaluate calibration and subgroup behavior when relevant.

## Reproducible Output

Produce:

- a data dictionary
- an explicit analysis plan
- deterministic cleaning code
- focused tables/figures with source commands
- assumptions and sensitivity checks
- a concise result statement separating observation, inference, and limitation

Use synthetic or tiny known-answer data to test transformations before applying them to the full dataset.
