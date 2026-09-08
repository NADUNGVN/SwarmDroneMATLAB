# R2.5 adversarial registry and numerical-rank audit

Authoritative inputs and outputs:

- frozen R2: `results/tcns_r2_generalization_validation/2026-09-08_161130/`;
- independent R2.5: `results/tcns_r2_5_adversarial_validation/2026-09-08_175427/`;
- R2 preregistration commit: `253b99b1071bdb65965c6aa56087ab02b6bec00e`.

## Registry construction and exclusion audit

The registry is the full Cartesian product

`N={5,7,9} x graph={ring2,sparse4,geometric} x pin={even,odd} x H={15,25} x D={2,4}`.

It contains 72 cells.  The gains are fixed in every cell at `Kp=1.8`,
`Kv=2.2`, `KpLeader=1.5`, and `KvLeader=1.8`; consensus-degree
normalization is disabled.  Formation geometry comes from the deterministic
`applyScalableSwarmConfig` lattice.  No graph is drawn from the seed.

| Graph | N | Pre-leader undirected edges/density | Controller-relevant directed edges/density | Actions including pins | Construction |
|---|---:|---:|---:|---:|---|
| ring2 | 5 | 5 / 0.500 | 8 / 0.500 | 10 | circulant distance 1 |
| ring2 | 7 | 7 / 0.333 | 12 / 0.333 | 15 | circulant distance 1 |
| ring2 | 9 | 9 / 0.250 | 16 / 0.250 | 20 | circulant distance 1 |
| sparse4 | 5 | 10 / 1.000 | 16 / 1.000 | 18 | circulant distances 1 and 2 |
| sparse4 | 7 | 14 / 0.667 | 24 / 0.667 | 27 | circulant distances 1 and 2 |
| sparse4 | 9 | 18 / 0.500 | 32 / 0.500 | 36 | circulant distances 1 and 2 |
| geometric | 5 | 4 / 0.400 | 4 / 0.250 | 6 | smallest deterministic lattice radius in 0.15-m increments from 0.60 m giving connectivity |
| geometric | 7 | 7 / 0.333 | 10 / 0.278 | 13 | same deterministic radius rule |
| geometric | 9 | 10 / 0.278 | 16 / 0.250 | 20 | same deterministic radius rule |

The pre-leader graph is checked connected.  The leader's unused incoming row
is then removed, and `tcnsInformationLimitsModel` separately enforces the
symmetric-grounded Schur theorem scope.  Even pinning selects UAVs
`2,4,...`; odd pinning selects `3,5,...`.  Both patterns contain the same
number of pins for the odd N values used here.

Every one of the 72 predefined cells is model-feasible.  R2.5 reconstructs
exactly one registry row and the complete expected action catalog for every
cell.  Counts are:

- `MODEL_INFEASIBLE`: 0;
- `SCIENTIFIC_RESULT_EXCLUDED`: 0;
- silent action/configuration exclusions: 0.

The graphs and Cartesian registry were committed before the first R2 result.
The first R2 run's invalid practical normalization was retained; no graph or
action was replaced.

## What 1320/1320 means

For every declared action, the structural study fixes an x-axis command
correction `[1 0 0]`, conditions the candidate receiver-memory payload, uses
the strongest implemented sender map, and stacks the complete held-memory
history of length `n_free-1`.  The performance functional is the
identity-weighted sum of all follower position-error energy across H samples.

R2.5 independently rebuilt 6600 action/tolerance rows.  It matched the stored
raw rank and identifiability Boolean on all 6600.  Every normalized projection
residual exceeds its tolerance.  Hence 1320/1320 distinct registry action
functionals are nonidentifiable at every one of the five declared tolerances.

This is an empirical property of this finite deterministic registry.  The
architecture makes nonidentifiability plausible: during the held-memory
history, the sender observes its own plant/controller state and its incoming
memories, while the global cost cross term can depend on the receiver's other
controller inputs and formation state.  Those remote components need not
enter the sender history.  This is only a mechanism explanation.  Special
response cancellations, different objectives, richer sharing, or different
graphs can remove the hidden component, so R2.5 does not promote the result to
an arbitrary-formation proposition.

## Why raw rank changes but the value conclusion does not

The raw information maps contain singular modes across many scales.  Changing
the relative cutoff from `1e-6` to `1e-14` changes the retained raw rank for
712 of 1320 action instances.  The scientific question is not the integer
rank in isolation; it is the dimensionless residual

`||N_C' ell||_2 / ||ell||_2`,

where `N_C` is the cutoff-defined information nullspace.  Its minimum is
`3.029117e-6`, which is 3.029 times the loosest declared tolerance.  At the
reference tolerance `1e-10`, the independent direct-SVD residual and R2's
compressed construction differ by at most `8.883e-15`.

Raw `rank([C;ell'])` is itself scale-sensitive.  It increases by one for
`1222, 1319, 1320, 1320, 614` of 1320 rows at tolerances
`1e-6,1e-8,1e-10,1e-12,1e-14`, respectively.  In contrast, after replacing
the retained row space of C by an orthonormal basis and normalizing ell, the
augmented dimension increases by one for 1320/1320 rows at every tolerance.
The latter is the scale-controlled diagnostic corresponding to functional
membership.  The manuscript must not describe it as an invariant raw-rank
result.

At `1e-14`, compressed versus direct null-basis residual magnitudes can differ
by as much as 0.018 because extremely small modes rotate the numerical basis;
the Boolean conclusion remains identical.  This discrepancy is retained in
the machine-readable diagnostic.

## Representative precision attacks

| Case | Raw ranks across tolerances | Cutoff neighborhood at `1e-10` | Double residual | 80-digit conditional-basis residual |
|---|---|---|---:|---:|
| N9 geometric/even, ordinary 1->5, H25/D4; global minimum residual | 15;15;15;15;15 | last retained 1.0; first discarded `5.43e-11`; cutoff `1.01e-5` | `3.02911716139849e-6` | `3.02911716129961e-6` |
| N5 ring/even, ordinary 3->2, H15/D2; rank-unstable | 24;24;24;24;25 | last retained 1.0; first discarded `2.38e-12`; cutoff `2.22e-8` | `0.999906954555914` | `0.999906954555914` |
| N9 geometric/odd, ordinary 2->7, H15/D2; nearest unstable cutoff | 30;30;30;30;33 | last retained 1.0; first discarded `7.33e-11`; cutoff `3.52e-8` | `0.999973273320498` | `0.999973273320489` |

The VPA calculation starts from double implementation matrices and a
double-selected independent row basis.  It is a high-precision projection
cross-check, not symbolic arbitrary-parameter proof.

## Code-path audit

R2's membership decision uses explicit SVD nullspace projection; it does not
call MATLAB `rank(...)`.  `tcnsLinearIdentifiability` uses a tolerance-aware
pseudoinverse projector and makes its Boolean decision from projection
residual.  The single `rank(...)` call in `tcnsR1TheoryDepthAudit` reports
`informationRank`; the multi-action missing dimension is separately computed
from singular values of `L_perp`.  R2.5 records raw ranks only as diagnostics.
