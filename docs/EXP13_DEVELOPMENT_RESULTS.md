# EXP13 — Development results and freeze decision

**Recorded run:** `results/exp13_development/2026-08-29_111747`  
**Corrective MAC diagnostic:**
`results/exp13b_multislot_mac_diagnostic/2026-08-29_131048`  
**Status:** EXP13 passed 14/14 gates over 531 runs; EXP13B passed 6/6 gates
over 96 runs.  Holdout remains unopened and no performance claim is permitted.

## 1. What was completed

EXP13 used four disjoint development matrices:

| Matrix | Runs | Purpose |
|---|---:|---|
| Equal-budget frontiers | 360 | six policy families, five points each, three loss cells, four paired seeds |
| Mechanism ablation | 60 | unicast, DATA-only, standalone, piggyback and hybrid feedback |
| LHS sensitivity | 39 | default plus 12 points, three paired seeds |
| Contention/history | 72 | CSMA p-grid, ALOHA, TDMA, background occupancy and finite-history stress |

All plant outputs were finite, receiver-confirmed age remained conservative,
physical accounting closed, queues/history remained bounded and the total
protocol-invariant count was zero.  The finite-history arm produced 46 expired
ACK rejections without corrupting sender belief.

## 2. Frontier result: the proposed method is not globally dominant

The post-run audit evaluates exact two-axis Pareto membership using mean
formation RMSE and mean offered airtime among points with zero separation
failures.  It is a descriptive development audit, not holdout inference.

| Regime | Causal-Broadcast Pareto points out of 5 | Interpretation |
|---|---:|---|
| Clean | 0 | periodic/state-event points dominate the proposed frontier |
| Moderate | 0 | periodic and delayed-ACK-belief points cover the useful frontier |
| Stressed | 2 | proposed multipliers 0.75 and 1.0 enter the frontier |

The strongest accuracy point is not the proposed method.  The AoI-only family
reaches mean RMSE 0.0298 m in Moderate and 0.0310 m in Stressed, but at offered
airtime 0.267 and 0.321.  Periodic remains a particularly strong benchmark:
its 25-Hz point reaches 0.0290/0.0315/0.0386 m in
Clean/Moderate/Stressed at utilization 0.197.

At the default Moderate point, Causal-Broadcast records 0.0528 m RMSE at 0.1146
offered utilization, while P10 records 0.0546 m at 0.0791.  Neither point
dominates the other.  Under collision-free TDMA, however, P10 records 0.0500 m
at 0.050 utilization and dominates default Causal-Broadcast (0.0540 m at
0.101).  Any eventual claim must therefore be explicitly limited to impaired
contention regimes where the holdout supports it; no general advantage is
visible in development.

The delayed-ACK belief adaptation is competitive and appears on the Moderate
and Stressed frontiers.  It remains an adaptation to the broadcast action
space, not an exact reproduction of Tahir et al.'s optimizer.

## 3. Mechanism result: broadcast aggregation is real; ACK mode is a tradeoff

The clearest positive mechanism result is physical aggregation rather than a
universal control advantage.

| Regime | unicast / hybrid offered-utilization ratio | unicast minus hybrid RMSE [m] |
|---|---:|---:|
| Clean | 2.020 | -0.00019 |
| Moderate | 2.078 | +0.000004 |
| Stressed | 2.270 | -0.00028 |

Thus one DATA broadcast removes approximately half the unicast offered airtime
without a material mean-RMSE change in these development cells.  This directly
addresses the broadcast-accounting reversal exposed by Study 1, but it is a
mechanism observation until holdout.

Piggyback-only feedback reduces offered utilization relative to hybrid by
37.8%, 38.6% and 34.6% in Clean, Moderate and Stressed, respectively, and has
slightly lower RMSE.  Its sender-confirmed age is worse by 0.0283, 0.0241 and
0.0186 s.  Standalone-only costs 25.1--28.5% more airtime than hybrid and also
has a larger confirmed age.  The hybrid mechanism therefore improves feedback
freshness over piggyback-only and dominates standalone-only on these two
feedback axes, but piggyback-only remains the better traffic/control point.
The paper must not describe hybrid as unconditionally optimal.

The state-event DATA-only arm fails separation in 2/4 Stressed seeds; every
causal feedback arm has zero separation failures in this ablation.

