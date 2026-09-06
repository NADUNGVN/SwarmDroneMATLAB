# EXP19A oracle service diagnostic — research result

## Decision

Run `2026-08-31_175039` completed all 1,620 declared development trajectories
(`30 seeds x 6 contexts x 9 arms`) in 7 min 12 s. All 18 integrity gates pass:
there are zero protocol violations, exact paired traces, bounded queue/history,
closed physical and virtual-service accounting, no endogenous collision in
scheduled arms, no future-random oracle read, and all 124 observed safety
failures remain in the result.

The frozen decision is **`NO_SERVICE_SCHEDULING_HEADROOM` (3/5 gates)**.
EXP19B, manuscript promotion and hardware-policy validation are not permitted.
This categorical label is retained exactly as specified even though the
mechanism audit below gives the more precise interpretation: collision-free
access has large headroom, but semantic max-weight does not pass the registered
incremental-value test over fixed/periodic TDMA.

## Frozen promotion gates

| Gate | Result | Evidence |
|---|---:|---|
| N5 Stressed oracle Pareto headroom | PASS | Both oracles lower mean RMSE and offered utilization versus frame-piggyback, with 0/30 failures in all arms. |
| N10 Moderate failure repair without load increase | FAIL | Failures fall from 17/30 to 0/30, but offered utilization changes by +0.00997 (deficit) or +0.00164 (urgency). |
| Not reproduced by periodic TDMA | FAIL | Periodic TDMA 12.5 Hz dominates the urgency oracle at the N5 Stressed boundary. |
| Priority differs from FIFO >=10% | PASS | 62.85% for deficit and 54.37% for urgency in the registered aggregate. |
| All integrity gates | PASS | 18/18. |

The periodic gate implementation is conservative: reproduction of any
boundary-qualified oracle fails the gate. The deficit oracle itself is not
strictly dominated by the discrete periodic points, whereas the urgency oracle
is. Under an existential alternative this gate would pass, but the overall
promotion decision would remain negative because the N10 offered-load gate
still fails. No gate is rewritten after observing outcomes.

## Mechanism separation

### Scheduled access versus frame-aware contention

The collision-free round-robin arm isolates service/access geometry while
retaining the same causal trigger and piggyback feedback.

| Context | RMSE change, paired 95% interval | Offered-utilization change, paired 95% interval | Failure change |
|---|---:|---:|---:|
| N5 Moderate bg0 ALOHA | -0.02530 [-0.02664, -0.02395] | -0.07966 [-0.08277, -0.07654] | 0 -> 0 |
| N5 Stressed bg0 ALOHA | -0.03274 [-0.03458, -0.03091] | -0.05338 [-0.05804, -0.04872] | 0 -> 0 |
| N5 Moderate bg0.30 CSMA | -0.01816 [-0.02038, -0.01593] | -0.12640 [-0.13364, -0.11916] | 0 -> 0 |
| N5 Stressed bg0.30 CSMA | -0.02714 [-0.03057, -0.02372] | -0.10964 [-0.11584, -0.10345] | 0 -> 0 |
| N10 Moderate bg0 ALOHA | -0.12854 [-0.13271, -0.12438] | +0.01039 [+0.00526, +0.01552] | 17 -> 0 |
| N10 Stressed bg0 ALOHA | -0.16769 [-0.17325, -0.16213] | +0.10147 [+0.09595, +0.10699] | 30 -> 0 |

Thus access scheduling is the dominant repair mechanism. At N5 it improves
both control and resource use. At N10 it removes all observed failures but
buys that repair with higher event-triggered offered airtime.

### Semantic priority versus collision-free round robin

Semantic ordering genuinely acts, but its incremental effect is much smaller:

- Deficit max-weight has a fully negative RMSE interval in all six contexts,
  but its offered-load interval is favorable in none; at N5 Stressed bg0.30 it
  is significantly adverse.
- Urgency max-weight improves both RMSE and offered utilization with paired
  intervals excluding zero in N5 Moderate bg0.30, N10 Moderate and N10
  Stressed. At the registered N5 Stressed boundary only offered utilization is
  clearly improved; the RMSE interval crosses zero.
- Periodic TDMA 12.5 Hz at N5 Stressed has RMSE 0.061344 and offered utilization
  0.2500, versus 0.061519 and 0.2799 for urgency max-weight. It therefore
  reproduces that oracle point without receiver-truth scheduling.

At N10 Moderate, the periodic frontier also exposes the main tradeoff: 10 Hz
has 0/30 failures, RMSE 0.08979 and offered utilization 0.4000; 12.5 Hz has
RMSE 0.07829 and offered utilization 0.5000. The urgency oracle lies between
these points (0.07901, 0.45669) but does not establish a primary novelty under
the frozen gate.

## Research disposition

Retain:

- collision-free scheduled access as the mechanism with demonstrated headroom;
- frame-length-aware service accounting, virtual deficits and starvation logs;
- causal piggyback protocol and all integrity invariants;
- the periodic TDMA frontier as a mandatory baseline.

Stop:

- EXP19B as specified;
- receiver-truth semantic max-weight as the primary contribution;
- any claim or hardware validation based on EXP19A.

The next research question is narrower and implementable:

> Can a causal contention-to-scheduled access mode reach the periodic-TDMA
> control/resource frontier using only local load/service observations, without
> receiver-truth oracle state?

This question requires a scoped literature/mechanism audit before another
policy cycle. No EXP20 seed or candidate is opened by this result.

## Artifacts

- `results/exp19a_oracle_service_diagnostic/2026-08-31_175039/tidy.csv`
- `development_decision_gates.csv`
- `oracle_gate_diagnostics.csv`
- `periodic_frontier_audit.csv`
- `posthoc_paired_mechanism_contrasts.csv`
- `posthoc_paired_failure_counts.csv`
- `posthoc_mean_pareto_audit.csv`
- `posthoc_mechanism_verdict.json`
