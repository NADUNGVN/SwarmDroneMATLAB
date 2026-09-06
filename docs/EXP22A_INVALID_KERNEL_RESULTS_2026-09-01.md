# EXP22-K v1: retained invalid ELCS-F kernel result

**Run:** `results/exp22_elcs_kernel_falsification/2026-09-01_122201`  
**Rows:** 1,400/1,400  
**Verdict:** `ELCS_F_KERNEL_INVALID`; 13/15 gates

The safety invariant survived all registered conditions: there were zero
scheduled collision frames, false-valid edge-frames, owner-lock violations,
stale accepts and future accepts. DATA erasure left the schedule-state hash
exactly unchanged, all 200 directed-GRANT-blackout clients remained
uncertified, every state-loss row recovered, and every requested owner change
waited beyond its release fence.

The candidate nevertheless failed its frozen liveness gates.

1. Six of 100 N10 zero-loss rows were temporarily uncertified at the arbitrary
   terminal frame. Every one had first reached full certification at frame
   16--22 and spent at least 96.45% of node-frames certified. The failure is a
   recurrent lease-refresh outage caused by random collisions in STATUS/GRANT
   control minislots, not failure to acquire initially.
2. The state-loss path recovered in all 200 rows, but the same six paired N10
   traces were transiently uncertified at the terminal frame, so the compound
   recovery gate failed.
3. N5 owner reconfiguration changed node 2 from slot 2 to slot 5 after the
   fence. Node 5 retained slot 5, correctly lost certification and remained in
   fallback. Safety held, but the fixed coloring rule had no cascading repair.

No gate is relaxed and the run is not reclassified. The result motivates two
structural repairs with no additional airtime window:

- assign STATUS and GRANT minislots deterministically by node ID, since the
  frozen window already contains `N` minislots; and
- when a lower-priority tuple change conflicts with a client's color, stop
  refreshing, wait one complete lease horizon plus fence, recolor, and let the
  repair cascade upward by ID.

The six observed N10 zero-loss seeds are retained as regression witnesses.
EXP22B must use disjoint fresh seeds for randomized validation.
