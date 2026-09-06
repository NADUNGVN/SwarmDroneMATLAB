# EXP21C — Closed-loop continuous-timing integration results

**Run:** `results/exp21c_closed_loop_timing_integration/2026-09-01_044850`

**Matrix:** 240/240 retained trajectories (30 paired seeds x 2 cells x 4
arms)

**Runtime:** 2 min 35 s

**Integrity:** 15/15 gates passed

**Frozen verdict:** `CLOSED_LOOP_TIMING_INTEGRATION_VALID`

## 1. Executive conclusion

The EXP21B continuous-time clock/guard construction survives integration into
the actual closed-loop shared-medium simulator.  A certified guard removes all
endogenous DATA collisions and preserves the ideal scheduled-access formation
performance in both registered boundary cells.  In contrast, the paired
unguarded-clock witness produces 99,752 collision frames and fails all 60
trajectories.

Therefore clock uncertainty is a tractable timing-and-guard problem under a
valid common assignment; it is not evidence that distributed scheduled access
is intrinsically infeasible.  The next unresolved mechanism is how a causal,
lossy, contending control plane establishes, repairs, and rejoins that
assignment.

## 2. Closed-loop result

| Cell | Arm | Mean RMSE (m) | Failures / 30 | Charged utilization | Collision frames |
|---|---|---:|---:|---:|---:|
| N5 Stressed | Ideal TDMA 8.333 Hz | 0.082328 | 0 | 0.166667 | 0 |
|  | Continuous, zero clock error | 0.082546 | 0 | 0.128000 | 0 |
|  | Continuous, certified safe guard | 0.082905 | 0 | 0.128000 | 0 |
|  | Continuous, unguarded clock | 0.348758 | 30 | 0.311629 | 31,695 |
| N10 Moderate | Ideal TDMA 8.333 Hz | 0.101507 | 0 | 0.333333 | 0 |
|  | Continuous, zero clock error | 0.100957 | 0 | 0.256000 | 0 |
|  | Continuous, certified safe guard | 0.102838 | 0 | 0.256000 | 0 |
|  | Continuous, unguarded clock | 0.546975 | 30 | 0.650001 | 68,057 |

The guard consumes schedule span but not transmitted airtime, so the charged
utilization of the two continuous collision-free arms is identical.  Their
lower charged utilization than the legacy ideal reference comes from exact
3.072-ms physical airtime instead of four 1-ms service quanta; it is an
accounting correction, not a new access-efficiency claim.

## 3. Paired consistency with the ideal reference

For N5 Stressed, safe-guard minus ideal RMSE is `+0.000577 m` with paired 95%
bootstrap interval `[-0.000899, +0.002051] m`.  For N10 Moderate it is
`+0.001330 m`, interval `[+0.000764, +0.001930] m`.  There are zero failures in
all ideal, zero-clock, and safe-guard arms.

These small differences are accepted only as integration consistency.  The
experiment was not registered as an equivalence trial and cannot establish a
submission-level performance claim.

## 4. Integrity and regression evidence

All 15 registered gates passed, including paired absolute traces, causal local
information, exact clock-equation closure (`9.44e-16 s` maximum residual),
exact physical airtime, recipient/terminal accounting, collision-free
zero-clock and safe-guard paths, and activation of the unguarded collision
witness.  All 60 unsafe trajectories were retained.

The additive scheduler mode did not change legacy modes: shared-medium
infrastructure (25/25), end-to-end (8/8), scheduler (6/6), EXP20 formation
(9/9), EXP21A (10/10), EXP21B (9/9), and EXP21C (8/8) contract suites passed.

## 5. Authorized next step

EXP21C permits integration of an explicit distributed reservation/recovery
control plane into this continuous-time event timeline.  That control plane
must pay airtime, contend and collide under the same interference graph, use
only causal local evidence, handle schedule inconsistency and lease loss, and
be tested under hidden-control visibility and churn.

Policy promotion, fresh-seed confirmation, and a submission claim remain
prohibited until that mechanism passes separately frozen robustness gates.
