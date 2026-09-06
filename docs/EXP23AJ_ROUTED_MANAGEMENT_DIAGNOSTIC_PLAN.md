# EXP23AJ routed-management diagnostic plan

Frozen: 2026-09-06, before execution of the registered Monte Carlo traces.

## Purpose and scope

EXP23AI validated the single-transaction receiver-lifted closure on one common
PHY, but its management plane still used an all-to-all logical delivery matrix.
EXP23AJ removes that abstraction at the routing-primitive level. It asks whether
each logical control packet can be forwarded causally over the actual one-hop
data graph with collision-free relay slots, finite reliability, and exact
physical byte/airtime accounting.

This is a development diagnostic. It cannot validate closed-loop routed
management, repeated online renewal, topology robustness, or submission
readiness. The next study must integrate the routed outcomes and airtime into
the closure kernel on the common PHY.

## Mechanism fixed before the diagnostic

For source `s` and semantic recipient set `D`, lexicographic BFS constructs a
one-parent shortest-path multicast tree over the directed one-hop decode graph.
Only nodes with active children forward. Transmitters at the same tree depth
are colored on the receiver-lifted conflict graph, and depths are serialized;
therefore a child cannot forward before receiving the packet and duplicate
forwarding is zero by construction.

Every active relay repeats its broadcast `r` times within its assigned hop
block. With independent link-erasure probability `p`, a tree edge fails with
probability `p^r`. For `E` active tree edges,

`P_fail(route) = 1 - (1 - p^r)^E <= E p^r`.

The registered dimensioner chooses the smallest integer `r <= 20` for which
the exact failure is below `10^-3`. This is compared openly with repetition of
the entire end-to-end flood; the latter discards successful upstream progress
between repetitions.

Semantic recipients are fixed from protocol state transitions:

- PREPARE and COMMIT: affected nodes;
- QUIESCENT and RESPONSE: the initiator;
- CLAIM and LOCK-PROOF: witnesses of incident union-graph edges;
- self-delivery: local, with zero radio attempts;
- REVOKE: retiring-graph neighbors if separate revoke is ever enabled.

## Registered matrix

- Topologies: N={5,10,20} ring-2 graphs with symmetric leader-pin links, using
  the same construction as the accepted D-STR integration cells.
- Sources: every node; recipients: every other node for structural worst-case
  routing.
- Receiver interference: empty off-diagonal graph (spatial-reuse lower bound)
  and complete off-diagonal graph (conservative upper bound).
- Per-link erasure: {0.05, 0.20, 0.30}.
- PHY rate: 250 kbit/s; packet accounting uses the frozen 96-byte maximum and
  the EXP23AI affine-clock guard.
- Structural rows: 210.
- Monte Carlo: the deterministically worst reserved-slot source in each of the
  six size/interference cells; p=0.2, r=2, 10,000 trials per cell, independent
  seeds 16094501--16094506. The deliberately under-protected `r=2` produces a
  measurable failure rate and tests the exact probability rather than relying
  on observing rare `10^-3` events.
- Semantic routing: the retained EXP23AI diagnostic witness, using its actual
  online old/proposed physical-union graph and every possible sender/kind role
  in that migration (25 rows). These are reused calibration data, not fresh
  evidence.

## Frozen gates

Seventeen gates require: exact registry and valid retained parent; complete
unique matrices; connected direct graphs and finite TTL; admissible one-parent
trees; receiver-conflict coloring; causal depth ordering; minimum integer
repetition selection; exact reliability below `10^-3`; analytical union-bound
ordering; no-loss replay delivery; exact attempt/byte/airtime identities;
causal descendant silence after an upstream erasure; Monte Carlo agreement
within five registered binomial standard errors plus `1/n`; exact semantic
recipient selection; admissible semantic routes; a visible logical-clique
undercount negative; full-flood repetition no more efficient than hop-local
repetition in reserved slots; and all downstream claim flags remaining false.

No gate or tolerance may be changed after the registered run begins.
