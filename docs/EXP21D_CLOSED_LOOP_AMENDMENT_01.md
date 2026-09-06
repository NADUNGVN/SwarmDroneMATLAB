# EXP21D-CL operational amendment 01

**Time:** 2026-09-01, after batch 1 checkpoint  
**Run:** `results/exp21d_closed_loop_integration/2026-09-01_074242`  
**Status when applied:** 18/180 rows complete; no performance table or gate
result had been inspected.

MATLAB failed to create the configured process pool and automatically fell
back to serial execution. Because the `parfor` statement retried pool creation
at every six-group batch, the runner was stopped after the first complete
checkpoint. The loop keyword was changed from `parfor` to `for`, and the same
run is resumed from its registry-validated checkpoint.

This amendment changes only task scheduling. It does not change the registry,
seed set, cell/arm matrix, source-mapped D-STR kernel, trace generation,
closed-loop simulator, metrics, gates or analysis. The 18 completed rows are
retained and will not be recomputed.

