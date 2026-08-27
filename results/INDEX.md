# Experiment index

Two tables. The first is the **curated map** — one row per experiment, with
the tag that froze it, the commit that produced its final run, its result
directory and its status. The second is the **auto-generated run log** that
`finishExperiment` appends to, one row per run including debug and superseded
runs.

Status vocabulary:

| Status | Meaning |
|---|---|
| POSITIVE | every pre-registered gate passed |
| PARTIAL | some gates passed, at least one failed; the failure is characterised, not tuned away |
| NEGATIVE | the pre-registered claim was rejected |
| DIAGNOSTIC | run to attribute a failure, not to support a claim |
| SECONDARY | characterisation at a condition outside the primary matrix |

A PARTIAL or NEGATIVE row is a result, not an unfinished task. None of them
is re-tested away later in the campaign; `docs/FINAL_CLAIMS.md` and the
`LOCKED LIMITATIONS` section of the EXP10B report carry them forward.

## Curated map

| Experiment | Tag | Commit | Result directory | Status | Note |
|---|---|---|---|---|---|
| exp01_hover | — | 1d30c4f | `results/exp01_hover/2026-08-20_080731` | POSITIVE | single-vehicle hover baseline |
| exp01b_position_step | — | 1d30c4f | `results/exp01b_position_step/2026-08-20_080800` | POSITIVE | step response |
| exp01c_disturbance | — | 1d30c4f | `results/exp01c_disturbance/2026-08-20_080829` | POSITIVE | disturbance rejection |
| exp01d_trajectory | — | 1d30c4f | `results/exp01d_trajectory/2026-08-20_080858` | POSITIVE | trajectory tracking |
| exp02_formation | — | 2b37367 | `results/exp02_formation/2026-08-20_074252` | POSITIVE | distributed formation, no impairment |
| exp03a_packet_loss | — | 1d30c4f | `results/exp03a_packet_loss/2026-08-20_074536` | POSITIVE | loss sweep |
| exp03b_delay | — | 1d30c4f | `results/exp03b_delay/2026-08-20_080929` | POSITIVE | delay sweep |
| exp03c_loss_delay | — | 1d30c4f | `results/exp03c_loss_delay/2026-08-20_081131` | POSITIVE | loss x delay, analytical AoI validation |
| exp03d_jitter | — | 1d30c4f | `results/exp03d_jitter/2026-08-20_081538` | POSITIVE | jitter and out-of-order delivery |
| exp04a_comm_rate | — | 1d30c4f | `results/exp04a_comm_rate/2026-08-20_081001` | POSITIVE | rate versus accuracy frontier |
| exp04b_rate_impairment | — | 1d30c4f | `results/exp04b_rate_impairment/2026-08-20_113608` | POSITIVE | minimum robust periodic rate |
| exp05a_event_triggered | — | 1d30c4f | `results/exp05a_event_triggered/2026-08-20_081043` | POSITIVE | state-event baseline |
| exp05b_aoi_aware | — | 1d30c4f | `results/exp05b_aoi_aware/2026-08-20_075304` | POSITIVE | AoI-aware policy, IDEAL (acausal) feedback |
| exp05c_ablation | — | 1d30c4f | `results/exp05c_ablation/2026-08-20_113200` | POSITIVE | A1-A4 ablation chain; values locked in test_lock_regression |
| exp05d_pareto_frontier | — | acdb9cb | `results/exp05d_pareto_frontier/2026-08-20_114031` | POSITIVE | Pareto definition and 1 % dominance margin |
| exp06a_scalability | — | acdb9cb | `results/exp06a_scalability/2026-08-20_115133` | POSITIVE | N = 5..50, near-linear scaling; **own graph convention**, see note below |
| exp07a_causal_ack | `exp07a-locked` | 2cbc5b2 | `results/exp07a_causal_ack/2026-08-21_202017` | POSITIVE | Causal-AoI-v3, 9/9 gates under a real ACK channel |
| exp07b_ack_impairment | `exp07b-locked` | b5490f4 | `results/exp07b_ack_impairment/2026-08-21_210001` | PARTIAL | 5/5 gates, but the mechanism is **saturation, not robustness** |
| exp07c_cost_model | `exp07c-locked-negative` | 14701ff | `results/exp07c_cost_model/2026-08-21_214817` | NEGATIVE | Stressed ACK-inclusive Pareto superiority **rejected** |
| exp08a_topology | `exp08a-locked-partial` | 6b8c534 | `results/exp08a_topology/2026-08-21_221900` | PARTIAL | 4/5; safety generalisation across topology fails at one condition |
| exp08ad_normalization | `exp08ad-locked-diagnostic` | eaa030d | `results/exp08ad_normalization/2026-08-21_230739` | DIAGNOSTIC | attributes the EXP08A failure to the unnormalised consensus gain |
| exp08b_link_failure | `exp08b-locked-partial` | b9b325b | `results/exp08b_link_failure/2026-08-22_071018` | PARTIAL | 2/3; absolute safety fails, and fails for **every method alike** |
| exp08c_node_blackout | `exp08c-locked-partial` | e8c4017 | `results/exp08c_node_blackout/2026-08-26_173420` | PARTIAL | 1/3; safety fails at a 5 s outage, for every method alike |
| exp09a_multiuav_6dof | `exp09a-locked` | e0f9e0b | `results/exp09a_multiuav_6dof/2026-08-26_210235` | POSITIVE | 7/7 under 6-DOF quadrotor followers |
| exp09a_n10_secondary | `exp09a-locked` | 92ba113 | `results/exp09a_n10_secondary/2026-08-26_211138` | SECONDARY | N = 10 characterisation, outside the primary matrix |
| exp09b_physical_mismatch | `exp09b-locked-partial` | 452af01 | `results/exp09b_physical_mismatch/2026-08-27_022038` | PARTIAL | 4/5; G2 absolute-RMSE fails on a **controller** limit, not a communication one |
| exp09c_synthetic_estimator | `exp09c-locked-partial` | e91c084 | `results/exp09c_synthetic_estimator/2026-08-27_025437` | PARTIAL | 3/4; Clean C3 DATA-rate gate fails on noise-driven hard triggers |
| exp09c_timestep_diagnostic | `exp09c-locked-partial` | e91c084 | `results/exp09c_timestep_diagnostic/2026-08-27_030722` | DIAGNOSTIC | RMSE stable across outer dt, but **DATA-rate dt-invariance rejected** |
| exp10a_final_validation | `simulation-v1.0` | f23c8c2 | `results/exp10a_final_validation/2026-08-27_091546` | POSITIVE | 50 holdout seeds, 3400 runs, 5/5 infrastructure gates; K1 SUPPORTED, K2 reported without direction |
| exp10b_unified_matrix | `simulation-v1.0` | f23c8c2 | `results/exp10b_unified_matrix/2026-08-27_095330` | PARTIAL | Moderate criterion MET at w = 0.25 (87.5 %); Causal-v3 dominated in 75 % of Moderate cells under **broadcast** accounting, and Stressed non-dominance falls to 37.5 % at w = 0.50, airtime and broadcast |
| simulation_v1_validation | `simulation-v1.0` | 9c96c4f | `results/simulation_v1_validation/2026-08-27_094912` | POSITIVE | EXP10C: 7/7 — test suite, tag and config hashes, hash re-verification in a fresh process, serial-versus-parallel bit-identity, environment manifest |

