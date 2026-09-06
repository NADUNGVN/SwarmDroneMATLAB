# EXP22C: ELCS-F activation-corrected kernel validation

**Frozen before randomized outcomes:** 2026-09-01  
**Parent run:** EXP22B `2026-09-01_165537`, retained invalid at 15/16 gates  
**Protocol/parameters:** unchanged from EXP22B  
**Deterministic contracts:** 14/14  
**Promotion and submission claims:** prohibited

EXP22C repeats the complete 1,400-row matrix on disjoint seeds
`16042001:16042100`. Its only change is the owner-reconfiguration stimulus.

The initial priority coloring is computed from the registered conflict graph.
For reconfiguration node 2, the condition selects the first higher-ID conflict
client whose color is not occupied by a lower-ID conflict neighbor of node 2.
Node 2 requests that color. The request is therefore feasible for node 2 but
necessarily collides with an existing higher-ID client color, forcing the
automatic revoke/fence/recolor cascade in both topologies.

Every EXP22B gate remains unchanged. In particular, every reconfiguration row
must both return to full terminal certification and record at least one
automatic recolor. No result from EXP22B or its seeds contributes to the
EXP22C randomized verdict.
