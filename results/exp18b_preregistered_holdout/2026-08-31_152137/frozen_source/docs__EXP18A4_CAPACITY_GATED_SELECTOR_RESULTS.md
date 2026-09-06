# EXP18A4 capacity-gated selector development results

## Canonical result

- Run: `results/exp18a4_capacity_gated_selector_development/2026-08-31_125544`
- Matrix: 400/400 development trajectories
- Runtime: 3 min 20 s on 16 process workers
- Integrity: 14/14 gates, zero protocol violations
- Development decision: 6/6 gates
- Machine verdict: `READY_TO_PREREGISTER_FRESH_SEED_HOLDOUT`

This is a development verdict. It permits a fresh-seed preregistration; it is
not confirmatory evidence and does not authorize a hardware claim.

## What was selected

EXP18A4 removes the failed per-ACK marginal-value heuristic. The frozen route
is deliberately auditable:

```text
if analytical service screen is infeasible: piggyback-only
else if configured MAC is CSMA:            piggyback-only
else if configured MAC is ALOHA:           legacy adaptive feedback
```

The implementation exactly aliases its declared fixed comparator on all
400/400 rows and all 17 registered control/network fields. Feasible CSMA and
all infeasible cells alias frame-aware piggyback; feasible ALOHA aliases the
frame-aware adaptive route. The maximum registered difference is zero.

All 220 certificate-infeasible trajectories emit exactly zero standalone ACKs.
The feasible ALOHA trajectories retain 9,611 standalone ACK attempts, proving
that the implementation has not silently collapsed to piggyback-only.

## Service-screen calibration boundary

The screen compares an analytical per-node successful-DATA rate with the
existing AoI requirement `1/0.12 = 8.333 Hz`. The five feasible core
context--MAC cells are:

| Context | Access | Screen ratio | Observed DATA goodput per node | Failures | Selected route |
|---|---:|---:|---:|---:|---|
| N5 Moderate bg0 | CSMA | 2.942 | 11.302 Hz | 0/20 | piggyback |
| N5 Moderate bg0 | ALOHA | 1.156 | 8.592 Hz | 0/20 | adaptive |
| N5 Stressed bg0 | CSMA | 2.313 | 12.052 Hz | 0/20 | piggyback |
| N10 Moderate bg0 | CSMA | 1.421 | 11.278 Hz | 0/20 | piggyback |
| N10 Stressed bg0 | CSMA | 1.117 | 11.507 Hz | 0/20 | piggyback |

Every feasible cell mean is above the registered rate requirement. This does
not make the screen a trajectory-wise guarantee: 9/180 feasible trajectories
fall below the required observed rate, all in the three N5 Moderate ALOHA
contexts (nominal, reverse and hidden boundaries).

Nor is an infeasible label a necessity statement. N5 Stressed bg0 ALOHA has a
screen ratio of 0.909 but observed mean per-node goodput of 8.528 Hz, and 14/20
trajectories exceed the target. It is the closest conservative false-negative
boundary. The paper must therefore call this an analytical service screen or
sufficient operating-point gate, not a complete feasibility classifier or a
safety theorem.

## Access repair retained

Frame-aware ALOHA uses `p = 1/[N(2L_D-1)]` rather than the legacy `1/N` rule.
For the four N10 ALOHA core contexts it produces the following development
contrast:

| Context | Legacy collision frames | Candidate collision frames | Reduction | Offered-load reduction |
|---|---:|---:|---:|---:|
| Moderate bg0 | 5015.9 | 717.8 | 85.7% | 74.1% |
| Moderate bg0.30 | 4398.0 | 1352.2 | 69.3% | 66.2% |
| Stressed bg0 | 4859.8 | 725.8 | 85.1% | 73.2% |
| Stressed bg0.30 | 4258.8 | 1319.3 | 69.0% | 65.9% |

This is an absolute collision-burden result. EXP18A v1's failed collision-rate
gate remains failed and is not rescored.

## Important adverse result

Exact routing is not evidence that the routed component is optimal. In the
feasible N5 Moderate bg0 ALOHA development cell, EXP18A4 selects adaptive
feedback, but frame-aware piggyback has lower mean RMSE (`0.0784` versus
`0.0826`) and lower offered utilization (`0.312` versus `0.321`). The selected
method therefore cannot be described as an optimal feedback-route selector.

The defensible new proposition is narrower: a causal, parameter-free capacity
screen can abstain from standalone feedback outside its declared operating
region, while retaining fixed, auditable routes inside it. Whether that
abstention has reproducible control/resource value is a fresh-holdout question.

## Development history retained

- EXP18A v1 failed 2/6 gates; its busy-based feasibility proxy never blocked.
- EXP18A2 passed its formal gate but retained excessive standalone ACK use in
  feasible CSMA cells, so it was not frozen scientifically.
- EXP18A3 reduced ACK use but failed exact piggyback routing; no further score
  coefficient or threshold was fitted.
- EXP18A4 passes because it removes the unsupported heuristic and exposes a
  closed capacity-plus-route map, not because failed versions were rescored.

## Decision

Write and freeze EXP18B with disjoint seeds. Do not open those seeds until the
registry, analysis, integrity tests and source snapshot are executable. EXP18B
must test service-screen sufficiency and the abstention boundary separately;
it must not preregister universal route optimality. Hardware remains deferred.
