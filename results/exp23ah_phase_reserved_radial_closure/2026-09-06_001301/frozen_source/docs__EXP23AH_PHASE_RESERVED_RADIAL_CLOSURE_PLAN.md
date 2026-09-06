# EXP23AH phase-reserved radial closure validation plan

Frozen: 2026-09-06, before any registered seed is executed.

## Why another experiment is required

EXP23AG `2026-09-05_142942` confirmed the one-sided radial geometry result on
50 fresh seeds: all 200 protected closure rows satisfied the radial theorem,
the maximum inward-contraction ratio was 0.865576, and every realized
physical/sender graph stayed inside its certificate. The overall experiment
nevertheless remains **invalid at 22/25 gates**. One seed exhausted its
PREPARE/QUIESCENT budget and another only partially received COMMIT, so gates
that required deterministic 50/50 completion under nonzero IID loss failed.

Finite retry cannot imply deterministic completion. EXP23AH therefore adds a
phase-reserved probability certificate and tests terminal safety
conditionally on the phase reached. It does not relabel EXP23AG.

## Mechanism repair and calibration record

Kernel v2 makes QUIESCENT state persistent: after a node has received a valid
PREPARE and stopped scheduled DATA, it advertises QUIESCENT at every remaining
PREPARE retry opportunity until the initiator receives it. A repeated
PREPARE reception in the same frame is no longer required. This is a protocol
change, not a gate relaxation.

Only already-used EXP23AG seeds 16094201--16094250 were used to choose the
phase budget and recheck geometry. Seven dense PREPARE opportunities, fifteen
dense CLAIM opportunities and six COMMIT opportunities fit exactly inside the
48-frame mission when the request occurs at 4 s. The first eight CLAIM rounds
form the evidence prefix and the last seven form a guaranteed RESPONSE suffix.

An initial 0.21 m leader-pair radial budget passed reliability but failed the
calibration radial gate (maximum ratio 1.054810). It was increased once to
0.23 m, 3.8% above the observed maximum inward contraction of 0.221510 m.
Because the radius enters graph construction, this makes the certificate more
conservative rather than forgiving a realized omitted edge. The rerun
`2026-09-06_000317` passed 50/50 normal completion, 200/200 protected radial
contracts, maximum ratio 0.963932, and maximum transaction failure bound
0.000760321. Both calibration runs remain development-only.

## Reliability certificate

Let `p_P,p_Q,p_C,p_L,p_R,p_M` bound independent per-recipient erasure for
PREPARE, QUIESCENT, CLAIM, LOCK-PROOF, RESPONSE and COMMIT. With `A` persistent
PREPARE/QUIESCENT opportunities, the failure probability for one remote node
is

`p_P^A + sum_{r=1}^A p_P^(r-1)(1-p_P)p_Q^(A-r+1)`.

The first term is failure to receive any PREPARE. The summand conditions on
the first PREPARE at round `r` and failure of all remaining QUIESCENT
advertisements. A union bound covers all remote affected nodes.

The evidence prefix contains `E=8` attempts. For every affected endpoint whose
witness is remote, failure is bounded by `p_C^E`; an outside endpoint uses the
15-frame LOCK-PROOF window and contributes `p_L^15`. Conditional on all
evidence being present after the prefix, every nonlocal witness has seven
remaining RESPONSE opportunities and contributes `p_R^7`. Finally each remote
affected node has six COMMIT opportunities and contributes `p_M^6`.

The sum of these four union bounds is computed separately for every online
geometry. The registered gate requires a feasible disjoint phase reserve and
an upper bound below `10^-3` for every normal closure row. No empirical success
count substitutes for this bound.

## Frozen matrix

- 50 untouched seeds, 16094301--16094350. They are disjoint from design seed
  16094001, EXP23AF seeds 16094101--16094120, and EXP23AG/calibration seeds
  16094201--16094250.
- N=10, two-hop ring DATA graph, 10.5 s mission, decision at 4 s.
- The EXP23AG command, controller, IID-20 DATA/control loss, 250 kb/s common
  PHY, bounded affine clocks and six paired arms are retained.
- Pairwise budgets are 0.11 m by default, 0.18 m for commanded-node pairs and
  0.23 m for leader pairs. Interference radius remains 0.97 m.
- Protected slots 11--15 give each currently suppressed affected sender one
  distinct emergency opportunity per frame.
- 300 registered rows total. No setting may change after execution begins.

## Frozen decision contracts

EXP23AH requires 27/27 gates:

1. Registry/source hashes are finite and all 50 registered seeds are disjoint
   from every design/calibration set.
2. EXP23AG remains invalid at 22/25 gates.
3. The phase-reserved diagnosis is locked as calibration-only and non-fresh.
4. All 300 seed/arm rows are unique and present.
5. Seed and arm coverage exactly matches the registry.
6. One exogenous PHY trace is paired across all arms per seed.
7. Decision states and pre-PREPARE schedules are prefix-identical.
8. Each seed has one causal geometry/selector certificate across closure arms.
9. Every certificate has a slot-changing receiver-lifted stimulus with at
   least one changed sender edge not incident on node 2.
10. Union coloring, packet MTU and protected-slot separation hold.
11. Kernel v2, persistent QUIESCENT, control attempt/byte bounds, actual-union
    and final-coloring invariants hold.
12. Motion starts exactly at authorized graph activation only.
13. PREPARE blackout leaves the barrier open and blocks motion.
14. Every online normal geometry has a feasible phase reserve and transaction
    failure bound below `10^-3`.
15. Normal empirical completion is at least 95%; any finite-loss failure must
    end in a certified suppressed safe state rather than an unsafe activation.
16. RESPONSE blackout is conditional fail-silent: before-barrier aborts do not
    move; after-barrier runs retain the entire affected closure suppressed.
17. COMMIT blackout is conditionally safe: pre-COMMIT evidence failures retain
    all nodes suppressed; if COMMIT is reached, only the initiator may
    reactivate.
18. Every currently suppressed sender in protected arms receives its own
    emergency slot each frame with no collision.
19. The swept radial construction premise holds for every omitted pair.
20. Every protected arm satisfies the radial-contraction theorem.
21. Every protected realized physical and receiver-lifted sender graph is a
    subset of its certificate.
22. Removing emergency service under RESPONSE blackout violates the radial
    contract and worsens mission RMSE for every paired seed.
23. Protected rows have zero kernel, receiver and observed collision.
24. Receiver DATA success/erasure replay is exact with no queue skip or
    control/DATA overlap.
25. Management attempts and airtime equal the registered schedule; byte totals
    stay within analytical bounds.
26. Affine timing equations and causal forbidden-read checks pass exactly.
27. Protected trajectories remain finite and safe. Routed management,
    repeated online renewal, broad robustness and submission claims remain
    forbidden.

Passing validates a single online radial closure transaction with an explicit
IID finite-retry reliability bound. It is necessary evidence, not the final
IoT-J claim package.
