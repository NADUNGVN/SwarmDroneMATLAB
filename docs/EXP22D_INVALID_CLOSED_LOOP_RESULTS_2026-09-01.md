# EXP22D invalid result: fallback saturation mismatch

**Run:** `results/exp22d_elcs_closed_loop_integration/2026-09-01_173320`  
**Matrix:** 120/120 rows complete  
**Verdict:** `ELCS_F_CONTINUOUS_INTEGRATION_INVALID`  
**Gates:** 14/17

## What passed

The complete paired run has zero false-valid edge-frames, owner-lock
violations, certified scheduled collisions, cross-plane overlaps, future
random reads, receiver-truth decision reads, protocol invariant violations,
unsafe rows and divergent rows. The affine clock equations close to
`4.44e-16 s`, the minimum inter-group gap is positive (`0.177 ms`), and all
STATUS/GRANT recipient and 32-byte airtime accounts close.

These facts validate the lease/clock/control-plane composition but do not make
the closed-loop integration valid.

## Failure

Three preregistered DATA gates failed:

1. 46 scheduled opportunities were skipped because the source queue was
   empty;
2. precomputed kernel receiver masks therefore did not equal all event-engine
   outcomes; and
3. completed event collision frames did not equal the saturated-kernel
   witnesses.

The 46 skips are exactly 23 logical skips repeated in the paired zero/affine
arms. An exhaustive reconstruction over all 60 unique seed/cell schedules
found exactly 23 cases where the same invalid node was selected in both ELCS
fallback slots inside one 20-ms state-generation interval. All 23 were
fallback/fallback pairs; no certified scheduled or mixed pair contributed.

The controller source uses latest-generated-wins admission and no retry. Once
the first fallback opportunity consumes the pending state, the second
opportunity cannot carry new information. Because the isolated kernel assumed
saturated DATA, retaining its collision mask after one transmitter is absent
can also create a counterfactual collision outcome.

Aggregate evidence is paired in both clock arms:

- N5: 8 skips per arm, 26 expected versus 16 observed collision frames over
  30 rows;
- N10: 15 skips per arm, 56 expected versus 53 observed collision frames over
  30 rows.

## Interpretation and repair boundary

This is not a clock, lease-safety or controller-stability failure. It is a
cross-layer design error: the fallback access rule permits redundant attempts
faster than the source can create a new latest state, while the replay layer
assumes every selected transmitter is present.

The gates are not relaxed and the performance table is not used for method
promotion. The minimal protocol repair is to allow an uncertified node at most
one fallback attempt per ELCS frame, selecting the first eligible fallback
minislot on its frozen random trace. This preserves the probability of at
least one attempt, `1-(1-p)^W`, while eliminating same-frame duplicate state
attempts. The repair must first repeat the full kernel matrix on disjoint fresh
seeds, then repeat closed-loop integration on another disjoint seed set.
