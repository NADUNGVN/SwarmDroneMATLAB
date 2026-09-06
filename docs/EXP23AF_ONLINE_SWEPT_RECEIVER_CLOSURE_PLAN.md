# EXP23AF online swept receiver-closure validation plan

Frozen: 2026-09-05, before registered execution.

## Question

Can a receiver-lifted schedule closure be constructed causally from the
observed swarm state and a public formation command, then keep the realized
closed-loop physical and sender-conflict graphs inside its swept certificate
while the closure transaction and DATA packets share one lossy PHY?

This experiment tests online plant/tube integration. It does not test routed
multi-hop management, broad robustness, or a submission claim.

## Fixture development boundary

Seed 16094001 was used only to develop and smoke-test the fixture and is
excluded from the registered matrix. The frozen command moves node 2 from its
nominal `[1.2, 0, 0]` offset to `[1.3, 0.1, 0]` over 2 s. On the excluded
seed, this small command produced three new sender-conflict edges, including
one receiver-lifted edge not incident on node 2, and required a slot change.

Pairwise relative tracking radii are 0.11 m by default, 0.21 m for pairs
containing the leader, and 0.18 m for pairs containing the commanded node.
The interference radius is 0.97 m. These values and the command are frozen;
no registered seed may be used to change them.

## Frozen matrix

- 20 previously unused registered development seeds, 16094101--16094120.
- N=10, two-hop ring DATA neighborhood, formation scale 2.
- Six paired arms per seed, 120 rows total:
  periodic IID-20; normal closure with protected emergency DATA; RESPONSE
  blackout with and without protected emergency DATA; PREPARE blackout with
  protected emergency DATA; and COMMIT blackout with protected emergency
  DATA.
- The closure decision is made at 6 s from the observed relative state and
  the public command. All arms use the same seed-level exogenous PHY trace,
  and all closure arms must have an exactly identical pre-decision state and
  pre-PREPARE schedule prefix.
- The candidate schedule colors the union of the observed and swept proposed
  receiver-lifted conflict supergraphs. Retiring slots are 1--10. Protected
  slots 11--15 assign one distinct DATA opportunity per currently suppressed
  affected sender per frame.
- DATA and management erasure probability 0.20, 250 kb/s PHY, 96-byte DATA,
  and at most 96-byte control packets.
- Affine clocks have offset <=0.25 ms and drift <=40 ppm. The guard is
  calculated by `continuousTdmaGuardBound` over a 30 s reset horizon.
- PREPARE/CLAIM retries use the locked bounded-retry configuration inherited
  from EXP23AB. The complete common-PHY mapping is inherited from EXP23AE.

## Frozen decision contracts

The registered run requires 24/24 gates:

1. Registry hash is finite and the smoke seed is excluded.
2. Canonical EXP23AE and EXP23AB parents retain all of their gates.
3. All 120 seed/arm rows are present and unique.
4. Seed and arm coverage matches the registry exactly.
5. Every seed uses one identical exogenous PHY trace across arms.
6. All closure arms have identical decision states and pre-PREPARE prefixes.
7. Every seed has one identical online geometry certificate across closure
   arms.
8. Every certificate is admissible, changes a slot, and contains at least one
   changed sender edge not incident on node 2.
9. Candidate union coloring, control packet bounds, and protected-slot
   separation all hold.
10. Command motion begins exactly at authorized graph activation and is absent
    otherwise.
11. PREPARE blackout leaves the barrier open and blocks motion.
12. Normal IID-20 closure authorizes motion and fully reactivates all affected
    nodes.
13. RESPONSE blackout authorizes the certified graph but retains every
    affected node in the suppressed closure state.
14. COMMIT blackout authorizes the graph but remains partially suppressed and
    collision-free.
15. In every protected arm, each currently suppressed sender is assigned its
    own unused emergency slot; emergency opportunities do not collide.
16. Every protected arm satisfies the frozen pairwise swept-tube bounds.
17. Every protected arm's realized physical and sender-conflict graphs are
    subsets of the certified swept union at every sampled time.
18. Removing protected service under the paired RESPONSE blackout must visibly
    break the tube certificate and worsen mission RMSE; this is a negative
    mechanism comparator, not a supported operating point.
19. Supported arms have zero kernel, receiver, and observed collision frames.
20. Scheduled receiver-level successes/erasures replay exactly, with no queue
    skip or cross-plane overlap.
21. Management attempts and airtime equal their registered schedule values.
22. Affine timing is conflict-free and satisfies its analytical equations.
23. All arms remain finite and pass the registered closed-loop safety check.
24. No future-random or receiver-truth reads occur, and the registry continues
    to forbid routed-management, robustness, fresh-seed, and submission claims.

Mission RMSE, minimum separation, airtime, latency, and control traffic are
reported descriptively. No favorable performance ranking is required for a
valid integration result. If any gate fails, EXP23AF is invalid and the
mechanism must be repaired without weakening the registered contracts.
