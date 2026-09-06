# EXP14I preregistered MAC-selective feedback validation results

## Status and provenance

EXP14I is complete. Run
`results/exp14i_mac_selective_validation/2026-08-31_004619` contains all 1,600
frozen rows (`100 seeds × 4 cells × 4 arms`) and consumed 15 min 49 s. The
registry hash is `84940762` over 52 leaves. The runner wrote the design lock,
registry and source snapshot before the first holdout seed was simulated.

The complete repository regression suite passed 27/27 files before opening.
The holdout then passed 15/15 integrity gates: complete and unique paired
matrix, common absolute trace/channel realization, finite outputs, causal
conservatism, bounded memory, physical accounting, access/route/comparator
semantics, local-busy bounds and divergence accounting. There are zero
protocol violations and zero divergences; maximum queue occupancy is 2 and
maximum sender history is 32.

Performance was not an integrity gate. Analysis opened only after every gate
passed.

## Exact meaning of the candidate

The candidate uses one registered context variable, the configured MAC type:

- CSMA routes to scaled piggyback-only feedback;
- ALOHA routes to scaled adaptive standalone plus piggyback feedback.

It is intentionally an exact alias of its routed reference inside each cell.
All 16 registered outcome/accounting fields match with maximum difference zero
for every seed and cell. EXP14I therefore does not relabel an existing
within-cell arm as a novel algorithm. The tested contribution is whether the
development-derived cross-MAC mapping chooses the correct fixed feedback mode
on new traces.

## Confirmatory result

Lower is better. Candidate minus the preregistered opposite route is tested on
RMSE and offered utilization. All 100 requested pairs are present in every
test, and Holm controls familywise alpha at 0.05 over the six hypotheses.

| Cell | Outcome | Candidate | Opposite route | Relative difference | Paired difference, 95% CI | Holm-adjusted p |
|---|---|---:|---:|---:|---:|---:|
| N5 CSMA | RMSE [m] | 0.053740 | adaptive 0.054267 | −0.97% | −0.000527 [−0.000690, −0.000365] | 4.06e−9 |
| N5 CSMA | offered utilization | 0.275350 | adaptive 0.283694 | −2.94% | −0.008344 [−0.010243, −0.006445] | 1.70e−13 |
| N10 ring2 | RMSE [m] | 0.089059 | adaptive 0.090160 | −1.22% | −0.001100 [−0.001455, −0.000746] | 7.56e−9 |
| N10 ring2 | offered utilization | 0.618860 | adaptive 0.635639 | −2.64% | −0.016779 [−0.020535, −0.013024] | 9.74e−14 |
| N5 ALOHA | RMSE [m] | 0.078753 | piggyback 0.089324 | −11.84% | −0.010572 [−0.013629, −0.007514] | 9.02e−10 |
| N5 ALOHA | offered utilization | 0.768387 | piggyback 0.804670 | −4.51% | −0.036282 [−0.045696, −0.026869] | 2.71e−11 |

All 6/6 hypotheses reject after Holm adjustment and all 3/3 registered cells
pass both continuous tests and the observed safety guard. The exact verdict is
`SUPPORTED_REGISTERED_MAC_SELECTOR`.

This is statistically strong but scientifically bounded. The CSMA gains at
N5/N10 are modest in RMSE (0.97--1.22%) and clearer in offered load
(2.64--2.94%). The ALOHA reversal is materially larger: 11.84% lower RMSE and
4.51% lower offered load than piggyback-only.

## Mechanism reproduced on new seeds

The holdout reproduces the earlier accounting story without fitting a new
threshold:

| Cell | Route selected | Standalone ACK attempts removed/added | DATA-attempt change | Collision-frame change | True-AoI change |
|---|---|---:|---:|---:|---:|
| N5 CSMA | piggyback | −61.92 | +4.80 | −6.57 (−5.14%) | −1.58% |
| N10 CSMA | piggyback | −81.12 | −10.39 | −35.22 (−7.07%) | −1.95% |
| N5 ALOHA | adaptive | +309.85 | −205.86 | −87.33 (−4.45%) | −14.99% |

