# EXP14C results — MAC-aware causal-feedback development

## 1. Status and provenance

EXP14C development is complete. Run
`results/exp14c_mac_aware_development/2026-08-30_080346` contains all 288
registered rows (`8 seeds × 6 cells × 6 arms`), passes 12/12 integrity gates,
and has zero divergences and zero protocol-invariant violations. Every
seed/cell group uses the same absolute plant, channel-state and MAC trace for
all six arms.

The simulations completed before a MATLAB `cellstr`/`string` mismatch stopped
only the figure-export step. The existing `tidy.csv` was finalized without
rerunning a simulation; `meta.json` records `simulationsRerun=false`. The
finalization regenerated summaries, contrasts, gates and the selection audit
from the completed rows, then wrote the figure and workspace.

EXP14C uses eight development seeds. All intervals below are exploratory
paired-t diagnostics, not confirmatory inference. The registry explicitly
sets `confirmatoryClaimPermitted=false`.

After finalization, the complete repository regression suite passed 18/18 test
files in 4.0 minutes. This includes all locked Study-1 numerical regressions,
shared-medium micro-cases, EXP14 infrastructure and 15 MAC-aware policy
contract checks.

## 2. Registered development decision

The fixed candidate `full-v2` passes all four predeclared selection criteria:

| Criterion | Result | Evidence |
|---|---|---|
| integrity | pass | 12/12 gates pass |
| no N5/N10 safety regression | pass | 0/8 failures for every N5/N10 cell |
| remove N20 collapse | pass | offered utilization 1.107; 5/8 failures versus hybrid 8/8 |
| no two-axis ALOHA loss | pass | RMSE 0.0763 versus 0.0740, but utilization 0.738 versus 0.758 |

The machine verdict is therefore `PROCEED_TO_NEW_PREREGISTRATION`. This means
that the design is eligible for another study; it is not a superiority claim
and does not require opening a holdout before the mechanism attribution is
scientifically complete.

## 3. Full-v2 relative to frozen hybrid

Differences are `full-v2 − frozen-hybrid`; relative values use frozen hybrid
as denominator.

| Cell | Full RMSE [m] | ΔRMSE | Full offered util. | Δutil. | Safety, full/hybrid |
|---|---:|---:|---:|---:|---:|
| N5 CSMA | 0.05406 | −6.24% | 0.2852 | −2.80% | 0/8, 0/8 |
| N5 ALOHA | 0.07632 | +3.14% | 0.7382 | −2.57% | 0/8, 0/8 |
| N5 30% background | 0.08891 | −1.91% | 0.7122 | +0.01% | 0/8, 0/8 |
| N5 hidden terminals | 0.06057 | −0.72% | 0.5080 | −0.72% | 0/8, 0/8 |
| N10 ring2 | 0.09119 | −0.87% | 0.6550 | −32.46% | 0/8, 0/8 |
| N20 ring2 | 0.24226 | −51.33% | 1.1070 | −61.22% | 5/8, 8/8 |

At N5 CSMA, the paired RMSE difference is −0.00360 m with exploratory 95%
CI [−0.00428, −0.00292], and standalone ACK attempts fall from 515.6 to 61.3
per run. At N10 and N20, offered-load reductions have paired intervals wholly
below zero. Most N5 OOD intervals overlap zero at only eight pairs and must not
be promoted to claims.

## 4. Mechanism attribution

### 4.1 Access scaling is the main N20 repair

Changing only hybrid access from the frozen `p=0.2` to `p=1/N` produces the
largest N20 improvement:

| N20 outcome | Frozen hybrid | Access-only | Relative change |
|---|---:|---:|---:|
| RMSE [m] | 0.49776 | 0.20433 | −58.95% |
| mean true AoI [s] | 0.51968 | 0.16111 | −69.00% |
| offered utilization | 2.85459 | 1.15740 | −59.45% |
| collision frames | 8156.3 | 1987.6 | −75.63% |
| safety failures | 8/8 | 0/8 | eight paired seeds improved |

This is stronger than the full-v2 N20 result. Relative to access-only,
full-v2 reduces offered utilization by another 4.36% and collisions by 15.02%,
but increases RMSE by 18.56%, increases mean true AoI by 23.01%, and changes
safety failures from 0/8 to 5/8. Each continuous paired interval excludes
zero, but remains an eight-seed development diagnostic.

