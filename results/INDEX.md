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
| exp12_shared_medium_diagnostic | — | 17cd865 | `results/exp12_shared_medium_diagnostic/2026-08-29_104600` | DIAGNOSTIC | 108 development runs; 14/14 shared-medium infrastructure gates |
| exp13_development | — | 17cd865 | `results/exp13_development/2026-08-29_111747` | DIAGNOSTIC | 531-run development/frontier selection; design 0 frozen without holdout access |
| exp13b_multislot_mac_diagnostic | — | 17cd865 | `results/exp13b_multislot_mac_diagnostic/2026-08-29_131048` | DIAGNOSTIC | 96 runs; proves one-slot MAC degeneracy and restores CSMA–ALOHA distinction with multi-slot DATA |
| exp14a_holdout_primary | — | dirty frozen snapshot | `results/exp14a_holdout_primary/2026-08-29_155023` | POSITIVE | 10,500 rows and 11/11 integrity gates; no performance gate—default is dominated in all regimes, while the family retains Pareto points |
| exp14b_holdout_ood | — | 17cd865 + frozen snapshot | `results/exp14b_holdout_ood/2026-08-29_230917` | SECONDARY | 4,800 rows and 9/9 integrity gates; N20 fixed-policy collapse and CSMA/ALOHA feedback-mode reversal retained |
| exp14c_mac_aware_development | — | 17cd865 + frozen snapshot | `results/exp14c_mac_aware_development/2026-08-30_080346` | DIAGNOSTIC | 288 development rows and 12/12 gates; access scaling repairs N20, but the full guarded policy retains failures |
| exp14d_factorial_closure | — | 17cd865 + frozen snapshot | `results/exp14d_factorial_closure/2026-08-30_183739` | DEVELOPMENT | 384 rows and 15/15 final gates; selects adaptive/no-guard/scaled arm and attributes residual failures to the fixed load guard |
| exp14e_preregistered_holdout | — | 17cd865 + frozen snapshot | `results/exp14e_preregistered_holdout/2026-08-30_213957` | POSITIVE | 2,800 rows, 14/14 gates, 6/6 Holm tests and 3/3 CSMA cells supported; post-hoc exact accounting shows piggyback stronger at N5/N10 and ACK-assisted stronger in the ALOHA boundary |
| exp14f_paired_shadow | — | 17cd865 + frozen snapshot | `results/exp14f_paired_shadow/2026-08-30_230947` | DIAGNOSTIC | 160 runs, 9,694 ACK events and 12/12 gates; positive policy-history lead is common but is not a focal-decision effect or value certificate |
| exp14g_branch_at_decision | — | dirty frozen snapshot | `results/exp14g_branch_at_decision/2026-08-30_235146` | PARTIAL | 13/14 gates; exact focal replay supports N5/N10/ALOHA descriptions, rejects lead-as-benefit, and fails frozen N20 event support |
| exp14h_n20_support_closure | — | 17cd865 + frozen snapshot | `results/exp14h_n20_support_closure/2026-08-31_001447` | DIAGNOSTIC | 240 N20 pilots; only 7 eligible parent seeds versus minimum 12, so preflight correctly stops before causal outcomes |
| exp14i_mac_selective_validation | — | 17cd865 + frozen snapshot | `results/exp14i_mac_selective_validation/2026-08-31_004619` | POSITIVE | 1,600 rows, 15/15 gates, exact alias identity, 6/6 Holm tests and 3/3 cells support the frozen CSMA→piggyback / ALOHA→adaptive selector |
| exp16_factorial_interaction | — | 17cd865 + frozen snapshot | `results/exp16_factorial_interaction/2026-08-31_104551` | DEVELOPMENT | 3,600 factorial trajectories; interaction diagnostics retained for mechanism attribution |
| exp17_operating_envelope | — | 17cd865 + frozen snapshot | `results/exp17_operating_envelope/2026-08-31_110505` | NEGATIVE | independent envelope gate returns `DO_NOT_PROCEED_WITH_GENERAL_SELECTOR`; no hardware promotion |
| exp18b_preregistered_holdout | — | 17cd865 + frozen snapshot | `results/exp18b_preregistered_holdout/2026-08-31_152137` | PARTIAL | 7,200 holdout trajectories; exact-alias and mechanism audit retained, but context routing is not a general novelty claim |
| exp19a_oracle_service_diagnostic | — | 17cd865 + frozen snapshot | `results/exp19a_oracle_service_diagnostic/2026-08-31_175039` | NEGATIVE | 1,620 trajectories, 18/18 gates; semantic-priority promotion rejected and scheduled access retained |
| exp20a_prior_art_baseline_closure | — | frozen source + amendment | `results/exp20a_prior_art_baseline_closure/2026-08-31_232833` | SUPERSEDED IN PART | formation panel valid: 2,520 rows and 13/13 gates; its original native panel is invalid and audit-only |
| exp20a_native_protocol_correction | — | corrected frozen source | `results/exp20a_native_protocol_correction/2026-09-01_005821` | DEVELOPMENT STOP | canonical EXP20A artifact: corrected 1,800-row native panel, 7/7 correction gates, unchanged formation panel; `PRIOR_ART_EXPLAINS_FRONTIER`, EXP20B prohibited |
| exp21a_distributed_scheduling_reality_check | — | frozen source + reporting amendment | `results/exp21a_distributed_scheduling_reality_check/2026-09-01_030941` | DEVELOPMENT FRAGILE | 1,680 trajectories and 15/15 integrity gates; nominal distributed reservation dominates current in 2/2 cells, but only 1/5 single-fault cells retains performance, convergence is 0.833 and churn recovery 0.333; `SCHEDULING_GAIN_FRAGILE`, no confirmation or hardware promotion |
| exp21b_continuous_timing_validity | — | frozen source | `results/exp21b_continuous_timing_validity/2026-09-01_040346` | MODEL VALIDITY | 1,600 timing rows and 11/11 gates; all 800 rows at/above the analytical guard bound are collision-free and the clock equation closes to 1.78e-15 s; `TIMING_MODEL_VALID_FOR_INTEGRATION` |
| exp21c_closed_loop_timing_integration | — | frozen source | `results/exp21c_closed_loop_timing_integration/2026-09-01_044850` | INTEGRATION VALIDITY | 240 closed-loop trajectories and 15/15 gates; continuous safe-guard scheduling has zero collisions/failures in both cells while unguarded clock has 99,752 collision frames and 60/60 failures; `CLOSED_LOOP_TIMING_INTEGRATION_VALID` |
| exp21d_dstr_kernel_conformance | — | frozen source | `results/exp21d_dstr_kernel_conformance/2026-09-01_070545` | PRIOR-ART KERNEL VALID | 800 rows and 17/17 gates; native assumptions and lossy/visibility boundaries retained |
| exp21d_closed_loop_integration | — | frozen source | `results/exp21d_closed_loop_integration/2026-09-01_080135` | PRIOR-ART INTEGRATION VALID | 180 trajectories and 17/17 gates; exact D-STR physical replay and substantial management cost |
| exp21d_boundary_continuation | — | frozen source + amendments | `results/exp21d_boundary_continuation/2026-09-01_104515` | BOUNDARY VALID | 360 trajectories and 16/16 gates; erasure and restricted-visibility failures retained |
| exp21d_clock_composition | — | frozen source | `results/exp21d_clock_composition/2026-09-01_114737` | CLOCK COMPOSITION VALID | 180 trajectories and 17/17 gates; full-mission affine clock boundary closed |
| exp22_elcs_kernel_falsification | — | frozen source | `results/exp22_elcs_kernel_falsification/2026-09-01_122201` | INVALID RETAINED | 13/15 gates; random refresh collision and missing cascade exposed |
| exp22b_elcs_kernel_repair | — | frozen source | `results/exp22b_elcs_kernel_repair/2026-09-01_165537` | INVALID RETAINED | 15/16 gates; reconfiguration stimulus failed to activate N10 |
| exp22c_elcs_kernel_activation | — | frozen source | `results/exp22c_elcs_kernel_activation/2026-09-01_170847` | KERNEL VALID | 1,400 rows and 16/16 gates; edge-lease safety, recovery and forced recolor validated |
| exp22d_elcs_closed_loop_integration | — | frozen source | `results/exp22d_elcs_closed_loop_integration/2026-09-01_173320` | INVALID RETAINED | 120 rows, 14/17 gates; duplicate fallback saturation mismatch exposed |
| exp22e_elcs_fallback_repair | — | frozen source | `results/exp22e_elcs_fallback_repair/2026-09-01_174154` | KERNEL VALID | 1,400 rows and 17/17 gates; one fallback attempt per node/frame, all prior safety gates preserved |
| exp22e_elcs_closed_loop_repair_validation | — | frozen source | `results/exp22e_elcs_closed_loop_repair_validation/2026-09-01_175319` | INTEGRATION VALID | 120 rows and 17/17 gates; zero skips and exact physical outcome/accounting replay |
| exp22f_direct_feasibility | — | frozen source | `results/exp22f_direct_feasibility/2026-09-01_180435` | FEASIBILITY PARTIAL | 600 rows and 14/14 integrity gates; coarse grid non-dominance but interpolation gap retained |
| exp22g_targeted_frontier_closure | — | frozen source | `results/exp22g_targeted_frontier_closure/2026-09-01_182938` | NEGATIVE / RETURN TO DESIGN | 180 rows and 10/10 integrity gates; cost-targeted periodic confidence-supported epsilon-dominates ELCS-F in both cells |
| exp22h_elcs_event_driven_renewal | — | frozen source | `results/exp22h_elcs_event_driven_renewal/2026-09-01_191307` | INVALID RETAINED | 1,400 rows and 19/20 gates; reconfiguration STATUS accounting/order defect isolated |
| exp23w_fast_reactivation_holdout | — | frozen registry/source snapshot | `results/exp23w_fast_reactivation_holdout/2026-09-04_225232` | FIXED-GRAPH MECHANISM CONFIRMED | 800 fresh-seed trajectories, 21/21 integrity gates, 6/6 Holm tests and 4/4 frontier guards; online union-graph migration remains unvalidated |
| exp23x_local_union_migration_kernel | — | frozen source + causal amendment | `results/exp23x_local_union_migration_kernel/2026-09-04_232823` | MIGRATION KERNEL VALID | repaired causal run: 3,000 rows and 21/21 gates over N={5,10,20}; fixed-window LOCK-PROOF, union oracle and fault boundaries valid |
| exp23y_migration_common_phy | — | frozen source + accounting amendment | `results/exp23y_migration_common_phy/2026-09-04_233744` | MIGRATION COMMON-PHY VALID | 1,800 rows and 18/18 gates over N={5,10,20}; exact control/DATA mapping, affine-clock safety, fault boundaries and visible incomplete-union collisions; closed-loop claim remains prohibited |
| exp23z_local_migration_closed_loop | — | frozen source snapshot | `results/exp23z_local_migration_closed_loop/2026-09-05_072640` | NEGATIVE | 120 rows and 15/16 gates; graph-input executor, timing and accounting valid, but permanent RESPONSE blackout causes 20/20 separation failures; collision-safe emergency DATA service required |
| exp23aa_emergency_data_development | — | frozen source snapshot | `results/exp23aa_emergency_data_development/2026-09-05_073757` | DEVELOPMENT FEASIBLE | 120 rows and 19/19 gates; protected slot-10 DATA restores safety in 20/20 permanent-RESPONSE-blackout rows while retaining lease silence and zero collisions; persistent control retry remains to be bounded |
| exp23ab_bounded_retry_development | — | frozen source snapshot | `results/exp23ab_bounded_retry_development/2026-09-05_075106` | DEVELOPMENT FEASIBLE | 120 rows and 24/24 gates; finite 6-dense/2-4-8-backoff/10-attempt CLAIM policy cuts blackout control attempts by 150.8 and total cost by 4.96% with exact closed-loop equivalence and a 5.85e-4 analytical failure bound |
| exp23ac_receiver_lift_diagnostic | — | development diagnostic snapshot | `results/exp23ac_receiver_lift_diagnostic/2026-09-05_080210` | NEGATIVE / RETURN TO DESIGN | 89 online tube graph-change rows; 86 are nonlocal despite only UAV 10 changing state, and the 3 local removals do not change its slot; one-sender plant coupling is rejected by the receiver lift |
| exp23ad_receiver_lifted_closure_kernel | — | frozen source snapshot | `results/exp23ad_receiver_lifted_closure_kernel/2026-09-05_081510` | CLOSURE KERNEL VALID | 2,400 rows and 24/24 gates over N={5,10,20}; dependency closure, quiescence-gated motion, joint union coloring, IID-20 liveness and all registered blackout/oracle boundaries pass; common-PHY integration remains required |

