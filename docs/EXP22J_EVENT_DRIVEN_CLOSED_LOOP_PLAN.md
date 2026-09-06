# EXP22J: event-driven ELCS closed-loop integration

**Frozen before randomized outcomes:** 2026-09-01  
**Upstream:** EXP22I 20/20  
**Stage:** redesigned-candidate model integration  
**Performance promotion, robustness and submission claims:** prohibited

- Seeds: `16051001:16051030`.
- Cells: N5 6-DOF zero-loss and N10 ring2 zero-loss.
- Arms: full-mission guard with zero clock and paired bounded affine clock.
- Matrix: 120 trajectories.
- PHY, guard, fallback and all event-driven kernel parameters are frozen from
  EXP22I.

All 17 EXP22E closed-loop gates remain. Added event-driven gates require exact
STATUS partition, zero GRANT without decoded request, zero-loss control within
the analytical bound, and certification by frame N for both clock arms.

Passing authorizes a fresh targeted periodic kill-test repeat; it is not a
performance claim by itself.
