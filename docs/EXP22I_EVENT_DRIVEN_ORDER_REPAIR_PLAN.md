# EXP22I: event-driven emission-order repair

**Frozen before randomized outcomes:** 2026-09-01  
**Parent invalid run:** EXP22H `2026-09-01_191307`, 19/20 gates  
**Protocol parameters and decision gates:** unchanged  
**Promotion and submission claims:** prohibited

Two implementation-order repairs are made:

1. `tupleChangePending` nodes are removed from request and STATUS masks before
   force flags and request/discovery counters are updated;
2. a node that applies a reconfigured tuple retains `forceStatusRequest=true`
   until its next eligible transmitted STATUS.

The lease, grant, fence, coloring, fallback and event-driven discovery/renewal
rules are unchanged. EXP22I repeats all seven conditions for seeds
`16050001:16050100` and both cells. Every EXP22H gate remains, including the
analytical zero-loss control bound and STATUS partition. A deterministic
regression additionally requires exact per-row partition in a forced
reconfiguration and a request STATUS immediately after the applied tuple.
