# EXP23Z — Local migration graph-input closed-loop plan

Status: frozen development protocol before the 120-trajectory execution.

EXP23Z asks one narrow question: does the repaired local union-graph
migration executor retain its packet, timing and fail-silent contracts when
its DATA opportunities drive the N=10 swarm controller?

The matrix uses 20 seeds and six paired arms: periodic and migration under
zero loss; periodic and migration under IID-20 DATA loss plus IID-20
migration-control loss; and migration with either REVOKE or permanent
RESPONSE blackout. All arms use the same condition-specific absolute DATA
random field and the same affine-clock draws.

At the midpoint of the 12-second mission, one causal receiver-lifted graph
transition adds exactly one edge incident to UAV 10. The retiring coloring
uses slot 7 for UAV 10; the certified union forces slot 9. The simulator
switches from the old physical detectability graph to its union at the same
registered event. DATA receiver masks, half-duplex exclusions, IID erasures
and collisions are bound independently before replay.

The 16 gates cover matrix identity, parent evidence, pairing, the exact local
graph stimulus, causal instrumentation, clock safety, replay/accounting,
normal reacquisition, fail-silent RESPONSE blackout, REVOKE-loss
independence and closed-loop safety. RMSE and total offered airtime are
descriptive development outcomes, not pass gates.

Scope is deliberately restricted. The geometry snapshots create a valid
causal graph input, but are not yet generated from the online plant state in
the same trajectory. Consequently, even a fully valid result cannot support
a fresh-seed or submission claim. The next gate is online state/tube coupling
with an independent actual-trajectory subset oracle.