Superseded or debug runs that the curated map deliberately does **not** point at:

| Run | Why it is not the run that counts |
|---|---|
| `results/exp10a_final_validation/2026-08-27_075759` | 3-seed infrastructure smoke, run before the holdout sweep. Its console log says so, and every row of its `tidy.csv` carries only 3 seeds. |
| `results/exp10a_final_validation/2026-08-27_081056` | A complete, valid 50-seed sweep. Superseded only because its `PHASEHASH`, `FAULTHASH` and `BLACKHASH` columns predate the exact-checksum fix. Every other recorded value — RMSE, minSep, SafeFail, DIVERGED, DATA, ACK, broadcast, AoI, forward and reverse hashes, invariants, MAXDEV — is **identical row by row** to the final run. Two independent 3400-run executions agreeing exactly is the campaign's strongest reproducibility datapoint, and it is kept for that reason. |
| `results/exp10b_unified_matrix/2026-08-27_0806*, _0841*, _0843*, _0844*, _0848*, _0854*` | Earlier aggregations. The numbers are the same as their source dataset; the reports are less complete — they predate the empty-denominator section, the no-fault safety table, or the warning-free table construction. |
| `results/simulation_v1_validation/2026-08-27_084500`, `_084932`, `_090539` | Abandoned attempts, each superseded for a stated reason. `_084500` and `_084932` hit the shared-workspace defect in `run_all_tests` (a test's `t0` collided with the runner's `tic`, so the suite aborted after its seventh file without printing a failure). `_090539` was interrupted deliberately, mid-suite, once the checksum defect had been diagnosed and a fix was going in. None is a regression: the recorded run passes 7/7. |
| `results/exp20a_prior_art_baseline_closure/2026-08-31_232833/native_tidy.csv` | Invalid native implementation omitted a DELTA collision-exit transition and did not reproduce upstream boundary semantics. It is retained for audit only and is explicitly superseded by `results/exp20a_native_protocol_correction/2026-09-01_005821/native_tidy.csv`. The parent formation panel remains valid and is copied unchanged into the canonical correction artifact. |
| `results/exp23x_local_union_migration_kernel/2026-09-04_232607` | All 3,000 numerical rows completed, but a manual causal audit found that neighbor LOCK-PROOF transmissions stopped on the revoker's private receipt state. It is superseded by the fixed-window causal run `_232823` and cannot support integration. |
| `results/exp23y_migration_common_phy/2026-09-04_233623` | All 1,800 rows completed, but the runner compared colliding DATA-attempt rows with unique collision frames in the incomplete-union negative control. It is superseded by `_233744`, which records and regression-tests both quantities; the invalid run cannot support integration. |
| `results/exp23z_local_migration_closed_loop/2026-09-05_072551` | The runner stopped before registry serialization and trajectory 1 because two local artifact-writing helpers were missing. No scientific result was produced; the unchanged protocol was executed in `_072640`. |
| `results/exp23aa_emergency_data_development/2026-09-05_073456` | All 120 trajectories completed, but postprocessing stopped because the registry still declared 18 gates after a nineteenth gate had been added. No validation-gate or verdict artifact was written; the unchanged six-arm matrix was rerun as `_073757`, which passes 19/19. |

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
| 2026-08-27_174026 | exp11_dynamic_network | 8 m 15 s | 3 | yes | yes | (R2025a) | 85ead26 |
| 2026-08-27_175335 | exp11_dynamic_network | 13.9 s | 3 | yes | yes | (R2025a) | 85ead26 |
| 2026-08-29_091707 | exp12_shared_medium_diagnostic | 55.4 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-29_092028 | exp12_shared_medium_diagnostic | 55.1 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-29_104600 | exp12_shared_medium_diagnostic | 3 m 18 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-29_111747 | exp13_development | 7 m 40 s | 4 | yes | - | (R2025a) | 17cd865 |
| 2026-08-29_131048 | exp13b_multislot_mac_diagnostic | 1 m 04 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-29_155023 | exp14a_holdout_primary | 32 m 22 s | 0 | yes | yes | (R2025a) | - |
| 2026-08-29_230917 | exp14b_holdout_ood | 43 m 44 s | 0 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-30_080346 | exp14c_mac_aware_development | 8.0 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-30_183739 | exp14d_factorial_closure | 3 m 02 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-30_213957 | exp14e_preregistered_holdout | 23 m 41 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-30_230947 | exp14f_paired_shadow | 2 m 13 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-08-30_235146 | exp14g_branch_at_decision | 2 m 45 s | 0 | yes | - | (R2025a) | - |
| 2026-08-31_001447 | exp14h_n20_support_closure | 7 m 23 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-08-31_004619 | exp14i_mac_selective_validation | 15 m 49 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_104551 | exp16_factorial_interaction | 3 m 25 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_110505 | exp17_operating_envelope | 23 m 04 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_121134 | exp18a_context_aware_development | 15 m 05 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_123541 | exp18a2_service_certificate_development | 3 m 27 s | 1 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_124628 | exp18a3_freshness_headroom_development | 3 m 11 s | 0 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_125544 | exp18a4_capacity_gated_selector_development | 3 m 20 s | 0 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_152137 | exp18b_preregistered_holdout | 1 h 40 m | 0 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_175039 | exp19a_oracle_service_diagnostic | 7 m 12 s | 0 | yes | yes | (R2025a) | 17cd865 |
| 2026-08-31_232833 | exp20a_prior_art_baseline_closure | 12 m 39 s | 0 | yes | - | (R2025a) | - |
| 2026-09-01_005821 | exp20a_native_protocol_correction | 1 h 07 m | 0 | yes | - | (R2025a) | - |
| 2026-09-01_030941 | exp21a_distributed_scheduling_reality_check | 15 m 03 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_040346 | exp21b_continuous_timing_validity | 1 m 11 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_044850 | exp21c_closed_loop_timing_integration | 2 m 35 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_055220 | exp21d_dstr_kernel_conformance | 4 m 06 s | 0 | yes | yes | (R2025a) | 17cd865 |
| 2026-09-01_060611 | exp21d_dstr_kernel_conformance | 4 m 13 s | 0 | yes | yes | (R2025a) | 17cd865 |
| 2026-09-01_070545 | exp21d_dstr_kernel_conformance | 12 m 13 s | 0 | yes | yes | (R2025a) | 17cd865 |
| 2026-09-01_074819 | exp21d_closed_loop_integration | 9 m 24 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_080135 | exp21d_closed_loop_integration | 7 m 46 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_104515 | exp21d_boundary_continuation | 2.1 s | 0 | yes | - | (R2025a) | - |
| 2026-09-01_114737 | exp21d_clock_composition | 9 m 12 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_122201 | exp22_elcs_kernel_falsification | 9 m 05 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_165537 | exp22b_elcs_kernel_repair | 10 m 43 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_170847 | exp22c_elcs_kernel_activation | 8 m 60 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_173320 | exp22d_elcs_closed_loop_integration | 3 m 07 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_174154 | exp22e_elcs_fallback_repair | 9 m 46 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_175319 | exp22e_elcs_closed_loop_repair_validation | 3 m 22 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_180435 | exp22f_direct_feasibility | 20 m 54 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_182938 | exp22g_targeted_frontier_closure | 5 m 36 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_191307 | exp22h_elcs_event_driven_renewal | 9 m 51 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_192508 | exp22i_elcs_event_driven_order_repair | 9 m 37 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_193812 | exp22j_elcs_event_driven_closed_loop | 3 m 07 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_194517 | exp22k_event_driven_frontier_closure | 5 m 44 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_195423 | exp22l_event_driven_frontier_gate_repair | 5 m 26 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_200249 | exp22m_sharp_frontier_closure | 5 m 23 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-01_203031 | exp23a_local_witness_kernel_falsification | 1 m 47 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-03_142535 | exp23b_local_witness_retry_validation | 2 m 27 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-03_161908 | exp23c_local_witness_closed_loop_integration | 2 m 29 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-03_163244 | exp23d_local_witness_sharp_frontier | 4 m 56 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-03_164740 | exp23e_local_witness_iid_robustness | 16 m 44 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-03_171702 | exp23f_local_witness_background_robustness | 23 m 53 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_154603 | exp23g_background_gate_repair | 17 m 15 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_161234 | exp23h_cumulative_receipt_kernel_validation | 9 m 11 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_162852 | exp23i_cumulative_closed_loop_target | 2.3 s | 0 | yes | - | 2025a | - |
| 2026-09-04_164602 | exp23k_horizon_scaled_development | 0.8 s | 0 | yes | - | 2025a | - |
| 2026-09-04_165837 | exp23l_coherence_geometry_kernel | 3.1 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_170157 | exp23m_coherence_geometry_stimulus_repair | 3.3 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_172147 | exp23o_broadcast_coherence_kernel | 16.7 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_172817 | exp23p_coherence_packet_kernel | 3 m 48 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_173841 | exp23q_broadcast_graph_repair | 18.1 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_174126 | exp23r_coherence_packet_graph_repair | 3 m 59 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_180028 | exp23s_dynamic_revocation_kernel | 14.7 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_180732 | exp23t_static_coherence_closed_loop | 2.5 s | 0 | yes | - | 2025a | - |
| 2026-09-04_203719 | exp23u_dynamic_closed_loop_envelope | 2.5 s | 0 | yes | - | 2025a | - |
| 2026-09-04_222905 | exp23v_fast_reactivation_development | 9 m 49 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_225232 | exp23w_fast_reactivation_holdout | 20 m 39 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_232607 | exp23x_local_union_migration_kernel | 14.0 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_232823 | exp23x_local_union_migration_kernel | 15.2 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_233623 | exp23y_migration_common_phy | 19.6 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-04_233744 | exp23y_migration_common_phy | 20.1 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_072640 | exp23z_local_migration_closed_loop | 2 m 41 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_073757 | exp23aa_emergency_data_development | 2 m 24 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_075106 | exp23ab_bounded_retry_development | 2 m 27 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_080210 | exp23ac_receiver_lift_diagnostic | 16.7 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_081510 | exp23ad_receiver_lifted_closure_kernel | 24.5 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_092152 | exp23ae_receiver_lifted_closure_common_phy | 52.2 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_115428 | exp23af_swept_online_diagnostic | 21.6 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_115633 | exp23af_command_candidate_diagnostic | 7.4 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_115734 | exp23af_command_candidate_diagnostic | 7.3 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_115925 | exp23af_command_candidate_diagnostic | 7.6 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_115958 | exp23af_command_candidate_diagnostic | 7.5 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_133218 | exp23af_command_candidate_diagnostic | 1.6 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_133248 | exp23af_command_candidate_diagnostic | 3.7 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_135215 | exp23af_online_swept_receiver_closure | 2 m 09 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_142004 | exp23af_radial_contract_diagnostic | 1 m 44 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_142942 | exp23ag_fresh_radial_receiver_closure | 4 m 38 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-05_235807 | exp23ah_phase_reserved_diagnostic | 3 m 58 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_000317 | exp23ah_phase_reserved_diagnostic | 4 m 04 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_001301 | exp23ah_phase_reserved_radial_closure | 4 m 51 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_003132 | exp23ai_integer_phy_accounting | 4 m 52 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_070738 | exp23aj_routed_management_diagnostic | 20.5 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_071620 | exp23al_routed_accounting_confirmation | 18.3 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_071938 | exp23am_semantic_local_sentinel | 8.4 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_072949 | exp23an_full_detectability_routing | 29.2 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_075633 | exp23ao_multi_origin_routing | 37.8 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_081712 | exp23ap_routed_state_machine_common_phy | 52.2 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_081945 | exp23aq_routed_state_machine_confirmation | 51.8 s | 0 | yes | - | (R2025a) | 17cd865 |
| 2026-09-06_140652 | tcns_gate0_baseline_audit | 21.9 s | 0 | yes | - | (R2025a) | 4dc76b0 |
| 2026-09-06_141912 | exp10a_final_validation | 31 m 22 s | 3 | yes | yes | (R2025a) | ddfd669 |
| 2026-09-06_145037 | exp10b_unified_matrix | 8.6 s | 4 | yes | yes | (R2025a) | ddfd669 |
| 2026-09-06_140912 | simulation_v1_validation | 42 m 20 s | 0 | yes | - | (R2025a) | ddfd669 |
| 2026-09-06_192155 | exp11_dynamic_network | 5 m 44 s | 3 | yes | yes | (R2025a) | 8e40d46 |
| 2026-09-06_193337 | tcns_gate0_baseline_audit | 17.5 s | 0 | yes | - | (R2025a) | 82b966e |
| 2026-09-06_194134 | tcns_gate1_model_audit | 0.7 s | 0 | yes | - | (R2025a) | 31ff907 |
| 2026-09-06_194936 | tcns_gate2_staleness_bound_diagnostic | 12.7 s | 1 | yes | yes | (R2025a) | 0632c21 |
| 2026-09-06_195059 | tcns_gate2_staleness_bound_diagnostic | 12.2 s | 1 | yes | yes | (R2025a) | 0632c21 |
| 2026-09-06_195402 | tcns_gate2_staleness_bound_diagnostic | 11.9 s | 1 | yes | yes | (R2025a) | 1d05c78 |
| 2026-09-06_195924 | tcns_gate2_staleness_bound_diagnostic | 12.2 s | 1 | yes | yes | (R2025a) | 36bfb69 |
| 2026-09-06_201053 | tcns_gate3_formation_robustness_diagnostic | 15.6 s | 1 | yes | yes | (R2025a) | ef4be37 |
| 2026-09-07_002803 | tcns_gate3_formation_robustness_diagnostic | 20.2 s | 1 | yes | yes | (R2025a) | ef4be37 |
| 2026-09-07_003415 | tcns_gate3_formation_robustness_diagnostic | 20.4 s | 1 | yes | yes | (R2025a) | f019d99 |
| 2026-09-07_003518 | tcns_gate3_formation_robustness_diagnostic | 20.7 s | 1 | yes | yes | (R2025a) | 6b92074 |
| 2026-09-07_005609 | tcns_gate4_small_sanity | 13.0 s | 1 | yes | yes | (R2025a) | 53eac10 |
| 2026-09-07_005719 | tcns_gate4_small_sanity | 12.2 s | 1 | yes | yes | (R2025a) | 4384589 |
| 2026-09-07_010403 | tcns_gate5_stationary_frontiers | 1 m 28 s | 1 | yes | yes | (R2025a) | 88b6705 |
| 2026-09-07_012209 | tcns_gate6_nonstationary_frontiers | 2 m 53 s | 2 | yes | yes | (R2025a) | 9d5d8c0 |
| 2026-09-07_093357 | tcns_post_gate6_oracle_value_diagnostic | 10.0 s | 1 | - | yes | (R2025a) | f5fc880 |
| 2026-09-07_110535 | tcns_predictive_voi_small_sanity | 1 m 52 s | 1 | - | yes | (R2025a) | 7c876ec |
| 2026-09-07_113834 | tcns_cross_term_oracle_diagnostic | 12.9 s | 1 | - | - | (R2025a) | 403b9e6 |
| 2026-09-07_121250 | tcns_true_branch_value_diagnostic | 54.7 s | 1 | - | - | (R2025a) | 84849c3 |
| 2026-09-07_160426 | tcns_o1_oracle_frontier_stage_a | 2 m 10 s | 3 | yes | yes | (R2025a) | 16537d1 |
| 2026-09-07_162102 | tcns_o1_oracle_frontier_stage_b | 4 m 37 s | 3 | yes | yes | (R2025a) | 58e9aa9 |
| 2026-09-07_170123 | tcns_ab0_ack_cost_adjusted_o1 | 19.4 s | 1 | yes | - | (R2025a) | 55c0dcb |
| 2026-09-07_170557 | tcns_ab0_ack_cost_adjusted_o1 | 19.4 s | 1 | yes | - | (R2025a) | 1fd9d39 |
| 2026-09-07_170715 | tcns_ab0_ack_cost_adjusted_o1 | 20.2 s | 1 | yes | - | (R2025a) | 6e99816 |
| 2026-09-07_175224 | tcns_fb0_feedback_economics | 10.7 s | 1 | yes | - | (R2025a) | 91a95bb |
| 2026-09-07_215747 | tcns_af2_passive_ack_free_calibration | 4 m 22 s | 1 | yes | yes | (R2025a) | f688525 |
| 2026-09-07_230816 | tcns_information_limits_validation | 8.2 s | 1 | yes | - | (R2025a) | 834e212 |
| 2026-09-07_231055 | tcns_information_limits_validation | 15.0 s | 1 | yes | - | (R2025a) | 605c1b6 |
| 2026-09-07_231250 | tcns_information_limits_validation | 14.4 s | 1 | yes | - | (R2025a) | dd7bef4 |
| 2026-09-07_231500 | tcns_information_limits_validation | 10.1 s | 1 | yes | - | (R2025a) | 370409a |
| 2026-09-07_231721 | tcns_information_limits_validation | 12.3 s | 1 | yes | - | (R2025a) | b3064c7 |
| 2026-09-08_060901 | tcns_information_limits_validation | 11.7 s | 1 | yes | - | (R2025a) | f0ec934 |
| 2026-09-08_095209 | tcns_information_limits_validation | 14.3 s | 1 | yes | - | (R2025a) | 15177a8 |
| 2026-09-08_101541 | tcns_r1_theory_depth_validation | 8.1 s | 1 | yes | - | (R2025a) | 2250d64 |
| 2026-09-08_103325 | tcns_r1_theory_depth_validation | 7.3 s | 1 | yes | - | (R2025a) | 05fa200 |
| 2026-09-08_155705 | tcns_r2_generalization_validation | 4 m 02 s | 0 | yes | - | (R2025a) | 253b99b |
| 2026-09-08_161130 | tcns_r2_generalization_validation | 5 m 42 s | 0 | yes | - | (R2025a) | a2cec3b |
| 2026-09-08_174125 | tcns_r2_5_adversarial_validation | 6 m 27 s | 0 | yes | - | (R2025a) | c1538ae |
| 2026-09-08_175427 | tcns_r2_5_adversarial_validation | 6 m 26 s | 0 | yes | - | (R2025a) | edad129 |
| 2026-09-08_232116 | tcns_r2_6_decision_identifiability | 4.5 s | 0 | yes | - | (R2025a) | 2fd1359 |
