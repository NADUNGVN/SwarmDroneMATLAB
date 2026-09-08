# TCNS reviewer-risk audit before R2 modification

**Audit date:** 2026-09-08  
**Audited branch:** `paper-v3-tcns`  
**Audited HEAD:** `9d9212e134c9e2cae3bbdb0f79d918d3560e5359`  
**Status:** completed before any R2 code or manuscript modification.

This document separates the general analytical statements from the numerical
evidence currently available. In particular, it does not reinterpret the
ten-link structural unit-response audit as ten physical scheduler-action
witnesses.

## 1. Claim-to-code and artifact map

| Current paper item or numerical claim | Direct code path | Frozen machine-readable source | Scope |
|---|---|---|---|
| Generic fixed-response quadratic benefit is affine | algebra in `paper/tcns/manuscript/tcns_information_limits.tex`, Sec. IV | theorem/proof, no numerical artifact | theorem/general for finite-dimensional affine systems with fixed action response and quadratic output cost |
| Current and finite-history row-space identifiability | manuscript Theorems 1--2; numerical implementation in `utils/tcnsLinearIdentifiability.m` and `utils/tcnsInformationLimitsSenderMap.m` | `results/tcns_information_limits_validation/2026-09-08_095209/link_identifiability.csv` | theorem is general; table application is N=5, graph-, H-, D-, and information-map-specific |
| Minimax value radius and binary decision regret | manuscript Theorem 3; witness values converted by `experiments/tcns_r1_theory_depth_validation.m/localRegretRow` | `results/tcns_r1_theory_depth_validation/2026-09-08_103325/witness_regret.csv` | theorem/general on a closed compatible value interval; numbers are two N=5 reachable histories at H=25, D=4 |
| Minimum simultaneous-action linear-statistic dimension | manuscript Theorem 4; `utils/tcnsR1TheoryDepthAudit.m/localSenderAudit` | `sender_multi_action.csv`, `sender_action_missing_norms.csv` in the R1 result directory | theorem/general for instantaneous noiseless real linear statistics; values are current-map N=5/unit-response-specific |
| Minimum owning coalition | manuscript Corollary 2; exhaustive enumeration in `tcnsR1TheoryDepthAudit.m/localMultiActionCoalition` | R1 `sender_multi_action.csv` | N=5 graph, global output, H=25, current sender maps, and unit responses |
| Exact Gate-3 affine formation map and O1 identity | `tcnsInformationLimitsModel` -> `tcnsInformationLimitsState` -> `tcnsInformationLimitsActionMap`; independent comparator `tcnsCentralizedStateOracleValue`; driver `tcns_information_limits_validation.m` | IL `finite_horizon_F.csv`, `finite_horizon_r.csv`, `affine_validation.csv` | N=5, fixed graph/gains, H=25, D=4, unsaturated sampled double integrator |
| Ten structural unit-response coefficients are sender-history nonidentifiable | `tcns_information_limits_validation.m` constructs `[1 0 0]` command corrections and zero substituted payloads; `tcnsR1TheoryDepthAudit/localActionCatalog` repeats the same construction | IL `link_identifiability.csv`; R1 `rank_robustness.csv`, `rank_tolerance_sweep.csv`, `singular_spectra.csv` | all ten catalog actions, but structural unit responses only; not ten actual state-derived controller corrections |
| Rank conclusion is tolerance/VPA robust | `tcnsR1TheoryDepthAudit/localRankAudit` and `localVpaProjectionResidual` | R1 rank/tolerance/spectrum tables | N=5, H=25, D=4; 80-digit arithmetic starts from double implementation matrices |
| Two dynamically reachable opposite-sign histories | `tcnsInformationLimitsDynamicWitness` called only for ordinary 1->5 and pinned-leader 1->4 by both IL and R1 drivers | IL `dynamic_witness.csv`, R1 `witness_regret.csv`, both `workspace.mat` files | N=5, sender 1 only, actual nonzero belief-derived controller response, H=25, D=4, positive-probability erasure history |
| Fig. 1 information architecture | `paper/tcns/manuscript/make_gm_figures.m`, model from `tcnsGate6Scenario(27020001,'S1')` | generated schematic | N=5 implementation schematic |
| Fig. 2 bound-trigger falsification | `make_gm_figures.m` reads Gate-5 frontiers | `results/tcns_gate5_stationary_frontiers/2026-09-07_010403/{frontier_periodic,frontier_control_aware}.csv` | five development seeds, frozen stationary stressed scenario |
| Fig. 3 centralized headroom/boundary | `make_gm_figures.m` reads O1 Stage A/B | `results/tcns_o1_oracle_frontier_stage_a/2026-09-07_160426/frontiers.csv` and `...stage_b/2026-09-07_162102/frontiers.csv` | five development seeds; privileged O1; S2 positive and S4 negative boundary |
| Fig. 4 and Table V ACK-like economics | `make_gm_figures.m`; `experiments/tcns_fb0_feedback_economics.m` | `results/tcns_fb0_feedback_economics/2026-09-07_175224/{feedback_economics_points,scenario_summary}.csv` | offline packet-frequency sensitivity; not a causal acquisition protocol |
| Fig. 5 information geometry | hand-coded geometry in `make_gm_figures.m` | no empirical data | explanatory schematic |
| Fig. 6 reachable histories | `make_gm_figures.m` loads the newest IL `workspace.mat` | IL ordinary 1->5 and pin 1->4 witness structs | exactly two actual-response reachable witnesses |
| Tables II--IV | values transcribed from IL/R1 artifacts above | IL/R1 CSV files | N=5 and stated map/response scopes |

