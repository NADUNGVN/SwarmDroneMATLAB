# EXP22K: event-driven periodic-frontier closure

**Frozen before randomized outcomes:** 2026-09-01  
**Parent:** valid EXP22J event-driven closed-loop integration, 20/20 gates  
**Stage:** candidate feasibility falsification  
**Tuning, robustness, promotion and submission claims:** prohibited

## Scientific question

EXP22G rejected the pre-redesign ELCS-F because a periodic static-TDMA point
2% below its cost was within the 1% RMSE equivalence margin in both cells.
EXP22I/J replaced frame-wise refresh traffic with event-driven discovery and
renewal and validated the protocol contracts. EXP22K asks the decisive
question: after charging all management airtime, can an analytically targeted
periodic policy still epsilon-dominate the redesigned candidate?

## Frozen rate construction

For 96-byte DATA at 250 kbit/s, collision-free periodic static TDMA below
service saturation has offered utilization

`C_periodic = N (8*96/250000) r`.

Only the EXP22J affine-clock mean offered cost is used to set rates; EXP22J
RMSE outcomes do not enter the construction.

| Cell | EXP22J ELCS cost | `r_match` (Hz) | `r_-2%` (Hz) |
|---|---:|---:|---:|
| N5 | 0.2935637333 | 19.1122222 | 18.7299778 |
| N10 | 0.3188736000 | 10.3800000 | 10.1724000 |

## Frozen matrix and contracts

- Fresh seeds: `16052001:16052030`.
- Cells: N5 6-DOF zero-loss and N10 ring-2 zero-loss.
- Arms: periodic cost-match, periodic 2%-below-cost, event-driven ELCS-F.
- Same mission-length affine clock, guard, PHY, receiver accounting and plant
  as EXP22J.
- Total: 180 trajectories.
- ELCS must additionally satisfy: STATUS discovery/request partition closure,
  zero GRANT without a decoded request, total control attempts no larger than
  the analytical bound, and first all-certified frame no later than `N`.

## Frozen decision rule

Both comparisons are reported:

1. strict 1% two-axis dominance:
   `R_p <= 0.99 R_e` and `C_p <= 0.99 C_e`;
2. practical epsilon dominance:
   `R_p <= 1.01 R_e` and `C_p <= 0.99 C_e`.

Paired bootstrap confidence intervals use 10,000 resamples. If the periodic
2%-below-cost arm epsilon-dominates event-driven ELCS-F in either cell, the
candidate returns to design. Otherwise, and only if every integrity gate
passes, robustness continuation is permitted. No result from EXP22K alone is
a promotion or submission claim.
