# Generated-metric provenance

Written by `paper/scripts/make_paper_metrics.m`. No simulation is run; every value is read from a persisted
`tidy.csv` of the frozen `simulation-v1.0` campaign.

| Purpose | Result directory |
|---|---|
| EXP10 holdout dataset (paired claims, safety, divergence) | `results/exp10a_final_validation/2026-08-27_091546` |
| EXP10 unified matrix (per-cell means, dominance) | `results/exp10b_unified_matrix/2026-08-27_095330` |
| EXP07A causal design chain and oracle comparator | `results/exp07a_causal_ack/2026-08-21_202017` |
| EXP07B ACK impairment and adaptive-scale saturation | `results/exp07b_ack_impairment/2026-08-21_210001` |
| EXP07C cost models | `results/exp07c_cost_model/2026-08-21_214817` |
| EXP08A topology generalization | `results/exp08a_topology/2026-08-21_221900` |
| EXP08B permanent and burst link failure | `results/exp08b_link_failure/2026-08-22_071018` |
| EXP08C node communication blackout | `results/exp08c_node_blackout/2026-08-26_173420` |
| EXP09A double-integrator versus 6-DOF | `results/exp09a_multiuav_6dof/2026-08-26_210235` |
| EXP09B plant mismatch | `results/exp09b_physical_mismatch/2026-08-27_022038` |
| EXP09C synthetic estimator | `results/exp09c_synthetic_estimator/2026-08-27_025437` |
| EXP09C timestep diagnostic | `results/exp09c_timestep_diagnostic/2026-08-27_030722` |

## Statistical conventions

| Context | Reported as |
|---|---|
| EXP10 key claims (K1, K2a, K2b) | paired mean difference, 95 % CI, n = 50 |
| Development experiments (EXP05-EXP09) | mean +- standard deviation, n = 20 |
| Binary safety | unsafe / eligible, and the percentage |

The paired intervals are recomputed from per-seed rows with
`utils/pairedCI.m`, not copied from a console log.
