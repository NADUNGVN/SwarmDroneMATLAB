# EXP23Z — Local migration graph-input closed-loop results

Run: `results/exp23z_local_migration_closed_loop/2026-09-05_072640`.

Status: **LOCAL_MIGRATION_GRAPH_INPUT_CLOSED_LOOP_INVALID (15/16 gates)**.

All 120/120 unique trajectories completed over 20 seeds and six paired
arms. The graph-input executor itself passed every registered integration
contract: the receiver-lifted local event added one incident edge and forced
UAV 10 from slot 7 to slot 9; clocks, DATA outcome replay, management
attempt/byte/airtime accounting and causal instrumentation closed exactly.
All 60 normal migration rows reacquired, all supported arms had zero
collision frames, and delivered versus lost REVOKE produced identical local
suppression and reuse histories.

The study is nevertheless negative because the preregistered
`closed_loop_safety` gate failed. Permanent RESPONSE blackout prevented
reactivation in 20/20 rows. The local lease logic correctly remained silent,
but silence removed UAV 10's state service for the second half of the
mission: all 20 rows crossed the separation threshold. Their mean minimum
separation was 0.16585 m (minimum 0.15959 m), versus 0.50598 m for ordinary
IID-20 migration. No trajectory diverged.

Descriptive operating points:

- zero loss: migration reduced mean RMSE by 2.59% and total offered airtime
  by 4.80% versus periodic;
- IID-20: migration increased mean RMSE by 1.77% while reducing total
  offered airtime by 4.89%;
- REVOKE blackout was exactly equivalent to ordinary IID-20 migration;
- permanent RESPONSE blackout increased RMSE by 111.56% and cost by 2.52%
  relative to ordinary IID-20 migration, because cumulative control retries
  continued while DATA remained suppressed.

These performance values are development observations, not confirmation
claims. The result identifies a concrete missing mechanism: fail-silent
lease acquisition is necessary for collision safety but insufficient for
closed-loop safety under persistent certificate loss. A separately
accounted collision-safe emergency DATA service is required before online
state/tube coupling is promoted to confirmation.

Artifact SHA-256:

- `trajectory_tidy.csv`: `D1F749009133D2FB953C7E047BE8890926E690497626B083446DA1CFC90EB0CE`
- `validation_gates.csv`: `F08F89472C6E657322669771E462C9648B1952BE7BC0BA71BD6CFC1C69F62011`
- `closed_loop_verdict.json`: `F47F11EF7665D82713E91DE801946DF9C8F9F02D77D43AE785A2FD5D73F61070`

The pre-execution directory `2026-09-05_072551` contains no trajectories
and is separately documented as an aborted software run.
