# EXP14 holdout results — Causal-Broadcast on a time-varying shared medium

## 1. Status and provenance

EXP14 is complete. The primary run
`results/exp14a_holdout_primary/2026-08-29_155023` contains 10,500 rows and
passes 11/11 integrity gates. The secondary/OOD run
`results/exp14b_holdout_ood/2026-08-29_230917` contains 4,800 rows, completed
in 43 min 44 s, and passes 9/9 integrity gates. Across both matrices there
are zero protocol-invariant violations and zero divergent runs. No performance
outcome is a pass gate.

The primary run required the operational and accounting amendments recorded in
`docs/EXP14_AMENDMENTS.md`. Original artifacts were retained. EXP14B logged
terminal in-flight outcomes directly and did not require resume. The analysis
source was checked against SHA-256
`11da340b344d7cafc257147000514c91d1ab658e21e43c94de025541814625ad`
before performance inspection. Amendment 005 completed the already
preregistered p95/p99 AoI outputs and declared an exhaustive, descriptive OOD
contrast matrix before any performance value was read.

The result remains an abstract discrete-event shared-medium study. Airtime,
energy and packet-error parameters are simulation quantities, not measurements
from a radio or UAV board.

## 2. Main paired contrasts

All differences are arm A minus arm B over 100 exact CRN seed pairs. Every
listed interval uses all 100 pairs; no pair was dropped. Relative changes use
arm B as the denominator. The interval shown is the preregistered paired-t 95%
CI; the 10,000-resample paired-bootstrap intervals agree in sign and are in the
CSV artifact.

| Frozen contrast | Outcome | Mean A | Mean B | Relative change | Mean difference, 95% CI |
|---|---|---:|---:|---:|---:|
| Clean proposed default − P10 | RMSE [m] | 0.05687 | 0.05572 | +2.05% | +0.00114 [0.00086, 0.00143] |
|  | offered utilization | 0.26446 | 0.31335 | −15.60% | −0.04889 [−0.05107, −0.04670] |
|  | mean true AoI [s] | 0.07743 | 0.07471 | +3.65% | +0.00273 [0.00223, 0.00322] |
| Stressed proposed default − P10 | RMSE [m] | 0.06515 | 0.08198 | −20.53% | −0.01683 [−0.01759, −0.01607] |
|  | offered utilization | 0.35980 | 0.31335 | +14.83% | +0.04646 [0.04397, 0.04894] |
|  | mean true AoI [s] | 0.09103 | 0.11928 | −23.69% | −0.02825 [−0.02953, −0.02698] |
| Stressed proposed default − delayed-belief default | RMSE [m] | 0.06515 | 0.07381 | −11.73% | −0.00866 [−0.00932, −0.00800] |
|  | offered utilization | 0.35980 | 0.26440 | +36.08% | +0.09541 [0.09344, 0.09737] |
|  | mean true AoI [s] | 0.09103 | 0.10509 | −13.39% | −0.01407 [−0.01538, −0.01276] |
| Moderate hybrid − causal unicast | RMSE [m] | 0.05797 | 0.06007 | −3.50% | −0.00210 [−0.00236, −0.00184] |
|  | offered utilization | 0.28895 | 0.70554 | −59.05% | −0.41659 [−0.42112, −0.41206] |
|  | mean true AoI [s] | 0.07900 | 0.08300 | −4.82% | −0.00400 [−0.00446, −0.00354] |
| Moderate piggyback − hybrid | RMSE [m] | 0.05379 | 0.05797 | −7.22% | −0.00418 [−0.00439, −0.00398] |
|  | offered utilization | 0.27551 | 0.28895 | −4.65% | −0.01344 [−0.01538, −0.01149] |
|  | mean true AoI [s] | 0.07160 | 0.07900 | −9.37% | −0.00740 [−0.00777, −0.00703] |

All arms in these five primary contrasts have 0/100 safety failures. The
Wilson 95% interval for each observed zero rate is [0, 0.03699]; therefore the
data do not establish a zero population failure probability.

