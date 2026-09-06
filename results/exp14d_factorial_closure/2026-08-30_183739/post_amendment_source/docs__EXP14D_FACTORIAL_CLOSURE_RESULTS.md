# EXP14D results — complete MAC-aware factorial closure

## 1. Status and provenance

EXP14D development is complete. Run
`results/exp14d_factorial_closure/2026-08-30_183739` contains all 384 declared
rows (`12 seeds × 4 cells × 8 arms`), passes 15/15 integrity gates, and has
zero divergences and zero protocol-invariant violations. Contract hash
`8052507`, the complete binary factor cube and the deterministic candidate rule
were frozen before performance inspection.

The run consumed 3 min 02 s. An operational gate amendment excluded only
`NETWORK_RUNTIME_SEC` from the N5 bit-identity comparison after a column-level
audit showed that all scientific outputs were exact. The original failed gate
artifact is retained. Finalization reused `tidy.csv`; none of the 384
simulations was rerun. Details are in `docs/EXP14D_AMENDMENTS.md`.

All 12 seeds are developmental. The paired intervals below are exploratory and
the registry fixes `confirmatoryClaimPermitted=false`.

After the analysis and operational amendment, the complete repository
regression suite passed 19/19 test files in 4.1 minutes, including every locked
Study-1 numerical regression and the new nine-check EXP14D interface contract.

## 2. Frozen development decision

Only two arms satisfy the registered eligibility rule of zero failures in all
four cells and N20 mean offered utilization below 1.2:

| Arm | Meaning | Total failures | N20 util. | Worst RMSE regret | Worst load regret | Selected |
|---|---|---:|---:|---:|---:|---:|
| `a0-g0-s1` | hybrid ACK, no guard, scaled access | 0 | 1.1547 | 7.41% | 14.78% | no |
| `a1-g0-s1` | adaptive ACK, no guard, scaled access | 0 | 1.1466 | 3.71% | 1.03% | yes |

The deterministic verdict is `FREEZE_FOR_NEW_PREREGISTRATION`, candidate
`a1-g0-s1`. This is a minimax development selection, not evidence of universal
dominance.

## 3. Selected arm versus access scaling alone

The contrast is `a1-g0-s1 − a0-g0-s1`; it isolates adaptive ACK with the guard
off and access scaled in both arms.

| Cell | ΔRMSE | Δmean true AoI | Δoffered util. | Safety selected/access |
|---|---:|---:|---:|---:|
| N5 CSMA | −6.29% | −7.57% | −2.78% | 0/12, 0/12 |
| N5 ALOHA | +3.71% | +6.61% | +1.03% | 0/12, 0/12 |
| N10 ring2 | −6.90% | −7.14% | −12.88% | 0/12, 0/12 |
| N20 ring2 | −3.69% | −4.01% | −0.70% | 0/12, 0/12 |

For CSMA N5, N10 and N20, all three exploratory paired intervals exclude zero.
At N20, adaptive feedback generates 2.02% more DATA attempts but removes
99.70% of standalone ACK attempts and reduces collision frames by 9.52%. The
net effect is lower error, AoI and offered load.

The ALOHA boundary remains negative: all three selected-arm means are worse
than access-only, although all three intervals contain zero at 12 pairs. The
candidate is therefore not a universal ALOHA improvement.

## 4. The factorial answer to the EXP14C confound

### 4.1 Access scaling is necessary

At N20, the `S` main effect averaged over ACK and guard settings is:

- RMSE: −0.2282 m, exploratory 95% CI [−0.2334, −0.2229];
- mean true AoI: −0.2641 s [−0.2740, −0.2543];
- offered utilization: −1.3375 [−1.3485, −1.3265].

Across the 48 matched N20 `S` safety comparisons, scaled access improves 33,
worsens none and leaves 15 unchanged. Without scaling, all four arms have
12/12 N20 safety failures. Access scaling is therefore the essential
congestion-control component in this development boundary.