## 4. Sensitivity and frozen trigger candidate

All 13 sensitivity designs have zero separation failures.  The preregistered
lexicographic selector chooses **design 0**, the original default:

- position/velocity thresholds: 0.05 m / 0.10 m/s;
- confirmed-age threshold: 0.12 s;
- maximum silence: 0.50 s;
- new-information/refresh intervals: 0.02 s / 0.10 s;
- scale base/minimum/adaptation range: 0.50 / 0.20 / 1.00.

This is useful negative evidence against post-hoc retuning: none of the 12 LHS
points improves the worst-seed RMSE enough to enter the declared 5% selection
band.  In an LHS-only Spearman screening (`n=12`), the confirmed-age threshold
is the dominant parameter: rho = +0.853 with RMSE and -0.804 with offered
utilization.  These correlations are screening diagnostics, not global
sensitivity indices.

The trigger candidate is frozen for EXP14.  The analytical primary access
probability remains `p=0.2`; it was not replaced by an empirical optimum.

## 5. Contention boundaries and corrective EXP13B

The p-grid reproduces congestion collapse at synchronized `p=1`:
Causal-Broadcast fails separation in 4/4 seeds with RMSE 0.3649 m, while P10
has zero delivery and RMSE 1.7372 m despite no binary separation failure.  This
again shows that minimum separation alone is an inadequate coordination gate.

Background busy probabilities 0.1 and 0.3 do not cause failure in the Moderate
development cell.  The finite-history stress arm remains causal and finite.

Post-run inspection found that the declared 48-B/1-Mbit/s configuration gives
one-slot DATA and ACK frames.  Consequently CSMA and slotted ALOHA are exactly
identical in all paired EXP13 physical outcomes.  This does not invalidate the
preregistered gates, but it makes the ALOHA reference scientifically
uninformative.

EXP13B preserved that result and added a fixed abstract multi-slot calibration
(96-B DATA, 250-kbit/s PHY).  Bare DATA then occupies four slots.  At `p=0.2`:

| Method | MAC | RMSE [m] | mean collisions | offered util. | failures / 4 |
|---|---|---:|---:|---:|---:|
| Causal-Broadcast | CSMA | 0.0547 | 202.0 | 0.313 | 0 |
| Causal-Broadcast | ALOHA | 0.0804 | 2019.3 | 0.813 | 0 |
| P10 | CSMA | 0.0594 | 369.8 | 0.315 | 0 |
| P10 | ALOHA | 0.3372 | 1642.5 | 0.588 | 4 |

EXP13B passed all six diagnostic gates and confirms that the kernel distinguishes
carrier sensing once service spans slots.  These figures diagnose the MAC
model; they must not be used as a policy-superiority claim.

## 6. Decisions before EXP14

1. Freeze trigger design 0 and `p=0.2`.
2. Keep complete periodic, state-event, AoI-only, AoCI-inspired and delayed-ACK
   belief frontiers; do not reduce them to a favorable single point.
3. Retain piggyback-only as a serious comparator to hybrid.
4. Use a multi-slot primary abstraction in EXP14 and carry one-slot service as
   a boundary arm.  The exact multi-slot parameters remain explicitly
   abstract until EXP15 measures hardware airtime.
5. Add burst/time-varying loss and reverse asymmetry before opening holdout;
   the current iid residual-loss cells are insufficient for the planned EXP14
   claim scope.
6. Keep binary separation, RMSE, confirmed AoI, physical airtime, failures and
   denominators visible together.

EXP14 is therefore **not opened by EXP13**.  Its preregistration and missing
time-varying channel arms must be completed first.

## 7. Artifacts

- EXP13 verdict and gates: `verdict.json`, `gates.csv`;
- raw matrices: `frontier.csv`, `mechanism.csv`, `sensitivity.csv`,
  `contention.csv`;
- selection: `selection.csv`, `selected_development_config.json`;
- post-run audit: `pareto_audit.csv`, `sensitivity_spearman.csv`,
  `mechanism_contrasts.csv`, `postrun_audit.json`;
- EXP13B: `tidy.csv`, `summary.csv`, `mac_contrasts.csv`, `gates.csv`,
  `verdict.json` in its recorded run directory;
- four EXP13 figures and one EXP13B figure are stored below each run's
  `figures/` directory.
