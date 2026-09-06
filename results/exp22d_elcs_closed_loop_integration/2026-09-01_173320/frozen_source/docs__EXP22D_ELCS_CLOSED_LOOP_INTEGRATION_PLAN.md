# EXP22D: ELCS-F continuous closed-loop integration

**Frozen before randomized outcomes:** 2026-09-01  
**Upstream gates:** EXP22C 16/16; ELCS continuous contracts 12/12  
**Stage:** candidate model-integration falsification  
**Tuning, promotion and submission claims:** prohibited

## Question

EXP22C validates the edge-lease safety invariant only in the isolated
scheduling kernel. EXP22D asks whether the exact STATUS, GRANT, fallback and
certified DATA realization survives composition with the common 250-kbit/s
PHY, bounded affine clocks, finite queues, estimator, formation controller and
the continuous event engine.

This is not a superiority experiment. A favorable RMSE is insufficient for a
valid result unless every causal, physical-outcome and airtime gate also
closes.

## Frozen matrix

- Fresh seeds: `16044001:16044030`.
- Cells: accepted N5 6-DOF zero-loss graph and N10 ring2 zero-loss graph.
- Arms:
  1. ELCS-F with the full-mission guard and zero clock error;
  2. the same native ELCS-F realization with bounded affine clock error.
- Mission duration: 12 s.
- Clock bound: initial offset `0.25 ms`, drift `40 ppm`, one affine epoch.
- PHY: 96-byte DATA and 32-byte STATUS/GRANT at 250 kbit/s.
- ELCS parameters are inherited unchanged from EXP22C.

Both arms share the kernel trace, base schedule, channel/estimator trace and
the same outcome-blind nominal cutoff. The only arm difference is the inverse
clock map. No outcome may be used to select a retained opportunity.

## Required integrity gates

1. all 120 seed/cell/arm rows occur exactly once;
2. all absolute traces and logical-opportunity hashes are paired;
3. the ELCS kernel has zero false-valid edge-frames, owner-lock violations and
   certified scheduled collisions;
4. every retained DATA opportunity is consumed exactly once;
5. scheduled/fallback receiver outcomes equal the kernel masks exactly;
6. management recipient partitions and 32-byte attempt-airtime close;
7. STATUS/GRANT and DATA intervals never overlap across physical regions;
8. the affine clock equation and finite-horizon guard certificate close;
9. recipient, busy-union and offered-airtime accounting close;
10. all future-random, receiver-truth and protocol-invariant counters remain
    zero; and
11. all unsafe, divergent or uncertified rows are retained.

Paired RMSE, AoI, offered utilization, channel utilization and goodput are
reported with bootstrap intervals but have no performance pass threshold.

## Decision

- Passing every integrity gate authorizes ELCS-F robustness studies on the
  same continuous closed-loop model.
- Any causal, timing, mapping or accounting failure invalidates the
  integration and must be repaired before performance experiments.
- Passing EXP22D alone does not authorize method promotion or manuscript
  claims.