Superseded or debug runs that the curated map deliberately does **not** point at:

| Run | Why it is not the run that counts |
|---|---|
| `results/exp10a_final_validation/2026-08-27_075759` | 3-seed infrastructure smoke, run before the holdout sweep. Its console log says so, and every row of its `tidy.csv` carries only 3 seeds. |
| `results/exp10a_final_validation/2026-08-27_081056` | A complete, valid 50-seed sweep. Superseded only because its `PHASEHASH`, `FAULTHASH` and `BLACKHASH` columns predate the exact-checksum fix. Every other recorded value — RMSE, minSep, SafeFail, DIVERGED, DATA, ACK, broadcast, AoI, forward and reverse hashes, invariants, MAXDEV — is **identical row by row** to the final run. Two independent 3400-run executions agreeing exactly is the campaign's strongest reproducibility datapoint, and it is kept for that reason. |
| `results/exp10b_unified_matrix/2026-08-27_0806*, _0841*, _0843*, _0844*, _0848*, _0854*` | Earlier aggregations. The numbers are the same as their source dataset; the reports are less complete — they predate the empty-denominator section, the no-fault safety table, or the warning-free table construction. |
| `results/simulation_v1_validation/2026-08-27_084500`, `_084932`, `_090539` | Abandoned attempts, each superseded for a stated reason. `_084500` and `_084932` hit the shared-workspace defect in `run_all_tests` (a test's `t0` collided with the runner's `tic`, so the suite aborted after its seventh file without printing a failure). `_090539` was interrupted deliberately, mid-suite, once the checksum defect had been diagnosed and a fix was going in. None is a regression: the recorded run passes 7/7. |

