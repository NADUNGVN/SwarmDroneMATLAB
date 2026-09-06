# EXP21A — Distributed scheduling reality-check results

**Run:** `results/exp21a_distributed_scheduling_reality_check/2026-09-01_030941`

**Matrix:** 1680/1680 retained trajectories (30 seeds x 8 cells x 7 arms)

**Runtime:** 15 min 03 s

**Integrity:** 15/15 gates passed

**Frozen verdict:** `SCHEDULING_GAIN_FRAGILE`

## 1. Executive conclusion

EXP21A rejects two overly broad interpretations of the EXP20 result.

First, ideal TDMA was **not merely a nominal artifact**.  With explicit lossy
reservation messages and fully charged control airtime, the registered
distributed 8.333-Hz arm still dominated the current frame-piggyback method in
both nominal primary cells and remained within the registered gap from ideal
TDMA.

Second, this nominal result is **not robust enough to promote**.  Only one of
five single-fault cells retained both safety and mean-RMSE performance.  Clock
phase error, hidden control visibility, and churn caused large freshness and
formation degradation.  Nominal convergence and churn-recovery gates also
failed.  No confirmatory, manuscript, hardware, or hardware-policy claim is
authorized by EXP21A.

## 2. Integrity before performance

All 15 registered integrity gates passed:

- exact, unique 1680-row matrix and declared seed/cell/arm coverage;
- paired channel, estimator, proposal, control-loss, and clock traces;
- zero protocol-invariant violations and zero future-random reads;
- bounded queues/histories;
- closed DATA, ACK, terminal, and control-recipient accounting;
- every named scheduling path activated;
- positive reservation airtime blocked DATA and was included in charged cost;
- local/static and distributed scheduling read no receiver truth;
- clock impairment was zero in nominal cells and bounded in clock cells;
- all 345 unsafe runs and all outcomes were retained; and
- frozen source was captured before performance analysis.

There were no diverged trajectories.  A reporting-only amendment corrected a
stale textual count from 13 to 15 integrity gates; it changed no Boolean gate,
data, threshold, or verdict.

## 3. Nominal result: distributed scheduling survives

| Cell | Method | Mean RMSE (m) | Failures / 30 | Charged util. | Control fraction |
|---|---|---:|---:|---:|---:|
| N5 Stressed nominal | Current frame-piggyback | 0.09669 | 0 | 0.33533 | 0 |
|  | Ideal TDMA 8.333 Hz | 0.08316 | 0 | 0.16667 | 0 |
|  | Distributed reservation 8.333 Hz | 0.08447 | 0 | 0.18724 | 0.02945 |
| N10 Moderate nominal | Current frame-piggyback | 0.21437 | 25 | 0.45238 | 0 |
|  | Ideal TDMA 8.333 Hz | 0.10158 | 0 | 0.33333 | 0 |
|  | Distributed reservation 8.333 Hz | 0.10848 | 0 | 0.39316 | 0.07883 |

Relative to the current method, the distributed arm reduced mean RMSE by
12.64% and charged utilization by 44.16% at N5 Stressed.  At N10 Moderate it
reduced mean RMSE by 49.40%, eliminated the 25 observed failures, and reduced
charged utilization by 13.09%.

The paired RMSE-difference intervals were entirely favorable:

- N5: -0.01222 m, 95% paired bootstrap interval
  [-0.01480, -0.00969] m;
- N10: -0.10590 m, interval [-0.11102, -0.10135] m.

Against ideal 8.333-Hz TDMA, distributed scheduling paid only +1.57% RMSE and
+0.02057 absolute charged utilization at N5, and +6.79% RMSE and +0.05983
utilization at N10.  Both cells passed the frozen ideal-gap gate.

## 4. Robustness result: four of five single-fault cells fail

| Single-fault cell | Distributed RMSE | Current RMSE | Distributed/current failures | Charged util. | Decision |
|---|---:|---:|---:|---:|---|
| N5 clock | 1.04028 | 0.09669 | 7 / 0 | 0.33887 | fail |
| N5 control loss 0.25 | 0.08409 | 0.09669 | 0 / 0 | 0.18839 | **retain** |
| N5 churn | 0.14683 | 0.09669 | 13 / 0 | 0.17872 | fail |
| N10 clock | 1.17295 | 0.21437 | 18 / 25 | 0.71813 | fail RMSE |
| N10 hidden control | 1.09134 | 0.21437 | 14 / 25 | 0.58521 | fail RMSE |

