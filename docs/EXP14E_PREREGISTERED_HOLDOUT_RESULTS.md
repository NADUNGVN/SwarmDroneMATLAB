# EXP14E results — preregistered adaptive-ACK/scaled-access holdout

## 1. Status and provenance

EXP14E is complete. Run
`results/exp14e_preregistered_holdout/2026-08-30_213957` contains all 2,800
frozen rows (`100 seeds × 4 cells × 7 arms`) and consumed 23 min 41 s. The
registry hash is `87778193` over 58 leaves. The runner wrote
`holdout_opened.json` and a source snapshot before simulating the first
registered seed. No policy parameter, hypothesis, comparator, exclusion rule
or cell changed after opening.

The complete repository regression suite passed 20/20 test files before the
holdout opened. The run subsequently passed 14/14 integrity gates: exact
matrix and arm completeness, paired absolute traces, causal conservatism,
bounded memory, terminal physical accounting, access/method/feedback
semantics, local-busy bounds and divergence accounting. There were zero
divergences and zero protocol-invariant violations; maximum queue occupancy
was 2 and maximum sender history was 32.

Performance was not an integrity gate. Analysis was opened only after all
integrity gates passed.

## 2. Confirmatory result

The frozen comparison is selected adaptive ACK plus scaled access minus the
access-only hybrid arm. All six one-sided paired tests use all 100 requested
pairs. Holm controls familywise alpha at 0.05 across the three CSMA cells and
two co-primary outcomes.

| Cell | Outcome | Selected | Access-only | Relative difference | Paired difference, 95% CI | Holm-adjusted p |
|---|---|---:|---:|---:|---:|---:|
| N5 CSMA | RMSE [m] | 0.05428 | 0.05780 | −6.09% | −0.003520 [−0.003740, −0.003300] | 2.06e−53 |
| N5 CSMA | offered utilization | 0.28266 | 0.28935 | −2.31% | −0.006686 [−0.008587, −0.004785] | 1.71e−10 |
| N10 ring2 | RMSE [m] | 0.09018 | 0.09725 | −7.27% | −0.007068 [−0.007442, −0.006694] | 6.47e−60 |
| N10 ring2 | offered utilization | 0.63696 | 0.73308 | −13.11% | −0.096113 [−0.100411, −0.091816] | 1.13e−66 |
| N20 ring2 | RMSE [m] | 0.19560 | 0.20676 | −5.40% | −0.011160 [−0.012480, −0.009840] | 1.61e−30 |
| N20 ring2 | offered utilization | 1.14317 | 1.15477 | −1.00% | −0.011605 [−0.014060, −0.009150] | 2.46e−15 |

All 6/6 hypotheses reject after Holm correction and all 3/3 preregistered
CSMA cells satisfy both continuous tests. The observed safety guard also
passes in every primary cell. The exact registered verdict is
`SUPPORTED_ALL_PREREGISTERED_CSMA_CELLS`.

The N20 offered utilization remains above one in both arms. It represents
offered airtime demand, not a physical busy-time fraction; measured channel
utilization is 0.8140 for selected and 0.8210 for access-only. Thus the N20
result supports a relative improvement under overload pressure, not operation
in an uncongested region.

## 3. Safety result and its limit

| Cell | Selected | Access-only | Historical | Piggyback | State | Belief | P10 |
|---|---:|---:|---:|---:|---:|---:|---:|
| N5 CSMA | 0/100 | 0/100 | 0/100 | 0/100 | 0/100 | 0/100 | 0/100 |
| N10 ring2 | 0/100 | 0/100 | 0/100 | 0/100 | 1/100 | 0/100 | 0/100 |
| N20 ring2 | 1/100 | 5/100 | 100/100 | 2/100 | 24/100 | 3/100 | 4/100 |
| N5 ALOHA | 0/100 | 0/100 | 0/100 | 0/100 | 7/100 | 1/100 | 100/100 |

At N20, selected improves four paired seeds and worsens none relative to
access-only. Its raw failure rate is 1% with Wilson 95% interval
[0.18%, 5.45%], versus 5% [2.15%, 11.18%] for access-only. This is an observed
claim guard only. The protocol did not register or power a population
noninferiority test, so no population safety-superiority claim is permitted.

The historical fixed `p=0.2` arm fails 100/100 times at N20. This independently
confirms that contention-aware access scaling is essential to the scalability
repair; fixed access probability cannot be defended as an N-invariant design.

## 4. Strongest secondary boundary: piggyback-only

The preregistered piggyback-only comparator prevents the positive primary
result from being read as universal superiority of standalone adaptive ACK.

| Cell | Selected minus piggyback RMSE | Selected minus piggyback offered utilization | Safety selected/piggyback |
|---|---:|---:|---:|
| N5 CSMA | +0.79%, CI [+0.000253, +0.000593] m | +1.86%, CI [+0.003381, +0.006923] | 0/100, 0/100 |
| N10 ring2 | +0.92%, CI [+0.000467, +0.001184] m | +2.33%, CI [+0.010591, +0.018371] | 0/100, 0/100 |
| N20 ring2 | +0.07%, CI [−0.000752, +0.001036] m | +0.03%, CI [−0.001105, +0.001718] | 1/100, 2/100 |

At N5 and N10, piggyback-only is better on RMSE, true AoI and offered/channel
utilization, with paired intervals excluding zero. It pays zero standalone ACK
attempts, whereas selected pays means of 62.96 and 82.15. At N20, selected
issues only 1.1 standalone ACK attempts on average and is statistically
indistinguishable from piggyback on the continuous outcomes.

