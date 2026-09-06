# EXP23P — Invalid coherence-aware packet-kernel results

Run: `results/exp23p_coherence_packet_kernel/2026-09-04_172817`

Status: **invalid because two predeclared safety gates failed**.

## What passed

The frozen study completed all 1,800/1,800 unique rows over 50 fresh seeds,
N5/N10, three geometry cells and six channel cells. Eighteen of twenty gates
passed, including exact packet format and MTU closure, admissible/inadmissible
binding, cumulative-receipt liveness, blackout stimulus, retry stimulus,
control bounds, exact byte/recipient accounting and zero forbidden
information reads.

There were zero false-valid edge frames and zero certificates without fresh
claims. These diagnostics do not override the failed safety verdict.

## Failure

The run observed scheduled DATA collisions in 23 rows. Each offender repeated
under the same geometry across channel variants and produced two collided
recipient deliveries per protected frame. The permanent-response-blackout
gate also failed solely because its stimulated subset contained these
scheduled collisions; no blackout row reached global certification.

## Root cause

The receiver-lifted sender graph used only the physical potential-interference
matrix at intended receivers. The packet kernel, however, defines a detectable
transmission as `interference OR reach`. With the frozen 1.5 m DATA-neighbor
radius and 1.0 m interference radius, two senders serving the same intended
receiver could both lie outside the separately declared interference graph.
They were therefore assigned the same color even though the delivery model
correctly treated both intended signals as detectable and colliding.

EXP23O did not expose this defect because its sampled actual-conflict oracle
called the same incomplete graph builder. EXP23P is retained as a valid
falsification of that graph definition, not as evidence for the method.

## Frozen repair direction

The sender-conflict lift must use the effective detectability relation
`physical interference OR intended DATA reach`. A deterministic common-
receiver fixture where both intended links extend beyond the physical
interference graph is required as a regression test. The repaired graph and
oracle must then be revalidated on disjoint fresh seeds before packet-kernel
integration can proceed. No packet size, retry rule, lease rule or safety gate
is relaxed.
