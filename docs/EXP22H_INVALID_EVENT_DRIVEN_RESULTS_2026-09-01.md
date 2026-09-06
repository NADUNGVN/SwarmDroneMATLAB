# EXP22H invalid result: reconfiguration STATUS counter order

**Run:** `results/exp22h_elcs_event_driven_renewal/2026-09-01_191307`  
**Rows:** 1,400/1,400  
**Gates:** 19/20  
**Verdict:** `ELCS_F_KERNEL_INVALID`

All lease safety, certification, fallback, loss, state-loss, reconfiguration,
causality and analytical control-bound gates pass. The sole failure is the
event-driven STATUS partition: aggregate residual `-15,200` attempts.

The residual occurs only in owner-reconfiguration rows and is deterministic:
`-34` per N5 row and `-118` per N10 row. Inspection identifies two adjacent
ordering defects:

1. request/discovery counters were updated before fenced
   `tupleChangePending` nodes were removed from `statusTx`;
2. the intended force-status flag after applying a new tuple was immediately
   cleared by a misplaced assignment.

No GRANT without a decoded request occurred. The analytical bound passes with
maximum observed/bound ratio `0.982967`, and all 200 zero-loss rows certify by
frame N. Nevertheless, the run is not rescored because its frozen
implementation does not match the preregistered emission semantics.

EXP22I moves the fence exclusion before all counter/force updates and restores
the post-reconfiguration force flag. It repeats the full matrix on disjoint
fresh seeds with an explicit reconfiguration regression.
