# TCNS R2 generalization and actual-action witness report

## Status and scope

**Classification:** `R2_EVIDENCE_STRENGTHENED_WITH_QUALIFICATIONS`

- implementation commit used by the authoritative run: `a2cec3b`;
- authoritative run: `results/tcns_r2_generalization_validation/2026-09-08_161130`;
- MATLAB: R2025a (`MATLAB 25.1`);
- study type: new deterministic TCNS theory/generalization evidence;
- no scheduler, held-out seed, population-performance claim, or simulation-v1
  evidence was changed.

The earlier run `2026-09-08_155705` is retained. Its structural and witness
checks passed, but its practical-scale reference grid used inconsistent units
and is explicitly invalidated by `INVALID_PRACTICAL_DIAGNOSTIC.md`. It is not
used below.

## Cross-instance structural study

The complete preregistered Cartesian registry contained 72 cells:

- `N = 5, 7, 9`;
- deterministic `ring2`, `sparse4`, and `geometric` graphs;
- even- and odd-follower pinning;
- `H = 15, 25`;
- `D = 2, 4`.

All 72 cells satisfied the symmetric grounded Schur theorem scope. Across
their 1320 controller-relevant action rows:

| Check | Result |
|---|---:|
| structural fixed-response functionals nonidentifiable | 1320 / 1320 |
| identifiable/nonidentifiable conclusion stable on `1e-6`--`1e-14` grid | 1320 / 1320 |
| compressed-null and direct-row-space calculation agree | 1320 / 1320 |
| appending the scalar value row increases rank by one | 1320 / 1320 |
| raw numerical rank unchanged over the full tolerance grid | 608 / 1320 |
| selected 80-digit VPA checks completed | 72 / 72 |
| full coalition identifies each sender's complete value set | all sender/cells |

The double-precision normalized hidden residual ranges from
`3.0291171612e-6` to `0.9999887402`. The selected 80-digit checks range from
`3.0291171613e-6` to `4.1355661625e-3`; none is marginal to the declared
membership tolerances.

The raw-rank instability in 712 rows is retained and reported. It reflects
small singular values crossing different numerical rank cutoffs; it does not
change any of the 1320 row-space membership conclusions. The manuscript must
distinguish these two statements.

### Simultaneous-action dimension

Compression across actions is heterogeneous but structured:

| Graph | N | Leader action count `p_1` | Leader missing rank `r_1*` | Ratio |
|---|---:|---:|---:|---:|
| ring2 | 5 / 7 / 9 | 4 / 5 / 6 | 3 / 4 / 5 | 0.750 / 0.800 / 0.833 |
| sparse4 | 5 / 7 / 9 | 6 / 7 / 8 | 4 / 5 / 6 | 0.667 / 0.714 / 0.750 |
| geometric | 5 / 7 / 9 | 6 / 7 / 8 | 4 / 5 / 6 | 0.667 / 0.714 / 0.750 |

Every follower sender in the tested registry has `r_j* = p_j`. Thus shared
missing directions occur for the leader's ordinary-plus-pin action set, but
not for the follower action sets in these configurations. This pattern is
unchanged by the tested pin split and H/D values.

### Coalition heterogeneity

- `ring2` and `sparse4`: every sender-wise complete missing subspace requires
  the full N-agent coalition for N=5, 7, and 9.
- `geometric`, N=5: the graph exposes only leader-originating actions and the
  minimum coalition is all five agents.
- `geometric`, N=7: the leader value set requires all seven agents, whereas
  each follower-sender value set is identified by a five-agent coalition.
- `geometric`, N=9: the leader value set requires all nine agents, whereas
  each follower-sender value set is identified by an eight-agent coalition.

Therefore the former N=5 statement that all five agents are required remains
correct for that graph, but it cannot be generalized as “all agents are always
required.” The general result is the coalition row-space condition; coalition
size is topology/action dependent.

## Actual-action reachable-witness audit

The audit retained the accepted N=5 `ring2`/even-pin configuration with
`H=25`, `D=4`. For every catalog action it generated a real 0.01 m/s2
controller correction, held receiver memory, constructed a consistent initial
perturbation in the complete sender-history nullspace, and independently
replayed the saturated implementation while requiring the unsaturated regime.

