# EXP23X amendment 01 — remove remote receipt-state scheduling

Superseded run:
`results/exp23x_local_union_migration_kernel/2026-09-04_232607`.

The run completed 3,000 rows and its registered numerical gates passed, but a
manual causal audit found that neighbor LOCK-PROOF transmissions were enclosed
by the revoker's private `transactionActive` state. They therefore stopped
when the revoker received all responses, even though the proof sender had no
causal stop indication. The run is retained as a superseded development
artifact and cannot authorize common-PHY integration.

The repaired kernel gives each neighbor a fixed, declared
`lockProofRepeatFrames` window starting at eligibility. This schedule is
independent of remote delivery or receipt state. A witness emits a RESPONSE
entry only when it receives the revoker's current-frame CLAIM and already has
the neighbor proof. Once the revoker receives all entries it stops its own
CLAIM locally; witnesses then stop causally because no new CLAIM arrives.

Attempt and byte bounds are updated to charge the entire fixed proof window
plus worst-case CLAIM/RESPONSE retries. No outcome gate is weakened. The full
3,000-row matrix must be rerun and the earlier run remains visible.