The registered requirement was at least four retained cells; the outcome was
one of five.  The compound N10 cell also had high RMSE (1.03593 m), although
its 16 failures did pass the narrow no-more-than-current safety guard (current:
25 failures).

The 10-Hz sensitivity arm did not repair the clock, hidden, churn, or compound
failures.  It generally increased charged utilization and collision exposure.

## 5. Coordination diagnostics

Mean control overhead was 0.04884 across all eight primary-arm cells, safely
below the registered 0.15 cap.  Therefore overhead alone did not kill the
approach.

The failure was coordination robustness:

- nominal convergence by 2 s: 50/60 = 0.8333, below 0.90;
- churn recovery by 2 s: 20/60 = 0.3333, below 0.90;
- N5 churn recovered in 20/30 runs, while compound N10 recovered in 0/30;
- N10 hidden reached a full unique terminal assignment in 0/30 runs;
- N10 compound reached a full unique terminal assignment in 0/30 runs; and
- clock cells produced hundreds to thousands of DATA collisions per run,
  causing multi-second AoI and RMSE near or above 1 m.

Nominal terminal assignments were ultimately unique in 60/60 runs.  Thus the
nominal convergence failure is mainly slow acquisition relative to the frozen
2-s bound, whereas hidden/compound failures are persistent topology conflicts.

## 6. Frozen decision gates

| Gate | Result |
|---|---|
| 15/15 integrity gates | pass |
| dominate current in both nominal cells | pass (2/2) |
| retain at least 4/5 single-fault cells | **fail (1/5)** |
| mean control overhead <= 0.15 | pass (0.04884) |
| nominal convergence >= 0.90 | **fail (0.8333)** |
| churn recovery >= 0.90 | **fail (0.3333)** |
| within ideal gap in both nominal cells | pass (2/2) |
| compound safety no worse than current | pass (16 vs 25) |

Because nominal dominance passed but later robustness/convergence gates failed,
the preregistered verdict is `SCHEDULING_GAIN_FRAGILE`, not
`IDEAL_SCHEDULING_ARTIFACT` and not `DISTRIBUTED_SCHEDULING_PATH_SUPPORTED`.

## 7. Scientific boundary of this result

The clock arm is an unguarded, phase-quantized local-clock stress model.  It
does not yet implement continuous-time local slot boundaries, guard intervals,
or a synchronization beacon/servo.  Its strong negative result proves that an
unguarded schedule is fragile under the registered abstraction; it must not be
presented as a calibrated claim about a particular oscillator or radio.

Reservation control frames are serialized within an abstract control window.
Their airtime and loss are real in the accounting, but request/response frames
do not themselves contend or collide.  This is optimistic relative to a real
distributed MAC.  The two-hop mechanism is explicitly an Aydin-inspired
projection, not a faithful protocol reproduction.

These boundaries make hardware execution premature.  The observed failure is
still at the scheduling/timing-model level and can be resolved or falsified in
simulation before selecting hardware.

## 8. Authorized next research step

EXP21A does not authorize a confirmatory study.  It supports a new, separately
registered development study that diagnoses mechanisms without altering these
results:

1. replace phase quantization by continuous-time slot starts, explicit guard
   time, sync beacons, drift accumulation, and synchronization energy/airtime;
2. make reservation control contend and collide on the same interference map;
3. add causal hidden-terminal conflict repair and explicit fast rejoin after
   lease loss;
4. compare the mechanism to the full published distributed-STDMA protocol if
   sufficient implementation detail or reference code is available; and
5. only after a new design passes clock, hidden, and churn cells, freeze fresh
   seeds for confirmation.

Until then, the defensible claim is narrow: **distributed reservation preserves
the ideal-TDMA advantage under nominal simulated conditions, but the present
mechanism is not robust enough for IoT-J promotion or hardware validation.**
