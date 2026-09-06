# EXP23AN full-detectability routed-management plan

Frozen: 2026-09-06, before execution of seeds 16094801--16094806.

## Why EXP23AJ--AM is superseded

An independent audit after EXP23AM found that the route conflict graph used
only the explicit physical-interference matrix and selected multicast-tree
edges. A receiver can also detect any sender connected by a direct one-hop
decode edge even when that edge is not the selected parent edge. Because the
old simulator consumed the planner's conflict graph, its zero-collision check
was circular.

The independent oracle rejected 30/70 all-source legacy plans under the
spatial-reuse boundary: 1 at N=5, 9 at N=10 and all 20 at N=20. It also rejected
5/24 nonlocal semantic routes on the online N=10 fixture, including PREPARE and
COMMIT. The EXP23AJ--AM machine artifacts and verdicts remain unchanged, but
their physical-routing interpretation is explicitly superseded.

## Frozen repair

1. Sender-task detectability is the union of explicit physical interference,
   the full directed one-hop decode graph, and the task's intended tree edges.
2. Half-duplex conflict remains explicit whenever a receiver transmits in the
   same slot.
3. The route planner colors this complete receiver-lifted conflict graph.
4. Replay v3 independently recomputes every receiver collision from physical
   interference, full direct reach and half-duplex state; it does not trust the
   planner conflict matrix.
5. Routing tree, semantic recipients, hop-local reliability, integer bytes and
   derived-airtime equations are unchanged.

Calibration before freezing found that the repair adds at most two base slots
in the all-source structural set and one base slot in the semantic fixture.

## Registered execution and gates

EXP23AN repeats the complete EXP23AJ matrix: 210 structural routes over
N={5,10,20}, two interference boundaries and p={0.05,0.20,0.30}; 60,000
simulator Monte Carlo trials at p=0.2/r=2 using new seeds
16094801--16094806; and all 25 semantic sender-kind routes. It retains the
exact reliability, causality, packet, accounting, negative-comparator and scope
gates.

Two new gates make 19 total:

- the independent audit must reproduce exactly 30 rejected structural and 5
  rejected semantic legacy plans while retaining the EXP23AM machine verdict;
- the independent oracle must accept all 94 corrected plans, every no-loss,
  Monte Carlo and semantic replay must report zero collision, and all nonlocal
  replays must use v3.

Passing validates only the corrected single-packet routed-management primitive.
Multi-origin common-PHY scheduling, closed-loop routed delivery, online renewal,
broad robustness, fresh confirmatory evidence and submission readiness remain
false.
