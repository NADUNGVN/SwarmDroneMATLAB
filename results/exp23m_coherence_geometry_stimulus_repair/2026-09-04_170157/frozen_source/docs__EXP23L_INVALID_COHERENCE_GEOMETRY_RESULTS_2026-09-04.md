# EXP23L — Invalid coherence geometry-kernel results

Run: `results/exp23l_coherence_geometry_kernel/2026-09-04_165837`

Status: **invalid because the predeclared selector-stimulus gate failed**.

## What passed

The study completed all 400/400 unique rows over 100 fresh seeds, N5/N10 and
paired low/high uncertainty. Fourteen of fifteen gates passed:

- zero sampled actual-graph subset violations;
- zero same-color actual conflicts;
- zero horizon-monotonicity violations;
- high uncertainty never selected a longer horizon than low uncertainty;
- every issued horizon had witness, payload and slot feasibility;
- uncovered cases issued no positive lease;
- bounded motion never self-revoked and every injected acceleration-bound
  violation did self-revoke;
- deterministic reproduction and causal-information checks passed.

These observations are retained as diagnostics but are not promoted as a
valid kernel result because the complete study gate failed.

## Why the run is invalid

The frozen stimulus gate required all three selector outcomes: target horizon
6.8 s, a contracted positive horizon, and no lease. The observed counts were:

- target horizon: `0` rows;
- contracted positive horizon: `313` rows;
- no lease: `87` rows.

With random mobile geometry and only 1.5 m management reach, every 6.8 s
potential-conflict supergraph contains at least one edge that cannot be locally
witnessed. The matrix therefore never exercised the positive long-coherence
branch that motivated the adaptive selector.

## Repair

The repair must add a predeclared static/wide-reach coherence cell while
retaining mobile limited-reach low/high-uncertainty cells. It uses disjoint
fresh seeds. The target branch is expected to activate only in the first cell;
the other two preserve contraction and no-lease pressure. No graph rule,
reachable-tube equation, selector rule, self-revocation rule or gate threshold
is changed.

