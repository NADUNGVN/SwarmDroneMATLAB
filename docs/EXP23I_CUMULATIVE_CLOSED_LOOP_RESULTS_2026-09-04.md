# EXP23I — Targeted cumulative-receipt closed-loop results

Run: `results/exp23i_cumulative_closed_loop_target/2026-09-04_162852`

Frozen decision: **`ELCS_W_CUMULATIVE_TARGET_SURVIVES`**.

Scientific interpretation: **valid targeted survival, but the periodic
frontier separation is too close to the 1% boundary to support a robustness
or promotion claim**.

## Integrity

- 60 fresh seeds and three paired arms: 180/180 unique trajectories.
- Registry hash `75941239` over 54 leaves.
- All 18/18 validation gates passed after the analysis-only pairing-gate
  consolidation recorded in `EXP23I_AMENDMENT_01_GATE_COUNT.md`.
- Channel, estimator, clock, occupancy, kernel draws and overlay are paired
  by seed.
- Exact replay, variable-payload airtime, recipient partitions, busy-time
  union and causal-information contracts close.
- No false-valid, scheduled-collision, safety, divergence or terminal-
  liveness failure occurred. Every cumulative transaction closes by the
  physical horizon.

## Redesign mechanism

Relative to legacy ELCS-W, cumulative receipts produce:

- management airtime `0.58381653 -> 0.41468587` s per 12 s run,
  a `28.9698%` reduction;
- paired management-airtime difference 95% bootstrap CI
  `[-0.17914069, -0.15900160]` s;
- physical retry CLAIM count `188.33 -> 107.75`, a `42.7876%` reduction;
- total offered utilization `0.32558364 -> 0.31151929`, a `4.3197%`
  reduction.

The frozen mechanism-relief criterion therefore passes decisively. Closed-
loop RMSE is effectively unchanged (`-0.000068%`), which correctly isolates
the redesign as an overhead repair rather than a control-quality change.

## Periodic comparison and boundary warning

Against cumulative ELCS-W, periodic TDMA has:

- RMSE `0.05501311` versus `0.05446432` m, or `1.00762%` worse;
- cost `0.28672000` versus `0.31151929`, or `7.96076%` lower;
- paired RMSE-difference CI
  `[-0.00056859, 0.00171811]` m.

The point RMSE ratio lies only `0.00762` percentage points beyond the frozen
1% epsilon band. Hence periodic does not point-estimate epsilon-dominate the
cumulative candidate and the preregistered target decision is a pass.
However, the RMSE interval spans both practically equivalent and clearly
separated outcomes.

Legacy ELCS-W also lands just outside the same point boundary on these fresh
seeds (`1.00755%` periodic RMSE penalty). Cumulative and legacy RMSE are
nearly identical, so crossing the 1% boundary cannot be attributed to the
cumulative redesign. This is seed sensitivity around a deliberately sharp
frontier, not robust evidence of performance separation.

## Feasibility implication

Cumulative ELCS-W's DATA-only utilization is `0.27696213`, below periodic's
`0.28672000`, but its remaining management utilization is `0.03455716`.
At unchanged DATA behavior, another `0.29759147` s per run—`71.7631%` of the
remaining management airtime—must be removed merely to cost-match periodic.
Thus cumulative receipt retention fixes the diagnosed retry amplification
but cannot by itself create a comfortable Pareto margin.

## Decision

The frozen verdict permits a full background confirmation, but proceeding
directly would test a candidate whose decisive IID cell is still boundary-
sensitive. Before spending confirmatory seeds, the next research step is a
mechanism-level overhead-floor audit that decomposes bootstrap, renewal,
CLAIM and RESPONSE airtime and tests whether an in-band or stability-adaptive
renewal design can remove the required 71.76% without weakening certificate
safety. EXP23I data remain development evidence and do not authorize method
promotion or a submission claim.