| Action | q minus | q plus | normalized radius | sampled crossing fraction | failure |
|---|---:|---:|---:|---:|---|
| ordinary 1->2 | -3.475e-6 | +3.475e-6 | 0.1590 | 0.1875 | NONE |
| ordinary 1->5 | -5.344e-6 | +5.344e-6 | 0.1953 | 0.0625 | NONE |
| ordinary 2->3 | -5.392e-6 | +5.392e-6 | 0.01010 | 0.09375 | NONE |
| ordinary 3->2 | -8.519e-8 | +8.519e-8 | 0.0002666 | 0 | NONE |
| ordinary 3->4 | -3.198e-6 | +3.198e-6 | 0.009173 | 0.0625 | NONE |
| ordinary 4->3 | -5.223e-6 | +5.223e-6 | 0.01080 | 0 | NONE |
| ordinary 4->5 | -1.333e-7 | +1.333e-7 | 0.0003459 | 0 | NONE |
| ordinary 5->4 | -3.396e-6 | +3.396e-6 | 0.01099 | 0.0625 | NONE |
| pinned leader 1->2 | -3.449e-6 | +3.449e-6 | 0.2315 | 0.25 | NONE |
| pinned leader 1->4 | -5.002e-6 | +5.002e-6 | 0.2106 | 0.03125 | NONE |

Coverage is therefore:

- structural unit-response nonidentifiability: **10/10**;
- actual controller response tested: **10/10**;
- dynamically reachable, sender-indistinguishable, unsaturated opposite-sign
  witnesses: **10/10**;
- failures: **none**.

Independent replay maxima/minima were:

- sender-history mismatch: `7.980e-20`;
- affine/dynamic residual: `4.163e-16`;
- action-response mismatch: `0`;
- affine/oracle value mismatch: `4.066e-20`;
- minimum acceleration saturation margin: `0.9521 m/s2`.

This closes the previous two-action dynamic-witness gap for the frozen N=5
instance. It does not establish dynamic sign ambiguity for every graph, N,
action magnitude, operating point, or nonlinear UAV model.

## Practical-scale interpretation

The normalized information radius is meaningful for the two pin actions and
leader ordinary actions (0.159--0.232), about one percent for most follower
actions, and only `2.67e-4`/`3.46e-4` for ordinary 3->2 and 4->5. On the 32-point
dimensionally scaled deterministic grid, seven actions have at least one local
compatible interval crossing zero; three do not. The projection-sign
disagreement rate is nonzero for nine actions but is zero for ordinary 4->5.

These numbers show that the ambiguity is not uniformly important. The exact
existence result is 10/10, while practical magnitude is action dependent. The
32-point fractions are descriptive properties of the chosen local grid, not
population probabilities.

## Communication-cost audit

No causal protocol was added. The new evidence characterizes algebraic
missing-statistic dimension and coalition ownership only. The existing
ACK-like `DATA + 0.25 ACK` analysis remains a sensitivity/accounting screen on
the centralized diagnostic trajectory; it is not a measurement of a deployed
mechanism that constructs the missing statistic. One scalar dimension is not
one packet, and no packet/byte/airtime acquisition claim is warranted.

## Evidence hierarchy for the manuscript

1. **General theorem:** standard functional-identifiability specialization to
   a fixed communication-action value, plus the paper's decision-radius/regret
   and multi-action interpretations under their stated assumptions.
2. **Cross-instance structural evidence:** 1320/1320 action functionals violate
   sender-history identifiability in the 72-cell R2 registry.
3. **Sender-wise dimension and ownership:** leader-only compression recurs;
   minimum coalition size is topology dependent.
4. **Implementation-faithful decision consequence:** actual-action reachable
   opposite-sign witnesses cover 10/10 actions only for the frozen N=5 case.

## Required claim changes

Claims that may be strengthened:

- replace “two reachable witnesses” by “all ten N=5 controller-relevant
  actions have independently replayed actual-action witnesses”;
- state that the structural mechanism recurs in all 1320 preregistered
  cross-instance action rows;
- state that leader action values share missing directions throughout the
  registry, while tested follower action sets do not.

Claims that must remain qualified or be weakened:

- do not generalize dynamic 10/10 witness coverage beyond frozen N=5;
- do not state that every topology requires the full coalition;
- do not call raw numerical rank stable for all rows;
- do not imply that algebraic statistic dimension determines packet count or
  acquisition cost;
- do not turn deterministic local-grid fractions into statistical claims.
