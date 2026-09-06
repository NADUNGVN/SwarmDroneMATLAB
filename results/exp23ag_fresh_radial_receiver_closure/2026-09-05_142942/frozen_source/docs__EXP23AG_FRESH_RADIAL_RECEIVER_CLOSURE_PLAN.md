# EXP23AG fresh radial receiver-closure validation plan

Frozen: 2026-09-05, before registered execution.

## Why EXP23AF remains invalid

The canonical EXP23AF run `2026-09-05_135215` passed 23/24 gates but failed
an omnidirectional Euclidean tracking-tube gate: the maximum protected-arm
ratio was 1.166702. That result is retained as invalid.

A posthoc diagnosis on the same 20 seeds found that the violation was mainly
tangential to pairwise separation. It motivated, but cannot confirm, the
one-sided contract below. The diagnostic is explicitly not fresh evidence.

## Mathematical question

For pair `(i,j)`, let `rbar_ij(t)` be its public nominal relative position,
`r_ij(t)` its realized relative position, `R_I` the interference radius and
`b_ij` its frozen radial-contraction budget. Define

`delta_ij(t) = max(0, ||rbar_ij(t)|| - ||r_ij(t)||)`.

The swept graph includes an edge whenever the minimum nominal distance is at
most `R_I+b_ij`. Therefore, for every omitted pair,

`min_t ||rbar_ij(t)|| > R_I+b_ij`.

If `delta_ij(t) <= b_ij`, then

`||r_ij(t)|| >= ||rbar_ij(t)||-b_ij > R_I`,

so an omitted physical conflict cannot occur. An arbitrary tangential or
outward error is irrelevant to this implication, and a pair already included
in the physical supergraph needs no non-edge certificate. EXP23AG tests every
premise, radial bound, implication and realized graph on new seeds.

## Frozen matrix

- 50 untouched registered seeds, 16094201--16094250.
- The design seed 16094001, calibration/diagnostic seeds
  16094101--16094120, and theorem witness 16094113 are excluded.
- N=10; the same command, pair budgets, interference radius, controller,
  bounded-retry closure, parallel protected DATA service, affine clocks and
  six paired arms as frozen for EXP23AF.
- No radius, command, fault, retry, service or gate changes are permitted
  after any registered seed is executed.
- 300 rows total. Vector-error tube ratios remain descriptive so that the
  original negative result cannot be hidden.

## Frozen decision contracts

EXP23AG requires 25/25 gates:

1. Registry/source hashes are finite and all fresh seeds are disjoint from
   design and calibration seeds.
2. The canonical EXP23AF parent remains `INVALID` at 23/24.
3. The radial diagnosis remains marked posthoc and non-confirmatory.
4. All 300 seed/arm rows are present and unique.
5. Seed and arm coverage matches the registry exactly.
6. One exogenous PHY trace is paired across all arms of each seed.
7. Decision states and pre-PREPARE schedule prefixes are exactly paired.
8. Each seed uses one causal geometry/selector certificate across closure
   arms.
9. Every seed has an admissible slot-changing receiver-lift stimulus with at
   least one changed sender edge not incident on node 2.
10. Union coloring, MTU and protected-slot separation hold.
11. Motion starts exactly at authorized graph activation only.
12. PREPARE blackout keeps the barrier open and blocks motion.
13. Normal IID-20 closure fully reactivates all affected nodes.
14. RESPONSE blackout activates the certified graph but retains the complete
    affected closure in fail-silent state.
15. COMMIT blackout remains partially suppressed and collision-free.
16. Every suppressed protected sender receives one distinct emergency slot
    per frame.
17. The swept radial construction premise holds for every omitted pair and
    sampled time.
18. Every protected arm satisfies the radial bound and theorem implication.
19. Every protected realized physical and receiver-lifted sender graph is a
    subset of its certificate.
20. The paired no-emergency RESPONSE blackout violates the radial contract
    and has worse mission RMSE on every seed.
21. All protected cells have zero kernel, receiver and observed collision.
22. Receiver DATA success/erasure replay is exact with no queue skip or
    cross-plane overlap.
23. Management attempts and airtime equal the registered schedule; scheduled
    control-byte totals are archived and respect the MTU gate.
24. Affine timing equations and forbidden-read checks pass exactly.
25. All trajectories remain finite and safe; routing, repeated renewal,
    broad robustness and submission claims remain forbidden.

Passing EXP23AG validates only the fresh-seed, one-command radial closure
contract under the frozen model. It does not erase EXP23AF, establish a
general disturbance bound, validate routed management, or make the study
submission-ready.
