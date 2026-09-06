# EXP23Q — Broadcast detectability-graph repair results

Run: `results/exp23q_broadcast_graph_repair/2026-09-04_173841`

Status: **BROADCAST_DETECTABILITY_GRAPH_REPAIR_VALID (19/19 gates)**.

The study completed 600/600 unique rows over 100 fresh seeds, N5/N10 and
three paired geometry cells. An independently implemented pair/receiver
oracle found zero actual-graph subset violations, zero same-color conflict
violations and zero direct receiver-delivery collision violations.

The repaired branch was strongly stimulated: 44,034 aggregate conflict
instances existed only because intended DATA reach extended beyond the
physical-interference graph. The study also observed 17,247 hidden-sender
edge instances. All 200 static/wide rows selected the 6.8 s target; the full
matrix contained 268 target, 284 contracted and 48 no-lease rows.

The repaired definition is therefore eligible for fresh packet-kernel
validation. EXP23Q does not retroactively validate EXP23O or EXP23P and makes
no closed-loop performance or submission claim.
