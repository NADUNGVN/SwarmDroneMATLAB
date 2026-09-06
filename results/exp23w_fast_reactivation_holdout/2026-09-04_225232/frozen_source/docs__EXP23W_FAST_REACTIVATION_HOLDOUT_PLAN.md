# EXP23W — Preregistered fixed-graph fast-reactivation holdout

Protocol status: frozen before opening. The registered seeds have not been
used by any pilot, smoke test or prior experiment.

## Question and scope

EXP23W tests whether the witness-confirmed early-reactivation mechanism found
in EXP23V replicates on 100 disjoint paired seeds. It covers a fixed certified
conflict graph, for which the old/new union certificate is exact. It does not
claim online graph-migration validity or broad operating-envelope robustness.

The holdout may promote the fixed-graph mechanism to a graph-migration study.
It cannot authorize a submission claim or any policy retuning.

## Frozen matrix

Seeds are `16083001:16083100`, strictly above the prior campaign maximum
`16082060`. Each seed shares one absolute channel, estimator, clock and
background realization across eight arms:

1. periodic lower-cost frontier reference;
2. static coherence reference;
3. conservative old-fence early event;
4. witness-confirmed early event;
5. witness-confirmed early event with permanent REVOKE-delivery blackout;
6. conservative old-fence late event;
7. witness-confirmed late event;
8. witness-confirmed early event with permanent reacquisition-RESPONSE
   blackout.

The total is 800 trajectories. The policy, event times, margins, fault arms,
outcomes and analysis freeze before the first registered seed is simulated.

## Six-test confirmatory family

All alternatives are one-sided `mean(a-b)<0`; raw paired-t p-values enter one
Holm family at familywise alpha 0.05. All six adjusted tests must reject:

- H1: fast-early RMSE versus conservative-early RMSE;
- H2: fast-late RMSE versus conservative-late RMSE;
- H3: fast-early RMSE versus `1.01 * static RMSE` (1% noninferiority);
- H4: fast-early offered utilization versus static offered utilization;
- H5: fast-early offered utilization versus `1.05 * conservative-early`
  offered utilization (5% cost-penalty ceiling);
- H6: fast-late offered utilization versus `1.05 * conservative-late`
  offered utilization.

Paired mean differences, two-sided 95% percentile-bootstrap intervals with
10,000 deterministic resamples, raw p-values and Holm-adjusted p-values are
reported. The paired unit is the seed.

## Integrity, safety and boundary gates

Performance is not opened unless the registry/source snapshot, exact seed
block, full paired matrix and realization hashes validate. Fast normal arms
must reactivate only after eligibility and fresh response closure but before
the conservative fence. Permanent RESPONSE blackout must remain suppressed.
Delivered and lost REVOKE must have identical local suppression,
reactivation, RMSE and offered-utilization histories.

All candidate rows require zero scheduled collisions, false-valid edge
frames, safety failures, divergence, causal forbidden reads and replay
mismatch. Common-PHY REVOKE bytes/airtime, management totals, recipient
accounting, clock composition, background overlay and absolute control bounds
must close exactly.

As a continuation guard, neither normal fast arm may be epsilon-dominated by
the registered static or periodic reference under the fixed 1% RMSE / 1% cost
rule. The RESPONSE-blackout boundary is excluded from this guard and its
periodic dominance, if repeated, remains visible.

## Decision

`FAST_REACTIVATION_FIXED_GRAPH_CONFIRMED` requires all integrity gates, all six
Holm rejections and the frontier continuation guard. Any other complete
outcome is retained as a negative confirmatory result. No threshold, arm or
seed substitution is permitted after holdout opening.