The Clean result is not hidden: the proposed default has worse RMSE and mean
AoI than P10, although it uses materially less offered airtime. Conversely,
the Stressed result buys lower RMSE/AoI with more airtime. Neither comparison
is two-axis dominance.

## 3. Pareto result

The proposed family contributes points to the global RMSE–offered-airtime
frontier, but the frozen default point is not one of them.

| Regime | Proposed exact Pareto points | Proposed nondominated points at 1% margin | Default point status |
|---|---:|---:|---|
| Clean | 2/5 (points 4, 5) | 2/5 | dominated by delayed-belief point 3 |
| Moderate | 2/5 (points 4, 5) | 3/5 (points 2, 4, 5) | dominated by delayed-belief point 3 |
| Stressed | 4/5 (points 1, 2, 4, 5) | 4/5 | dominated by delayed-belief point 2 |

At the 2% margin, the Stressed default becomes nondominated because the
dominator's RMSE advantage is smaller than 2%; the conclusion is therefore
reported with the full 0/0.5/1/2% sensitivity table. The correct claim is
family-level frontier participation, not default-policy superiority.

## 4. What the mechanism ablation says

Broadcast aggregation resolves Study 1's physical-cost reversal against the
legacy per-directed-link mechanism: at Moderate, hybrid broadcast reduces
offered utilization by 59.05% and also lowers RMSE by 3.50% relative to causal
unicast.

However, standalone ACK fallback is counterproductive in the frozen primary
CSMA cell. At Moderate, piggyback-only generates and attempts more DATA frames
(711.7/826.5 versus 600.1/699.5 per run) because its sender-side age estimate
is more conservative, but it removes about 522.5 standalone ACK attempts. It
therefore reduces mean collision frames from 162.2 to 121.2, total offered
utilization from 0.2890 to 0.2755, true AoI from 0.0790 s to 0.0716 s, and RMSE
from 0.0580 m to 0.0538 m. This is consistent with an ACK-load externality:
less explicit feedback can yield fresher receiver state when conservative
belief causes useful DATA transmissions and the saved ACK airtime reduces
contention.

That mechanism explanation is supported directly only for the preregistered
Moderate contrast. The same mean ordering appears descriptively in Clean and
Stressed, but no new confirmatory interval is retrofitted after inspection.

## 5. Secondary/OOD result

The OOD intervals are exhaustive but descriptive and unadjusted. Negative
relative RMSE means the hybrid is better than the comparator. The last column
is piggyback minus hybrid; `overlap` means its paired 95% RMSE interval contains
zero.

| OOD point | Hybrid RMSE [m] | Hybrid offered util. | Hybrid safety failures | Hybrid ΔRMSE vs P10 | Hybrid ΔRMSE vs belief | Piggyback ΔRMSE vs hybrid |
|---|---:|---:|---:|---:|---:|---:|
| N10 ring2 | 0.0917 | 0.949 | 0/100 | −38.7% | −1.9% | −7.4% (better) |
| N20 ring2 | 0.5038 | 2.849 | 100/100 | +27.5% | +20.0% | −2.3% (better; both unsafe) |
| N10 sparse4 | 0.1109 | 1.322 | 0/100 | −33.5% | +1.9% | −15.8% (better) |
| 30% background busy | 0.0904 | 0.713 | 0/100 | −33.5% | −12.8% | −3.3% (better) |
| hidden terminals | 0.0625 | 0.497 | 0/100 | −53.1% | −2.9% | −4.3% (better) |
| reverse-asymmetric ACK | 0.0545 | 0.326 | 0/100 | −12.1% | −2.7% | −1.4% (better) |
| C3 estimator | 0.0397 | 0.724 | 0/100 | −35.0% | −29.6% | −0.6% (overlap) |
| ALOHA p=0.2 | 0.0794 | 0.763 | 0/100 | −75.8% | +3.1% | +11.0% (worse) |

