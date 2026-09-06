# EXP22B: retained invalid mechanism-activation result

**Run:** `results/exp22b_elcs_kernel_repair/2026-09-01_165537`  
**Rows:** 1,400/1,400  
**Verdict:** `ELCS_F_KERNEL_INVALID`; 15/16 gates

The two v1 structural repairs close the substantive failures. All 200
zero-loss rows are terminally certified; every scheduled region is collision
free; there are zero false-valid edge-frames and owner-lock violations; all
200 state-loss rows recover; and all 200 owner-reconfiguration rows wait past
their fence and return to full terminal certification.

The sole failed gate requires every reconfiguration row to activate automatic
recolor. The frozen request `node 2 -> slot N` creates a same-slot conflict in
all 100 N5 rows, which each execute one automatic recolor. It creates no color
conflict in the N10 ring2 graph, so all 100 N10 rows correctly recover without
recolor. The aggregate is 100/200 activation, while the gate requires 200/200.

The gate is not relaxed post outcome and the run remains invalid. EXP22C keeps
the protocol and all parameters unchanged but corrects the test stimulus: in
each graph, node 2 requests the color of the first higher-ID conflict client
whose color is not used by node 2's lower-ID neighbors. This guarantees that
the requested tuple is locally feasible yet requires a real cascading recolor.
Fresh seeds are mandatory.
