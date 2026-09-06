# EXP23T — Static coherence common-PHY results

Run: `results/exp23t_static_coherence_closed_loop/2026-09-04_180732`

Status: **STATIC_COHERENCE_COMMON_PHY_SURVIVES** with 17/17 validation gates.

All 300/300 trajectories completed over 100 fresh paired seeds in the N5
6-DOF, IID-15% occupancy cell. The exact repaired packet format, fixed-graph
certificate, continuous replay, affine-clock guard, MTU, recipient/airtime
accounting, safety and terminal liveness gates passed. There were no safety,
divergence or scheduled-collision failures.

The 6.8 s target relative to the 1 s coherence arm produced:

- management airtime: -90.45%, paired delta CI
  `[-0.571083, -0.554429]` s;
- RMSE: -0.0030%, paired delta CI `[-4.99e-6, 0]` m.

Relative to the EXP23D lower-cost periodic boundary, target total offered
utilization was -3.95%, with paired delta CI
`[-0.0115210, -0.0111170]`. Mean RMSE was 0.05550 m for target versus
0.05438 m for periodic (periodic is about 2.03% better in tracking), while
mean cost was 0.27540 versus 0.28672. Hence neither arm epsilon-dominates the
other under the frozen 1%/1% rule.

The run's only amendment corrected the post-processing summary column name
after all 300 trajectories had been checkpointed; no trajectory, contrast,
bootstrap setting, gate or threshold was changed or rerun.

This is fresh evidence for the fixed-topology mechanism. It is not evidence
for online graph migration or broad dynamic robustness.
