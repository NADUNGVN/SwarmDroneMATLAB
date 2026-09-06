# EXP22G: targeted periodic-frontier closure

**Frozen before randomized outcomes:** 2026-09-01  
**Parent:** valid EXP22F, coarse-grid non-dominance but interpolation unresolved  
**Stage:** candidate feasibility falsification  
**Robustness, tuning, promotion and submission claims:** prohibited

## Frozen construction

For 96-byte DATA at 250 kbit/s, collision-free periodic static TDMA below
service saturation has offered utilization

`C_periodic = N (8*96/250000) r`.

Using only the observed ELCS mean cost from EXP22F, not RMSE outcomes, define
for each cell:

- cost-matched rate `r_match = C_ELCS/[N(8*96/250000)]`;
- buffered lower-cost rate `r_-2% = 0.98 r_match`.

Frozen values are:

| Cell | EXP22F ELCS cost | `r_match` (Hz) | `r_-2%` (Hz) |
|---|---:|---:|---:|
| N5 | 0.3507882667 | 22.8377778 | 22.3810222 |
| N10 | 0.3769514667 | 12.2705556 | 12.0251444 |

The 2% buffer ensures the new periodic point can satisfy a 1% cost margin
despite small fresh-seed variation in ELCS acquisition/fallback traffic.

## Matrix

- Seeds: `16048001:16048030`.
- Cells: the same N5 and N10 cells.
- Arms: periodic cost-match, periodic 2%-below-cost, and ELCS-F.
- Same full-mission affine clock, guard, PHY and accounting as EXP22F.
- Total: 180 trajectories.

## Decision rules

Both rules are reported:

1. strict two-axis 1% dominance:
   `R_p <= 0.99 R_e` and `C_p <= 0.99 C_e`;
2. practical epsilon dominance:
   `R_p <= 1.01 R_e` and `C_p <= 0.99 C_e`.

Paired bootstrap intervals accompany both metrics. If the 2%-below-cost arm
epsilon-dominates ELCS in either cell, the current candidate returns to design.
This rule is frozen before all EXP22G outcomes and does not alter EXP22F's
archived verdict.
