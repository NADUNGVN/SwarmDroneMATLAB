# EXP22B: ELCS-F structural kernel repair

**Frozen before v2 randomized outcomes:** 2026-09-01  
**Parent negative run:** EXP22-K v1 `2026-09-01_122201`  
**Deterministic contracts:** 13/13, including all six v1 failure seeds  
**Tuning, closed-loop claims, promotion and submission claims:** prohibited

EXP22B repeats the same 2-cell, 7-condition, 1,400-row matrix on 100 disjoint
fresh seeds (`16041001:16041100`). It changes exactly two structural rules:

1. STATUS and GRANT transmitters use their unique node-ID minislot in the
   already charged `N`-minislot windows. Window size, lease, refresh lead,
   fallback window and DATA frame length are unchanged.
2. A node whose lower-ID neighbor changes onto its slot revokes refresh, waits
   at least a full lease horizon plus the owner/client fence, chooses the
   smallest color unused by its lower-ID envelope neighbors, and propagates
   the change upward. No node reads remote state outside decoded STATUS/GRANT.

All v1 gates remain. EXP22B adds the requirement that every owner-
reconfiguration row returns to full terminal certification and activates at
least one automatic recolor. A safe but permanently fallback result is no
longer sufficient for this condition.

This is structural development after a retained negative result, not a
confirmatory holdout. Passing EXP22B authorizes only continuous/closed-loop
integration of the candidate and mandatory prior-art references.
