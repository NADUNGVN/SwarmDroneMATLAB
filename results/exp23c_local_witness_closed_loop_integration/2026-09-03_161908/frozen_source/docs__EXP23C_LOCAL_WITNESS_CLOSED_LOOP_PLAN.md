# EXP23C — ELCS-W local-witness closed-loop integration

Status: frozen before trajectory generation on 2026-09-03.

## Question

Does the retry-safe ELCS-W kernel remain causal, locally implementable and
accounting-exact when its CLAIM, RESPONSE and DATA opportunities share the
same continuous PHY inside the UAV closed loop, including bounded affine
clock error?

EXP23C is an integration/falsification study. It does not tune a policy,
compare a performance frontier, promote a method, or authorize a submission
claim.

## Frozen matrix

- Seeds: `16059001:16059030` (30 fresh paired seeds).
- Cells: N5 6-DOF zero-loss and N10 ring-2 zero-loss.
- Arms: zero clock and bounded affine clock.
- Horizon: 12 s; ELCS-W kernel capacity: 400 frames.
- PHY: 250 kbit/s, 96-byte DATA.
- Management reach: the one-hop neighbor graph, never all-to-all.
- CLAIM: 24 bytes.
- RESPONSE: 16-byte header plus 8 bytes for every assigned conflict edge,
  capped by the frozen 96-byte management MTU.
- Clock bounds: 0.25 ms offset and 40 ppm drift over the 12 s reset horizon.
- Guard: the frozen sufficient mission-horizon guard returned by
  `continuousTdmaGuardBound`.

All channel, estimator, witness-kernel and clock realizations are paired
between clock arms. Only the clock transform differs.

## Required contracts

The run is valid only if all 18 gates pass:

1. registry hash is frozen;
2. the 120-row seed/cell/arm matrix is complete and unique;
3. exact seed, cell and arm coverage holds;
4. absolute channel, estimator, kernel, witness-map and logical schedules are
   paired across clock arms;
5. every conflict edge has a one-hop witness, including conflict edges hidden
   from direct endpoint communication, and the response payload bound holds;
6. only the affine arm consumes a bounded clock realization;
7. the affine clock equation and physical non-overlap certificate hold;
8. terminal certification, no false-valid edge, no scheduled collision and
   no unsupported certificate hold;
9. in zero loss, certification occurs in frame 1, retry count is zero, the
   nominal attempt/byte bounds are exact, and absolute bounds hold;
10. no future-random or receiver-truth decision read occurs;
11. every logical DATA opportunity is served exactly once;
12. DATA success/erasure/collision outcomes replay exactly;
13. management attempts, recipients, bytes and variable packet airtime close
    exactly in the event engine;
14. no management/DATA cross-plane overlap occurs;
15. recipient partitions and total offered/busy airtime accounting close;
16. protocol invariants hold;
17. all failures, if any, remain in the output;
18. no tuning, promotion, frontier or submission decision is made.

## Decision rule

Passing all gates yields `ELCS_W_CLOSED_LOOP_VALID` and permits the next
pre-registered experiment: a fresh-seed sharp frontier comparison against
periodic and the strongest retained distributed baseline under identical
common-PHY accounting. Any failed gate yields
`ELCS_W_CLOSED_LOOP_INVALID`; the failure is retained and repaired before any
frontier experiment.
