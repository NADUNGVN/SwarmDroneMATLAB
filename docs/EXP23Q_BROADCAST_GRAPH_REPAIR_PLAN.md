# EXP23Q — Broadcast detectability-graph repair validation

Status: frozen before fresh-seed execution on 2026-09-04.

EXP23P falsified the first receiver-lift definition because the delivery
kernel detects `physical interference OR intended DATA reach`, while the graph
lift used physical interference alone. EXP23Q validates the repaired graph on
100 fresh seeds `16078001:16078100`, N5/N10 and the three frozen EXP23O
geometry cells (600 rows).

The repaired sender graph is the receiver lift of effective detectability
`I+ OR A`. Safety is checked with an independently implemented pair/receiver
enumeration and a direct receiver collision oracle; neither calls
`buildSenderConflictGraph`. The study must observe at least one conflict edge
that exists only because intended DATA reach extends beyond the physical
interference graph. It retains all EXP23O subset, coloring, horizon,
witness/MTU, self-revocation-fixture, causality and selector-stimulus gates.

A pass permits a fresh packet-kernel repair study. It does not retroactively
validate EXP23O or EXP23P and does not promote a closed-loop method.
