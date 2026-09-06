# EXP21D-CL scientific amendment 02

**Date:** 2026-09-01  
**Invalidated run:**
`results/exp21d_closed_loop_integration/2026-09-01_074242`  
**Completion at stop:** 18/180 rows; no summary, paired comparison, gates or
performance verdict generated.

## Failure

The v1 oracle-warm arm copied the native D-STR terminal assignment. A later
seed did not have a resolved, collision-free terminal assignment at the frozen
1200-frame horizon, so the warm-arm constructor stopped. Extending the horizon
or dropping that seed after opening the run would make the reference depend on
observed native behavior and is prohibited.

## Correction

Version 2 defines the oracle-warm reference independently of the native
terminal state. At time zero it installs a deterministic centralized greedy
coloring of the declared sender conflict graph, in ascending node order. It
retains the five idle D-STR management slots per superframe and generates no
management attempts. The native arm, its parameters and its 1200-frame horizon
are unchanged, so native non-resolution remains an observed failure rather
than becoming a construction error in another arm.

The registry version changes from v1 to v2 and uses new seeds
`16036101:16036130`. No v1 trajectory is reused or interpreted.