Changes are candidate minus the opposite route. Under CSMA, deleting
standalone feedback removes direct ACK service and reduces collisions; at N10
it also reduces DATA demand. At N5 the mean DATA-attempt change is slightly
positive and its descriptive interval crosses zero, yet total offered airtime
still falls because 61.92 ACK attempts disappear and collisions fall.

Under ALOHA, 309.85 standalone ACK attempts are repaid by 205.86 fewer DATA
attempts, 87.33 fewer collision frames, lower true AoI and lower offered load.
This validates MAC-conditioned routing; it does not make standalone ACK
universally beneficial.

## N20 mandatory boundary

N20 is outside the confirmatory family. Candidate is exactly piggyback-only
and has zero safety failures. Relative to adaptive, the paired descriptive
effects are:

| Outcome | Candidate | Adaptive | Difference, 95% CI |
|---|---:|---:|---:|
| RMSE [m] | 0.195700 | 0.195595 | +0.000105 [−0.000797, +0.001008] |
| true AoI [s] | 0.155265 | 0.155506 | −0.000241 [−0.001234, +0.000753] |
| offered utilization | 1.140123 | 1.140380 | −0.000257 [−0.001918, +0.001405] |
| ACK attempts | 0 | 0.77 | −0.77 [−0.955, −0.585] |

Continuous intervals cross zero and the adaptive policy averages fewer than
one standalone ACK attempt per 12 s run. This independently agrees with the
EXP14G/H support audit: adaptive feedback has already converged almost to the
piggyback route under N20 load. No equivalence or N20 causal-value claim is
made.

As a secondary full-policy contrast, candidate reduces RMSE by 5.14%, true AoI
by 5.68%, offered utilization by 0.95% and collision frames by 10.13% relative
to access-only. Access-only has 6/100 observed safety failures versus 0/100 for
candidate. These were not confirmatory N20 hypotheses.

## Safety and claim ceiling

Candidate has 0/100 observed failures in all four cells. The opposite-route
comparators have 0/100 at N5/N10 CSMA, while piggyback has 1/100 under ALOHA.
For zero observed failures, the Wilson 95% upper bound is 3.70%; therefore raw
zero counts are not a population safety proof.

### Supported

- The frozen selector reproduces the CSMA/ALOHA feedback-mode reversal on 100
  new paired traces per cell.
- Piggyback-only improves both registered continuous outcomes over adaptive
  standalone feedback at N5 and N10 CSMA.
- Adaptive standalone feedback improves both registered outcomes over
  piggyback-only at N5 ALOHA.
- The six directional results survive the frozen Holm family and all three
  observed safety guards.

### Not supported or not claimed

- no universal optimality over other MAC protocols, topologies or loads;
- no N20 per-decision ACK-value or equivalence claim;
- no population safety superiority/noninferiority claim;
- no claim that MAC type alone is sufficient for every operating regime;
- no measured radio energy, security, trace, HIL or flight claim;
- no novelty claim for the within-cell adaptive or piggyback component.

The defensible design conclusion is narrow and useful: **standalone feedback
should be routed by MAC mechanism, not enabled by a universal scalar ACK
threshold**. Within the registered abstract channel model, piggyback-first is
the correct CSMA default, while ALOHA retains a valuable fast standalone
confirmation path.

## Artifacts

- Frozen plan: `docs/EXP14I_MAC_SELECTIVE_VALIDATION_PLAN.md`.
- Locks/snapshot: `frozen_registry.json`, `holdout_opened.json`,
  `frozen_source/` in the run directory.
- Raw data: `tidy.csv`, `tidy_checkpoint.csv`, `workspace.mat`.
- Integrity: `gates.csv`, `integrity_verdict.json`, `meta.json`.
- Confirmatory inference: `primary_holm_tests.csv`,
  `primary_cell_claims.csv`, `claim_verdict.json`.
- Alias/mechanism/safety: `candidate_alias_audit.csv`,
  `secondary_paired_contrasts.csv`, `analysis_summary.csv`,
  `safety_wilson.csv`, `paired_safety_counts.csv`.
- Figure: `figures/fig01_EXP14IMAC_selectiveHoldout.png`.