The frozen simulation-v1 evidence used by Figs. 2--4 is not part of the new R2
study and must not be modified.

## 2. Dependency classification of current claims

| Claim class | What is independent | What remains conditioned |
|---|---|---|
| Theorem/general | affine fixed-response value representation; row-space iff application; compatible-interval minimax radius/regret; rank of the hidden multi-action projection | fixed action response, affine dynamics/information, quadratic output, declared compatible set, instantaneous linear-statistic scope |
| Graph-instance-specific | ten residuals; sender-wise compression; coalition ownership | exact adjacency, pinning, global output, controller gains, current/history sender maps |
| N=5-specific | 99-state dimension; 8 ordinary + 2 pin catalog; all-five coalition; sender counts and ratios | every table entry in current Tables II--IV |
| Seed-specific | Gate-5/O1/FB0 development plots use the declared paired seed sets | IL/R1 structural matrices are deterministic after configuration; seed 27020001 selects the S1 configuration/channel law but no Monte Carlo claim is made |
| H-specific | action response, value coefficient, missing direction, regret scale, and multi-action rank are evaluated at H=25 | generic theorems do not require H=25 |
| D/history-specific | action response uses D=4; reduced complete-history lengths are 92 (ordinary) and 89 (pin); ranks and witnesses use those maps | no current evidence establishes invariance over D or shorter histories |

## 3. Current ten-action evidence inventory

The action convention is sender -> receiver. `Actual response` below means an
actual nonzero state/controller-derived correction was constructed and replayed;
`structural unit` means only `[1 0 0]` with a zero substituted payload was used.

| Action class | Sender | Receiver | Current all-link nonidentifiability input | Current reachable witness? |
|---|---:|---:|---|---|
| ordinary | 1 | 2 | structural unit | no |
| ordinary | 1 | 5 | structural unit; separate actual-response witness | yes |
| ordinary | 2 | 3 | structural unit | no |
| ordinary | 3 | 2 | structural unit | no |
| ordinary | 3 | 4 | structural unit | no |
| ordinary | 4 | 3 | structural unit | no |
| ordinary | 4 | 5 | structural unit | no |
| ordinary | 5 | 4 | structural unit | no |
| pinned-leader | 1 | 2 | structural unit | no |
| pinned-leader | 1 | 4 | structural unit; separate actual-response witness | yes |

Current coverage is therefore:

- structural unit-response nonidentifiability: 10/10;
- dynamically reachable actual-response opposite-sign witnesses: 2/10;
- follower-sender dynamically reachable witnesses: 0/6.

## 4. Hard-coded assumptions in the existing theory experiments