At N10, access scaling alone trades load for freshness: it lowers offered
utilization by 24.92% versus hybrid but raises RMSE by 6.19%. Adding the
adaptive-feedback/guard package to the scaled-access arm then lowers RMSE by
6.65%, AoI by 5.92% and offered utilization by 10.04%. Thus the package is
useful at N10 but too suppressive or too weakly confirmed at N20.

### 4.2 Adaptive ACK resolves direction, not universal superiority

Adaptive ACK without the load guard is nearly indistinguishable from
piggyback-only in N5 CSMA and N10. Under N5 ALOHA its mean RMSE and offered
utilization are respectively 5.47% and 2.45% lower than piggyback-only, which
is directionally consistent with the EXP14 ALOHA reversal. Both exploratory
intervals nevertheless contain zero. Under N=20 with frozen `p=0.2`, both
arms remain saturated and unsafe, so feedback adaptation cannot repair an
incorrect access scale by itself.

### 4.3 The load guard is state-coupled, not a monotone traffic limiter

Given adaptive ACK at frozen access, the guard lowers N20 RMSE by 22.88%, AoI
by 26.76% and offered utilization by 25.06%, but all eight runs remain unsafe.
At N10 it reduces utilization by 2.47% with essentially unchanged RMSE. In the
hidden-terminal cell it raises mean AoI and offered traffic even though it
blocks individual branch-3/4 transmissions. This is not an accounting error:
suppressing a current transmission changes later innovation, freshness and
retry decisions. The closed-loop load response is therefore not guaranteed
to be monotone in the count of locally blocked frames.

## 5. Important unresolved confound

The six-arm matrix is not a complete `adaptive ACK × load guard × access
scaling` factorial. In particular, it omits `adaptive ACK + scaled access`
with the guard disabled. Consequently, the N20 loss of full-v2 relative to
access-only cannot be attributed separately to adaptive feedback or the load
guard. Full-v2 versus access-only identifies only their combined effect.

This limitation was discovered from the completed development results and is
not retrofitted into the registered gate. The formal `PROCEED` verdict remains
unchanged, but the scientifically conservative action is to close this
factorial gap with new development seeds before freezing a confirmatory
candidate. Opening a full-v2-only holdout now would test a method that is
already worse than its access-only ablation on N20 safety.

## 6. Claim disposition

### Supported as development evidence

- The causal/local-observation contract, bounded memory, terminal accounting
  and additive legacy interfaces hold across all 288 rows.
- Scaling contention effort with swarm size removes most of the N20 congestion
  collapse and is the only tested N20 arm with 0/8 safety failures.
- Adaptive standalone ACK is directionally useful under ALOHA and avoids the
  assumption that piggyback-only is universally best.
- The full package substantially reduces N10/N20 offered load relative to the
  frozen hybrid design.

### Rejected or bounded

- Full-v2 is not the best tested N20 design; access-only is safer and has lower
  RMSE/AoI.
- The load guard cannot be described as monotonically reducing total offered
  traffic in a closed loop.
- Eight development seeds do not support confirmatory performance or safety
  claims.
- The current matrix does not isolate the guard effect under scaled access.
- No radio, energy, security, trace or flight claim is opened by EXP14C.

## 7. Next controlled step

Before a new holdout, run a small, separately identified factorial-closure
study on disjoint development seeds. It must include all eight combinations
of hybrid/adaptive feedback, guard off/on and frozen/scaled access, with N10
and N20 as mandatory cells and ALOHA retained as a boundary cell. The next
candidate can then be frozen without conflating adaptive ACK with load
suppression.

**Completed by EXP14D:** the 384-run complete factorial selected adaptive ACK
plus scaled access with the guard disabled. It identified the fixed load guard,
not adaptive ACK, as the source of the residual N20 safety loss. See
`docs/EXP14D_FACTORIAL_CLOSURE_RESULTS.md`.

EXP15 remains the trace/radio/HIL study and is not renumbered.

## 8. Artifacts

- Registered matrix and policy contract: `development_registry.json` and the
  source snapshot in the run directory.
- Raw and summarized outcomes: `tidy.csv`, `summary.csv` and
  `paired_contrasts.csv`.
- Integrity and fixed selection: `gates.csv`, `selection_criteria.csv` and
  `selection_verdict.json`.
- Post-run exploratory attribution: `development_effects.csv`,
  `development_safety_effects.csv` and
  `development_analysis_manifest.json`.
- Figure: `figures/fig01_EXP14CMAC_awareDevelopment.png`.
