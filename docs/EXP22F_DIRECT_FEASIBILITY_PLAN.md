# EXP22F: direct common-PHY feasibility kill test

**Frozen before randomized outcomes:** 2026-09-01  
**Upstream:** EXP22E-K 17/17; EXP22E-CL 17/17  
**Stage:** candidate feasibility falsification  
**Tuning, confirmation and submission claims:** prohibited

## Question

Does queue-compatible ELCS-F provide a non-dominated accuracy/airtime operating
point once it is compared directly with simple periodic static TDMA and native
D-STR under the same continuous PHY, full-mission guard and affine-clock
realization?

This study is deliberately a kill test. Failure returns the candidate to
design before robustness or holdout work.

## Frozen matrix

- Seeds: `16047001:16047030`.
- Cells: N5 6-DOF zero-loss and N10 ring2 zero-loss.
- Common PHY: 96-byte DATA at 250 kbit/s.
- Clock: one 12-s affine epoch, offset at most `0.25 ms`, drift at most
  `40 ppm`, sufficient guard `1.460058 ms`.
- Periodic static node-ID TDMA rates per node:
  `5, 8.333333, 10, 12.5, 15, 17.5, 20, 25 Hz`.
- References: native D-STR with the same mission guard and ELCS-F after the
  accepted fallback repair.

All ten arms share channel, estimator, initial state, clock draws and seed.
D-STR and ELCS-F each use their own frozen absolute protocol trace. Every
transmitted byte, including management traffic, contributes to total offered
utilization.

## Integrity gates

1. 600 rows are present exactly once;
2. shared traces are paired within every seed/cell;
3. all bounded affine-clock realizations and guards are declared;
4. static TDMA has zero physical collisions;
5. D-STR and ELCS replay every retained outcome exactly with zero skipped
   queue opportunities and zero control/DATA overlap;
6. ELCS lease safety and D-STR physical schedule validity remain intact;
7. recipient and full offered-airtime accounts close;
8. causal/protocol invariants and safety remain clean; and
9. all failures and dominated outcomes are retained.

## Predefined feasibility rule

For each cell and periodic rate, let `R` denote mean RMSE and `C` total offered
utilization. With the previously used 1% margin, periodic dominates ELCS-F if

`R_periodic <= 0.99 R_ELCS` and `C_periodic <= 0.99 C_ELCS`.

Paired bootstrap intervals are reported for both differences. The mean-margin
rule is the frozen decision rule; confidence-supported dominance is an added
strength label, not a post-hoc replacement.

- If any periodic point dominates ELCS-F in either cell, return the current
  candidate to design. Robustness and confirmation remain closed.
- Otherwise, proceed to lossy-control/topology robustness and the remaining
  direct protocol references.

D-STR is reported as a direct prior-art contrast but does not replace the
periodic kill rule.
