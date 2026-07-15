---
name: scientific-python
description: Build, debug, test, or review scientific Python. Use for NumPy, SciPy, matplotlib, PyTorch, JAX, scikit-learn, environments, and reproducibility.
compatibility: Prefers uv; use pixi for native, CUDA, conda-style, or cross-platform environments.
---

# Scientific Python

## Inspect Before Choosing Tooling

Look for, in order:

- `pixi.toml` / `pixi.lock`
- `pyproject.toml` / `uv.lock`
- an existing virtual environment and documented commands
- test, lint, and type-check configuration

Do not introduce a second environment manager without a concrete reason. Do not install into system Python.

For a greenfield ML environment, choose a Python version supported by the actual numerical stack. The newest system Python may be ahead of binary wheels; Python 3.12 is a conservative baseline when dependency support is uncertain.

## Implementation Standard

- Prefer small functions with explicit inputs and outputs.
- Add type hints where they clarify array, config, or return structure.
- Make shapes, dtypes, devices, units, and missing-value policy explicit.
- Use `numpy.random.default_rng(seed)` rather than hidden global NumPy RNG state.
- Pass randomness into functions when practical.
- Separate pure computation from I/O, plotting, and CLI parsing.
- Use vectorization when it improves clarity; do not force it when a loop expresses the algorithm better.
- Avoid notebooks as the only reproducible artifact; move reusable logic into `.py` files.

## Numerical Reasoning

Check:

- conditioning and scale
- overflow/underflow and stable log-space forms
- absolute versus relative tolerances
- integer versus floating-point division
- broadcasting and accidental rank changes
- in-place mutation and aliasing
- CPU/GPU transfers and dtype mismatch
- whether a reduction should be a sum or a mean

Use assertions for invariants and tiny arrays with known answers.

## ML Debugging Ladder

Before a long training run:

1. inspect one batch and its labels
2. assert shapes, ranges, dtypes, and devices
3. run one forward pass and verify finite outputs
4. run one backward pass and inspect gradient presence/norms
5. overfit a tiny subset
6. compare against a trivial baseline
7. only then scale data, model, and compute

For stochastic results, distinguish a reproducibility seed from an experimental seed sweep. Report variation across repeated runs when it affects the claim.

## Environment Commands

Typical `uv` workflow:

```bash
uv sync
uv run pytest
uv run ruff check .
uv run python scripts/run_experiment.py --seed 0
```

Typical `pixi` workflow:

```bash
pixi install
pixi run test
pixi run experiment --seed 0
```

Use only commands supported by the existing project configuration.

## Completion Checklist

- smallest relevant tests pass
- a representative command runs from a clean environment
- seeds/configuration are visible
- failures are explicit rather than silently coerced
- plots have labels, units, legends, and reproducible inputs
- dependency and lock files agree
- generated artifacts are written to the documented output directory
