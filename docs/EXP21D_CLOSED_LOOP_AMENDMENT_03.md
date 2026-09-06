# EXP21D-CL scientific amendment 03

**Date:** 2026-09-01  
**Invalidated run:**
`results/exp21d_closed_loop_integration/2026-09-01_074819`  
**Completed matrix:** 180/180 rows  
**Automatic verdict:** `DSTR_CLOSED_LOOP_INTEGRATION_INVALID` (16/17 gates)

## Failure

The only failed gate was the exact DATA collision witness. The closed-loop
simulator augments `cfg.swarm.A` with every declared leader-pin link before it
constructs DATA receiver masks. The D-STR kernel graph had been built from
`cfg.swarm.A` before that augmentation. For the N=10 cell, the controller pins
followers 2, 4, 6, 8 and 10 to leader 1, while the pre-augmentation ring graph
contains only followers 2 and 10 as leader neighbors. Kernel and event engine
therefore evaluated different receiver/interference graphs.

This explains both signatures of the failure: every N=10 oracle-warm row had
one repeated conflict per schedule cycle, and a subset of native rows had
additional event-engine collisions absent from their kernel witness.

## Correction

Version 3 applies all leader-pin links to the physical graph first, then
symmetrizes it, and passes that exact matrix to both the D-STR kernel and the
closed-loop event engine. A new N=10 end-to-end contract checks equality of
scheduled and realized collision witnesses. The native schedule is also built
once per seed/cell and reused by native/warm arms; this changes computation
only, not the schedule or outcome.

The v3 registry uses new seeds `16036201:16036230`. No v2 outcome is rescored,
reused or interpreted for performance claims.

