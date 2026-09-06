# EXP21D-CL D-STR closed-loop integration — results

**Date:** 2026-09-01  
**Accepted run:**
`results/exp21d_closed_loop_integration/2026-09-01_080135`  
**Verdict:** `DSTR_CLOSED_LOOP_INTEGRATION_VALID`

This result validates the prior-art integration and authorizes the frozen
boundary continuation. It does not promote a new scheduler or support a
submission claim.

## 1. Integrity result

All 17 gates passed over 180/180 unique trajectories:

- exactly 30 v3 seeds, two cells and three arms;
- shared channel/clock/estimator traces paired within seed and cell;
- native and oracle-warm arms derived from the same D-STR realization;
- zero future-random or receiver-truth decision reads;
- exact common 96-byte, 250-kbit/s DATA airtime;
- 0 skipped D-STR service opportunities;
- event-engine collision counts equal every translated kernel witness;
- all management recipient and airtime accounting closes;
- 0 DATA/control-plane overlaps and 0 protocol invariant violations;
- all 60 native kernels terminally resolved, collision-free and in frame
  agreement; and
- 0/180 observed safety failures.

Two earlier versions remain invalid and are not rescored. V1 stopped at 18/180
rows because its oracle-warm constructor depended on a valid native terminal
assignment. V2 completed but failed the collision-witness gate because the
closed-loop simulator added leader-pin links after the kernel graph had been
constructed. Amendments 02 and 03 document the corrections and seed changes.

## 2. Closed-loop comparison

| Cell / arm | Mean RMSE (m) | Mean true AoI (s) | Mean offered util. | Mean channel util. | Mean DATA goodput (Hz) | Mean management attempts |
|---|---:|---:|---:|---:|---:|---:|
| N5 periodic static TDMA 8.333 Hz | 0.04401 | 0.07174 | 0.1280 | 0.1280 | 41.67 | — |
| N5 D-STR native | 0.02581 | 0.03062 | 0.4837 | 0.4677 | 135.85 | 258.1 |
| N5 D-STR oracle-warm | 0.02579 | 0.03057 | 0.4250 | 0.4250 | 138.33 | 0 |
| N10 periodic static TDMA 8.333 Hz | 0.05989 | 0.08090 | 0.2560 | 0.2560 | 83.33 | — |
| N10 D-STR native | 0.03266 | 0.03704 | 0.9314 | 0.5996 | 205.73 | 1167.0 |
| N10 D-STR oracle-warm | 0.03019 | 0.03283 | 0.7731 | 0.4639 | 251.67 | 0 |

Against the low-rate periodic service reference, native D-STR reduces mean
RMSE by 41.35% at N5 and 45.46% at N10, and reduces mean true AoI by 57.32%
and 54.21%. These gains are purchased with 2.78 and 2.64 times the reference
utilization added on an absolute-reference basis: total native offered load is
3.78 times periodic at N5 and 3.64 times periodic at N10. This is a frontier
trade-off, not dominance.

## 3. Acquisition and management penalty

The oracle-warm arm retains D-STR frame geometry and five idle management
slots but installs a deterministic centralized conflict-graph coloring at
time zero. Native minus warm therefore isolates acquisition, transient
assignment and continued management attempts.

At N5, native minus warm is small for control quality but material for cost:

- RMSE: `+1.81e-5 m` (95% paired CI `[1.35e-5, 2.26e-5]`), +0.07%;
- true AoI: `+4.70e-5 s` (`[3.18e-5, 6.33e-5]`), +0.15%; and
- offered utilization: `+0.05874` (`[0.05637, 0.06109]`), +13.82%.

At N10, the penalty is no longer negligible:

- RMSE: `+0.002477 m` (`[0.002213, 0.002756]`), +8.21%;
- true AoI: `+0.004213 s` (`[0.003776, 0.004656]`), +12.83%; and
- offered utilization: `+0.15828` (`[0.14269, 0.17394]`), +20.47%.

Mean management-only utilization is 0.0661 at N5 and 0.2988 at N10. Native
DATA utilization is lower than warm by 0.0073 and 0.1405 respectively because
acquisition and invalid/transient schedules suppress useful service. Thus the
net native-warm load difference is not merely the raw control airtime.

## 4. Mechanism diagnostics

- Native convergence occurs within the 12-s mission in every row. Median/p95/
  maximum convergence time is 0.659/1.192/1.203 s at N5 and
  1.914/4.385/5.230 s at N10.
- N5 uses exactly five terminal DATA slots. N10 uses 7–10, mean 8.03.
- Native has early DATA collisions in 12/30 N5 rows (mean 2.27, maximum 12)
  and 30/30 N10 rows (mean 10.07, maximum 30). Every count has an exact
  physical witness and no collision remains hidden by the integration.
- N10 native offered utilization has median 0.931, p95 1.014 and maximum
  1.021; 3/30 rows exceed one because simultaneous spatial-reuse attempts are
  charged per transmitter while channel utilization is a busy-time union.

## 5. Decision

EXP21D-CL closes the zero-loss synchronized composition. It also identifies a
reproducible scaling gap: D-STR's source-style implicit evidence and continued
management traffic remain benign for N5 control quality but impose substantial
N10 load and transient freshness penalties even before erasure, restricted
visibility or state loss is introduced.

The next authorized experiment is the frozen Stage-C boundary continuation:

1. 5% DATA-beacon erasure with full management reach;
2. restricted management reach;
3. one local state-loss/rejoin event; and
4. only after zero-clock boundary accounting closes, composition with the
   already validated bounded-clock model.

A new scheduler is still not authorized. The boundary study must determine
whether the residual problem is false validity, persistent disagreement,
recovery outage, or only high overhead; that mechanism will define any later
candidate.