### 4.2 The fixed load guard causes the residual N20 safety loss

With adaptive ACK and scaled access, enabling the guard changes:

| N20 outcome | Guard off, selected | Guard on, full-v2 | Relative change |
|---|---:|---:|---:|
| RMSE [m] | 0.19858 | 0.24317 | +22.45% |
| mean true AoI [s] | 0.15847 | 0.19560 | +23.43% |
| offered utilization | 1.14658 | 1.10390 | −3.72% |
| collision frames | 1794.5 | 1687.6 | −5.96% |
| safety failures | 0/12 | 6/12 | six paired seeds worsened |

The same result is stronger with hybrid ACK: enabling the guard under scaled
access changes safety from 0/12 to 9/12. Across all 48 matched N20 guard
comparisons, the guard worsens safety in 15 and improves none. The positive
`G×S` interaction is also large: +0.0691 m RMSE and +0.0929 s AoI. Thus the
guard saves a small amount of airtime after contention has already been scaled,
but suppresses useful refresh strongly enough to damage closed-loop safety.

The EXP14C confound is therefore resolved: adaptive ACK is not the source of
the N20 degradation. The fixed branch-aware load guard is.

### 4.3 Regime dependence remains

At N5 ALOHA, the guard reduces mean offered utilization and tends to lower
RMSE; with adaptive ACK its load difference is −2.90% and its interval is
entirely below zero. At N10 and N20, however, the guard increases load or
damages freshness when access is already scaled. A universal fixed guard
cannot cover all regimes. Developing another threshold schedule now would
restart tuning and is not necessary for the selected no-guard candidate.

## 5. Negative-control result

In both N5 cells, `p_configured=0.2=1/N`. For every seed and each matched
`A,G` setting, the `S=0` and `S=1` arms are bit-identical in every logged
physical, control, AoI, traffic, accounting, protocol and realization-hash
output. All registered `S`, `A×S`, `G×S` and `A×G×S` effects are numerically
zero up to floating representation. This verifies that the factor flag itself
does not leak into behavior when scaling cannot change access.

## 6. Claim disposition

### Supported as development evidence

- A complete factorial resolves the missing-arm confound from EXP14C.
- `p=min(p_configured,1/N)` is necessary to remove the N20 collapse in the
  tested topology and traffic model.
- Adaptive ACK without the load guard improves the selected CSMA N5/N10/N20
  trade-off relative to access scaling alone.
- The fixed load guard, not adaptive ACK, causes the residual scaled-N20 safety
  failures of full-v2.
- The additive `load-guarded-broadcast` method isolates guard-only cells while
  leaving legacy method semantics unchanged.

### Rejected or bounded

- Full-v2 with the fixed guard should not be promoted to a holdout.
- The selected arm is not better in mean under ALOHA.
- The guard is not a generally safe or monotone congestion controller.
- Twelve development seeds do not establish population safety or superiority.
- No radio, real energy, security, trace or flight claim is supported here.

## 7. Next step

Freeze `a1-g0-s1` as the proposed arm in a new preregistered holdout with new
seeds. The holdout must retain access-only, frozen hybrid and the ALOHA boundary
as explicit comparators, report raw safety denominators, and state in advance
that the primary claim is a CSMA/scalability trade-off rather than universal
MAC superiority. EXP15 remains the subsequent trace/radio/HIL stage.

## 8. Artifacts

- Raw/summarized rows: `tidy.csv`, `summary.csv`.
- Registered inference: `factorial_effects.csv`,
  `factorial_safety_shifts.csv`, `candidate_audit.csv` and
  `selection_verdict.json`.
- Descriptive pairwise audit: `descriptive_pairwise_contrasts.csv`,
  `descriptive_pairwise_safety.csv` and
  `descriptive_analysis_manifest.json`.
- Integrity: `gates.csv`, `gates_pre_runtime_exclusion.csv` and `meta.json`.
- Figure: `figures/fig01_EXP14DCompleteFactorial.png`.