| Quantity | Existing value/source |
|---|---|
| N | 5 |
| graph | `applyTopologyConfig(defaultConfig(),5,'ring2')`; follower controller rows give ordinary actions 1->2, 1->5, 2->3, 3->2, 3->4, 4->3, 4->5, 5->4 |
| pinning | `[0 1 0 1 0]^T`, so pin payloads are 1->2 and 1->4 |
| formation geometry | 0.6 m cross: leader at origin, followers east/north/west/south |
| controller | Kp=1.8, Kv=2.2, KpLeader=1.5, KvLeader=1.8; consensus degree normalization disabled |
| plant | 50 Hz (`h=0.02` s) semi-implicit double integrator; fixed symmetric grounded Schur unsaturated theorem scope; max command 2 m/s^2 |
| performance horizon | H=25 samples = 0.5 s |
| action delay | D=4 samples = 0.08 s |
| configuration seed | 27020001 under Gate-6 S1/Moderate; packet-loss probability 0.2 and configured delay 0.08 s |
| default identifiability tolerance | `1e-10*max(1,sigmaMax(C))`; membership compares residual with this absolute cutoff times coefficient norm |
| R1 tolerance grid | relative factors `1e-6, 1e-8, 1e-10, 1e-12, 1e-14` |
| high precision | 80-digit row-basis projection on implementation-generated double matrices |
| history length | `numel(action.keepIndex)-1`: 92 ordinary, 89 pinned; this is a complete finite-dimensional held-memory horizon, not the network delay |
| sender map | own position/velocity; leader acceleration for sender 1; every incoming ordinary/pin memory feeding the local controller; current unsaturated command; graph/gains/offsets/time/channel law and sent-packet history as fixed affine data; no remote receiver truth |
| structural audit payload/action | substituted payload zero; command correction `[1 0 0]` |
| dynamic witness construction | sender must be 1; one leader DATA attempt at t=h with positive-probability erasure; constant-velocity leader chosen to induce a 0.01 m/s^2 x-axis correction at decision time; initial follower perturbation restricted by `initialConsistencyMap3` |

## 5. Manuscript/evidence mismatches and reviewer hazards

1. **Displayed adjacency versus actual configuration.** Equation (4) displays
   the symmetric full ring with nonzero row 1. `applyTopologyConfig` explicitly
   zeros `cfg.swarm.A(1,:)` because the analytical leader reads no neighbors.
   Follower dynamics and the ten-action catalog are unchanged by row 1, but the
   displayed matrix is not the literal stored configuration and should be
   corrected after R2 results are reviewed.
2. **“Current action” can be misread.** Table IV and surrounding prose refer to
   controller-relevant current actions, but its coefficients use structural
   unit corrections, not state-derived corrections from a trajectory. The
   nearby qualification is present but should become part of the evidence
   hierarchy rather than a caveat readers must discover.
3. **Ten versus two evidence levels.** The conclusion correctly says ten
   structural functionals and two reachable histories, but the abstract's
   proximity of those sentences can still invite an all-ten actual-witness
   reading. R2 must preserve the distinction even if more witnesses succeed.
4. **The existing dynamic routine is leader-only by construction.** Its
   `sender~=1` error prevents the manuscript from supporting follower-sender
   decision ambiguity. This is an evidence gap, not a theorem gap.
5. **Two witness values are small.** They certify strict sign divergence but
   currently lack a normalization against typical actual action-value scale.
6. **Internal-development names remain in reader-facing text.** `GM`, `O1`,
   `Gate-5`, `AB0`, and `FB0` appear in the appendices/captions/prose. They are
   reproducibility labels, not scientific concepts, and should be reduced only
   after the new evidence is frozen.
7. **Artifact overview is stale, not false history.** `ARTIFACT_README.md`
   accurately documents frozen simulation-v1 and paper-v1/paper-v2, but its
   headline package description does not route readers to paper-v3-tcns or a
   separate R2 evidence layer.
8. **No acquisition protocol exists.** The one-scalar/rank result is algebraic;
   FB0 prices an ACK-like stream only. Current wording mostly states this
   correctly. R2 must not turn that sensitivity calculation into measured
   deployable acquisition cost.

## Audit decision

The requested R2 study is valid within the existing sampled linear theorem
architecture. The model builder already accepts arbitrary admissible N,
adjacency, pinning, H, and D. The new work should be additive: preserve IL/R1
and their artifacts, introduce a deterministic graph/pinning registry, and
report both heterogeneous rank outcomes and explicit witness-search failures.