The exact post-hoc airtime identity shows why: DATA savings repay only 49.1%
of direct ACK airtime at N5, while N10 standalone feedback induces rather than
saves DATA airtime. At N20 the adaptive rule is already almost piggyback-only.
In contrast, ALOHA DATA savings repay 247.4% of ACK airtime. This mechanism
audit is descriptive and does not alter the confirmatory family; details are
in `docs/STANDALONE_ACK_VALUE_ANALYSIS.md`.

Therefore EXP14E confirms that adaptive ACK scheduling improves the original
hybrid ACK implementation, but it does **not** establish that standalone ACKs
add value beyond a strong piggyback-only design. In the two lower-N CSMA cells,
the evidence instead favors piggyback-only. This boundary must appear in the
abstract/discussion of any paper that foregrounds ACK assistance.

## 5. Other comparator structure

- Selected has lower RMSE than delayed-belief by 4.78%, 9.45% and 8.41% at
  N5/N10/N20 CSMA, but uses 8.04%, 5.62% and 9.50% more offered airtime. This
  is a trade-off, not dominance.
- State-event uses much less airtime but has substantially worse RMSE and
  accumulates 24/100 N20 failures. It remains a low-load frontier point.
- Selected improves both RMSE and offered utilization over P10 at N5 and N10.
  At N20 it improves RMSE by 4.80% and observed safety (1 versus 4 failures),
  but uses 8.58% more offered airtime.
- Relative to the frozen historical hybrid, selected reduces offered
  utilization by 32.80% at N10 and 59.90% at N20. The N20 comparison is mainly
  evidence against fixed `p=0.2`, not clean evidence for ACK scheduling.

No single arm dominates the full error/load/safety landscape across all cells.

## 6. Mandatory ALOHA boundary

ALOHA was excluded from the confirmatory family before opening and remains a
mandatory reported boundary. Relative to access-only, selected has 2.88%
lower RMSE with paired 95% difference interval [−0.004189, −0.000427] m, but
the offered-utilization difference is only −0.51% and its interval
[−0.010997, +0.003152] crosses zero. Both arms have 0/100 safety failures.

This reverses the unfavorable 12-seed development mean, whose intervals also
contained zero. It does not license a universal MAC claim: the ALOHA joint
error/load proposition was not confirmatory, and one of its two relevant
intervals remains inconclusive. The result instead shows why the development
boundary had to be retained rather than converted into a claim.

## 7. Claim disposition for an IEEE/TCNS-style manuscript

### Supported

- Under the frozen abstract multi-slot CSMA model, local-busy adaptive ACK
  scheduling plus `p=min(p_configured,1/N)` improves RMSE and offered airtime
  over the scaled hybrid-ACK implementation at N=5, 10 and 20.
- The result is reproducible across 100 paired seeds, survives the frozen Holm
  family and satisfies the registered observed-safety guard.
- Access scaling removes the catastrophic fixed-`p` N20 failure mode.
- The protocol and accounting implementation satisfies the declared causal,
  bounded-memory and physical-accounting contracts.

### Rejected or bounded

- Selected is not universally Pareto-superior: piggyback-only is better at N5
  and N10 CSMA on the continuous outcomes.
- EXP14E does not establish that standalone ACK traffic is necessary.
- No population safety superiority/noninferiority claim is supported.
- No universal CSMA/ALOHA claim is supported.
- Offered utilization is not measured radio energy, and the abstract MAC is
  not validation of IEEE 802.11, 802.15.4 or another named standard.
- No trace, security, hardware-timing, HIL or flight claim follows from EXP14E.

The defensible contribution is now narrower and stronger: a causal
communication/control framework with explicit physical accounting, a
confirmed CSMA improvement over the original hybrid implementation, and a
negative mechanism result showing when piggyback removes the need for
standalone ACKs.

## 8. Next research decision

EXP14E is closed and must not be tuned or extended with additional seeds. A
post-hoc promotion of piggyback-only would require a separately preregistered
validation if it becomes the proposed final policy.

The recommended next work has two parallel intellectual components, without
requiring flight hardware yet:

1. derive a marginal-value condition for standalone ACKs: the expected
   reduction in future stale DATA/collision cost must exceed ACK airtime and
   contention cost; use it to explain the N5/N10 piggyback result and the N20
   convergence;
2. begin EXP15 with frozen trace replay and a two-node radio/energy bench before
   any multi-UAV packaging decision. The existing hardware BOM deliberately
   defers the flight-computer choice until this gate.

Any new adaptive design belongs to a new development seed block. EXP14E data
may motivate its hypothesis but may not tune its thresholds.

## 9. Artifacts

- Frozen contract: `frozen_registry.json`, `holdout_opened.json`,
  `frozen_source/`.
- Raw data: `tidy.csv`, `tidy_checkpoint.csv`, `workspace.mat`.
- Integrity: `gates.csv`, `integrity_verdict.json`, `meta.json`.
- Confirmatory inference: `primary_holm_tests.csv`,
  `primary_cell_claims.csv`, `claim_verdict.json`.
- Secondary and safety: `secondary_paired_contrasts.csv`,
  `safety_wilson.csv`, `paired_safety_counts.csv`, `analysis_summary.csv`.
- Post-hoc ACK mechanism accounting: `posthoc_ack_value_accounting.csv` and
  `posthoc_ack_value_manifest.json`.
- Figure: `figures/fig01_EXP14EHoldoutFixedArms.png`.