## Auto-generated run log

Appended by `finishExperiment`, one row per run. Includes debug and
superseded runs; the curated map above names the run that counts.

| Run ID | Experiment | Elapsed | Figures | Workspace | Tidy CSV | MATLAB | Commit |
|---|---|---|---|---|---|---|---|
| 2026-08-20_074252 | exp02_formation | 7.6 s | 3 | yes | - | (R2025a) | 2b37367 |
| 2026-08-20_074536 | exp03a_packet_loss | 21.9 s | 3 | yes | yes | (R2025a) | 1d30c4f |
| 2026-08-20_075304 | exp05b_aoi_aware | 1 m 40 s | 6 | yes | yes | (R2025a) | 1d30c4f |
| 2026-08-20_080731 | exp01_hover | 9.4 s | 2 | yes | - | (R2025a) | 1d30c4f |
| 2026-08-20_080800 | exp01b_position_step | 9.7 s | 2 | yes | - | (R2025a) | 1d30c4f |
| 2026-08-20_080829 | exp01c_disturbance | 10.0 s | 2 | yes | - | (R2025a) | 1d30c4f |
| 2026-08-20_080858 | exp01d_trajectory | 12.4 s | 3 | yes | - | (R2025a) | 1d30c4f |
| 2026-08-20_080929 | exp03b_delay | 12.8 s | 3 | yes | - | (R2025a) | 1d30c4f |
| 2026-08-20_081001 | exp04a_comm_rate | 18.0 s | 7 | yes | - | (R2025a) | 1d30c4f |
| 2026-08-20_081043 | exp05a_event_triggered | 19.8 s | 6 | yes | - | (R2025a) | 1d30c4f |
| 2026-08-20_081131 | exp03c_loss_delay | 3 m 44 s | 7 | yes | yes | (R2025a) | 1d30c4f |
| 2026-08-20_081538 | exp03d_jitter | 1 m 26 s | 8 | yes | yes | (R2025a) | 1d30c4f |
| 2026-08-20_113200 | exp05c_ablation | 3 m 49 s | 3 | yes | yes | (R2025a) | 1d30c4f |
| 2026-08-20_113608 | exp04b_rate_impairment | 3 m 58 s | 6 | yes | yes | (R2025a) | 1d30c4f |
| 2026-08-20_114031 | exp05d_pareto_frontier | 3 m 12 s | 5 | yes | yes | (R2025a) | acdb9cb |
| 2026-08-20_115133 | exp06a_scalability | 5 m 21 s | 8 | yes | yes | (R2025a) | acdb9cb |
| 2026-08-21_202017 | exp07a_causal_ack | 2 m 13 s | 3 | yes | yes | (R2025a) | 2cbc5b2 |
| 2026-08-21_210001 | exp07b_ack_impairment | 3 m 33 s | 3 | yes | yes | (R2025a) | b5490f4 |
| 2026-08-21_214817 | exp07c_cost_model | 1 m 48 s | 2 | yes | yes | (R2025a) | 14701ff |
| 2026-08-21_221900 | exp08a_topology | 38 m 02 s | 3 | yes | yes | (R2025a) | 6b8c534 |
| 2026-08-21_230739 | exp08ad_normalization | 27 m 54 s | 1 | yes | yes | (R2025a) | eaa030d |
| 2026-08-21_235608 | exp08b_link_failure | 7 m 11 s | 0 | yes | yes | (R2025a) | 700c836 |
| 2026-08-22_055745 | exp08b_link_failure | 6 m 06 s | 0 | yes | yes | (R2025a) | 49c28ea |
| 2026-08-22_060821 | exp08b_link_failure | 5 m 36 s | 0 | yes | yes | (R2025a) | 49c28ea |
| 2026-08-22_061608 | exp08b_link_failure | 6 m 24 s | 0 | yes | yes | (R2025a) | 49c28ea |
| 2026-08-22_062334 | exp08b_link_failure | 6 m 02 s | 0 | yes | yes | (R2025a) | 49c28ea |
| 2026-08-22_071018 | exp08b_link_failure | 17 m 17 s | 0 | yes | yes | (R2025a) | b9b325b |
| 2026-08-26_171952 | exp08c_node_blackout | 12 m 35 s | 0 | yes | yes | (R2025a) | 6689cde |
| 2026-08-26_173420 | exp08c_node_blackout | 26 m 40 s | 0 | yes | yes | (R2025a) | e8c4017 |
| 2026-08-26_210040 | exp09a_multiuav_6dof | 1 m 13 s | 0 | yes | yes | (R2025a) | e0f9e0b |
| 2026-08-26_210235 | exp09a_multiuav_6dof | 2 m 45 s | 0 | yes | yes | (R2025a) | e0f9e0b |
| 2026-08-26_210615 | exp09a_n10_secondary | 4 m 53 s | 0 | yes | yes | (R2025a) | 92ba113 |
| 2026-08-26_211138 | exp09a_n10_secondary | 4 m 37 s | 0 | yes | yes | (R2025a) | 92ba113 |
| 2026-08-27_021119 | exp09b_physical_mismatch | 7 m 43 s | 0 | yes | yes | (R2025a) | 452af01 |
| 2026-08-27_022038 | exp09b_physical_mismatch | 19 m 29 s | 0 | yes | yes | (R2025a) | 452af01 |
| 2026-08-27_024310 | exp09c_synthetic_estimator | 5 m 43 s | 0 | yes | yes | (R2025a) | d266db2 |
| 2026-08-27_025437 | exp09c_synthetic_estimator | 12 m 01 s | 0 | yes | yes | (R2025a) | e91c084 |
| 2026-08-27_030722 | exp09c_timestep_diagnostic | 3 m 22 s | 0 | yes | yes | (R2025a) | e91c084 |
| 2026-08-27_075759 | exp10a_final_validation | 6 m 42 s | 3 | yes | yes | (R2025a) | cdc1185 |
| 2026-08-27_080641 | exp10b_unified_matrix | 14.5 s | 4 | yes | yes | (R2025a) | cdc1185 |
| 2026-08-27_081056 | exp10a_final_validation | 30 m 30 s | 3 | yes | yes | (R2025a) | 9372170 |
| 2026-08-27_084154 | exp10b_unified_matrix | 13.0 s | 4 | yes | yes | (R2025a) | 9372170 |
| 2026-08-27_084305 | exp10b_unified_matrix | 14.2 s | 4 | yes | yes | (R2025a) | 9372170 |
| 2026-08-27_084400 | exp10b_unified_matrix | 17.1 s | 4 | yes | yes | (R2025a) | 9372170 |
| 2026-08-27_084853 | exp10b_unified_matrix | 17.2 s | 4 | yes | yes | (R2025a) | 3307fcc |
| 2026-08-27_085455 | exp10b_unified_matrix | 17.4 s | 4 | yes | yes | (R2025a) | 3307fcc |
| 2026-08-27_085455 | exp10b_unified_matrix | 1 m 04 s | 4 | yes | yes | (R2025a) | 3307fcc |
| 2026-08-27_091546 | exp10a_final_validation | 31 m 20 s | 3 | yes | yes | (R2025a) | 3307fcc |
| 2026-08-27_094814 | exp10b_unified_matrix | 11.3 s | 4 | yes | yes | (R2025a) | 3307fcc |
| 2026-08-27_095330 | exp10b_unified_matrix | 16.0 s | 4 | yes | yes | (R2025a) | f23c8c2 |
| 2026-08-27_094912 | simulation_v1_validation | 5 m 41 s | 0 | yes | - | (R2025a) | f23c8c2 |
