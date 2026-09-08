# R2.5 actual-action witness, fixed-response, and normalization audit

Authoritative replay:
`results/tcns_r2_5_adversarial_validation/2026-09-08_175427/`.

## Independent reconstruction

`tcnsInformationLimitsReplayWitness` loads the persisted N=5 initial
coordinates, reconstructs consistent receiver memories, runs
`distributedFormationPolicy` and `integrateFollowers`, recomputes the actual
terminal controller residual, constructs the candidate payload/action, and
then calls `tcnsCentralizedStateOracleValue`.  The oracle propagates the
finite-horizon baseline and action response directly; it does not evaluate
the affine witness-construction expression.

All 10/10 persisted actions pass.  Across the catalog:

- actual correction norm: 0.01 m/s2 for every endpoint, to numerical precision;
- action-response norm: `1.1383e-3` to `1.3895e-3` m;
- maximum sender-history mismatch: `7.980e-20`;
- maximum direct dynamic residual: `4.163e-16`;
- maximum paired response mismatch: 0;
- maximum affine/direct-oracle mismatch: `4.066e-20`;
- minimum saturation margin: `0.9521` m/s2;
- fixed initial-coordinate half-separation: `1e-4`;
- smallest absolute sign endpoint: `8.519e-8`, or 85,194 times the declared
  `1e-12` sign threshold.

Thus the smallest sign crossing is not a rounding-noise flip.  The test suite
also adds `1e-7` to one sender observation and, separately, to one action
response.  The independent validator rejects the first as
`INFORMATION_MISMATCH` and the second as `RESPONSE_MISMATCH`.

## Fixed-response checklist

For every pair:

- the command correction is recomputed from physical/source state minus the
  actual held payload and is identical between endpoints;
- `tcnsInformationLimitsActionMap` returns the same finite-horizon `g_a`;
- target indices and target payload values are identical;
- the packet class, sender, receiver, and payload semantics are identical;
- both trajectories stay in the same unsaturated controller branch;
- no DATA update occurs within the history, so the declared held-memory mode
  is identical.

No witness is reclassified: fixed-response consistency is 10/10.  This result
remains restricted to the frozen N=5 ring/even-pin instance, H=25, D=4, and
the declared no-update unsaturated histories.

## Practical-normalization definition

The reported primary number is

`normalized ambiguity = information radius / median(abs(q_reference))`.

For each action, the reference set contains 32 deterministic unsaturated
states centered on that action's witness fiber.  Directions use seed
`27022001 + actionIndex`; each position component has norm 0.05 m and each
physical velocity component has norm 0.05 m/s before multiplication by the
sample period.  All 32 states are valid for every action.  This is a local
diagnostic grid, not a population sample.

| Quantity across the 10 actions | Minimum | Q1 | Median | Q3 | Maximum |
|---|---:|---:|---:|---:|---:|
| information radius | `8.519e-8` | `3.198e-6` | `3.462e-6` | `5.223e-6` | `5.392e-6` |
| median absolute reference value | `1.490e-5` | `2.376e-5` | `3.143e-4` | `3.853e-4` | `5.337e-4` |
| RMS reference value | `2.412e-5` | `3.634e-5` | `4.213e-4` | `6.680e-4` | `1.043e-3` |
| IQR/1.349 reference scale | `1.968e-5` | `3.298e-5` | `3.066e-4` | `4.541e-4` | `5.899e-4` |
| radius / median absolute value | `2.666e-4` | `9.173e-3` | `1.090e-2` | `0.1953` | `0.2315` |
| radius / RMS value | `1.995e-4` | `5.169e-3` | `6.930e-3` | `0.1376` | `0.1446` |
| radius / (IQR/1.349) | `2.707e-4` | `6.070e-3` | `1.323e-2` | `0.1448` | `0.1752` |

The maximum 0.2315 occurs for pinned leader 1->2, whose median-absolute
denominator is the smallest among the ten actions.  It falls to 0.143 under
RMS scaling and 0.175 under IQR scaling.  Therefore the exact maximum is
denominator-sensitive, but the leader/pin cases remain order-0.1 under both
alternatives.  Conversely, the two weakest follower actions remain order
`1e-4` under all three definitions.  The manuscript reports the primary
definition once and retains both the maximum and the small-action boundary.

## Coalition distribution

The unit of analysis is one sender action set in one registry cell: 448 rows.
Independent exhaustive enumeration finds the same minimum size and
multiplicity as R2 for all 448.

| Scope | Minimum coalition size | Frequency | Fraction | Size/N | Multiple minimum coalitions |
|---|---:|---:|---:|---:|---:|
| N=5 | 5 | 88 | 1.000 | 1.000 | 0 |
| N=7 | 5 | 32 | 0.211 | 0.714 | 0 |
| N=7 | 7 | 120 | 0.789 | 1.000 | 0 |
| N=9 | 8 | 56 | 0.269 | 0.889 | 0 |
| N=9 | 9 | 152 | 0.731 | 1.000 | 0 |

Across all N, raw sizes 5, 7, 8, and 9 occur with frequencies 120, 120, 56,
and 152.  Every reported minimum coalition is unique in this registry.  This
is agent ownership, not the algebraic statistic dimension `r_j*`, and no
packet count or communication cost follows from the coalition size alone.
