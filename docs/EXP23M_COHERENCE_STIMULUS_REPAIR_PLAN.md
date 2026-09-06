# EXP23M — Coherence geometry stimulus-repair plan

Status: frozen before fresh-seed execution on 2026-09-04.

## Repair scope

EXP23L was invalid only because its randomized limited-reach matrix produced
no maximum-horizon selection. EXP23M adds the missing positive-control regime
and otherwise preserves the same geometry kernel and decision rules.

## Frozen matrix

- 100 disjoint fresh seeds `16075001:16075100`.
- N=5 and N=10.
- Three conditions:
  1. static, low uncertainty, complete management reach;
  2. mobile, low uncertainty, 1.5 m management reach;
  3. mobile, high uncertainty, 1.5 m management reach.
- Candidate horizons `[0.25, 0.5, 1, 2, 4, 6.8]` s.
- 600 rows.

All conditions share the same base positions and random directions within a
seed/size group. The static cell sets nominal speed and actual acceleration to
zero; it changes the intended operating regime rather than modifying the
selector.

## Required outcome

All EXP23L mathematical, safety, feasibility, determinism and causal gates
remain. In addition, the stimulus gate requires at least one target-horizon,
one contracted-horizon and one no-lease row; the static/wide cell must choose
6.8 s in every row; and mobile high uncertainty may never select a longer
horizon than paired mobile low uncertainty.

A pass validates only the geometry/coherence layer and permits distributed
ELCS-W integration. It does not establish closed-loop performance, robustness
or a submission claim.