Three boundaries matter.

1. **N=20 congestion collapse.** Hybrid offered demand is 2.849 channel-times
   per second of capacity, measured channel utilization is 0.978, and all
   hybrid, piggyback, P10, P20 and belief runs fail safety. State-event fails
   only 5/100 at offered utilization 0.484 and has lower mean RMSE. This is a
   fixed-policy OOD failure, not evidence that a retuned `p≈1/N`, load control
   or a different topology could not scale.
2. **Feedback mode depends on MAC.** Piggyback has lower RMSE than hybrid in six
   OOD cells, overlaps in C3, but is worse under ALOHA by 0.00877 m, paired 95%
   CI [0.00565, 0.01188]. Under ALOHA it also raises offered utilization from
   0.763 to 0.808 and collisions from 1859.9 to 1971.3. A universal
   piggyback-only replacement is therefore not justified.
3. **No universal advantage over delayed belief.** Hybrid has lower RMSE in
   five cells, but is worse in N10 sparse4, N20 ring2 and ALOHA. The ALOHA
   difference is small but its paired-t interval is entirely above zero.

Offered utilization may exceed one because it is demand before contention;
channel utilization remains bounded by one and is accounted as a busy-time
union.

## 6. Claim disposition

### Supported within the declared simulation model

- Broadcast aggregation removes the legacy unicast cost reversal at the
  preregistered Moderate mechanism point.
- Causal receiver-age estimates remain conservative with bounded protocol
  memory under bursty DATA/ACK loss and a multi-slot shared medium.
- The proposed family contributes Pareto points in every primary network
  regime.
- The frozen default trades more traffic for materially lower error/AoI in
  Stressed relative to P10 and delayed-belief default.

### Rejected or bounded

- The frozen default is not globally Pareto in Clean, Moderate or Stressed.
- Hybrid cumulative feedback is not the best feedback mechanism in the
  primary CSMA cell; piggyback-only is better on all three preregistered
  Moderate continuous outcomes.
- One fixed feedback design does not cover both CSMA-like and ALOHA behavior.
- The frozen `p=0.2`, fixed-threshold policy does not scale safely to N=20.
- EXP14 does not validate a radio standard, real energy consumption, security,
  measured traces or flight hardware.

## 7. Research direction after EXP14

EXP14 closes without retuning. Any improved method needs a new experiment
identifier and new development/holdout seeds. The evidence supports a
**MAC-aware feedback controller**, not another state-threshold sweep:

1. piggyback-first cumulative ACK in low/moderate-contention CSMA;
2. standalone ACK only when a receiver-specific confirmation obligation is
   near expiry and measured busy/collision risk permits it;
3. an explicit offered-load guard that suppresses refresh traffic before
   demand reaches capacity;
4. access probability scaled to the estimated active contender count rather
   than retaining `p=1/5` under N=10/20;
5. a proof track linking the service lower bound and AoI tail to the adaptive
   ACK deadline/load guard;
6. trace/HIL calibration kept separate, as planned, before hardware claims.

The next development study should compare this controller against both frozen
hybrid and piggyback-only policies across fully sensed CSMA, ALOHA, hidden
terminals and N=20. Its success criterion should be elimination of the N=20
offered-load collapse without losing the ALOHA advantage of standalone
confirmation.

## 8. Artifacts

- Primary summaries and inference:
  `analysis_frontier_summary.csv`, `analysis_mechanism_summary.csv`,
  `pareto_margin_audit.csv`, `primary_paired_contrasts.csv`, and
  `primary_safety_intervals.csv` in the EXP14A run directory.
- OOD summaries and inference: `analysis_ood_summary.csv`,
  `secondary_ood_paired_contrasts.csv`, and
  `secondary_ood_safety_intervals.csv` in the EXP14B run directory.
- Figures: `exp14_primary_frontiers.png`, `exp14_mechanism_ablation.png`, and
  `exp14_ood_robustness.png` in the corresponding `figures/` directories.

