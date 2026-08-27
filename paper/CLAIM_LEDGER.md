# Publication claim ledger — simulation-v1.0

Publication-ready form of `docs/FINAL_CLAIMS.md`. One row per claim, with
the status, the supporting experiment, the metric that carries it, the
scope it holds within, and the limitation attached to it.

**How to use this table.** A claim in **LIMITED / CONDITIONAL** may not be
stated in a paper, abstract or talk without its Limitation column. A claim
in **REJECTED** may not appear as supported anywhere.
`paper/scripts/paper_audit.m` checks both mechanically.

Every number is reproduced from `paper/generated/headline_metrics.csv`,
which is generated from the frozen result directories named in
`paper/generated/PROVENANCE.md`.

Rate conventions differ between eras and are labelled per row:
**per-ch** = per directed channel (P10 reads 10.00 Hz);
**total** = swarm total over all directed channels (P10 reads 99.67 Hz at
N = 5 under the EXP08+ graph convention). They are not comparable.

---

## SUPPORTED

| # | Claim | Experiment / tag | Metric or statistic | Scope | Limitation attached |
|---|---|---|---|---|---|
| S1 | Causal implementation without oracle receiver state: the sender learns receiver freshness only from ACKs crossing a delayed, lossy reverse channel | EXP07A `exp07a-locked`; EXP10A | 9 protocol invariants, **0 violations in 3400 runs**; `g_ack` advanced in exactly one place | all conditions tested | none |
| S2 | Adaptive DATA rate, Clean < Moderate < Stressed, with one fixed configuration | EXP10A/B | **84.47 < 134.84 < 182.94 Hz** (total) | N=5, 6-DOF, ring2, dt = 0.02 s | rate is dt-dependent (R7); ACK-inclusive total also rises |
| S3 | Lower mean RMSE than State-event throughout the final EXP10 matrix | EXP10B | **17 / 17 cells** | the 17 cells of the final matrix | part of the margin is State-event failing safety outright at N=20/50 (see L7) |
| S4 | Holdout Stressed RMSE improvement vs P10 (pre-registered K1) | EXP10A | paired **−0.0288 m**, CI **[−0.0294, −0.0283]**, n = 50 | nominal Stressed cell | holds in 15/17 cells matrix-wide, not 17/17 (L4) |
| S5 | Causal/recovery correctness under tested ACK and fault conditions | EXP07A/B, EXP08B/C, EXP10A | invariants 0; recovery via max-silence backstop, **no retransmission timer** | ACK loss ≤ 20 %, permanent link removal ≤ 30 %, blackout ≤ 5 s | recovery ≠ safety: safety still fails under fault (R3, R4) |
| S6 | Communication ranking survives the 6-DOF transition | EXP09A `exp09a-locked`; EXP10A | all methods degrade, ordering preserved; **0 divergences in 3400 runs** | N=5 (6-DOF), N=10 secondary | leader is kinematic; no 6-DOF result at large N |
| S7 | Non-dominated in Moderate under the reference cost model | EXP10B | **87.5 %** (7/8) of evaluable point families at w = 0.25 | Moderate, w = 0.25 / 0.10 / 0.50 / airtime | **25 %** under broadcast accounting (L2) |
| S8 | Scales to N = 50 without divergence | EXP10B `SCALE`; EXP06A | RMSE 0.2347 vs 0.2216 (P20), 0.2882 (P10); 0/50 unsafe | N = 50, double integrator, ring2 | absolute traffic not comparable to EXP06A (L8) |

## LIMITED / CONDITIONAL

| # | Claim | Experiment / tag | Metric or statistic | Scope | Limitation that must be quoted with it |
|---|---|---|---|---|---|
| L1 | Moderate Pareto competitiveness | EXP10B | 87.5 % non-dominated at w = 0.25 | Moderate only | **Not** a saving claim: Causal is cheapest in **0 / 17** cells at w = 0.25 |
| L2 | Accuracy–cost trade-off depends on the cost model | EXP07C `exp07c-locked-negative`; EXP10B | Moderate 87.5 / 87.5 / 87.5 / 87.5 / **25.0 %** for w = .10/.25/.50/airtime/**broadcast** | five cost models | the broadcast column is the operative one on a shared medium |
| L3 | DATA-packet reduction against P20 (K2a) | EXP10A | paired **−16.73 Hz**, CI [−16.77, −16.68] | nominal Stressed | reverses under ACK-inclusive cost: K2b **+10.67 Hz**, CI [+10.59, +10.76] |
| L4 | Accuracy advantage over P10 matrix-wide | EXP10B | **15 / 17** cells | final matrix | two exceptions: NOMINAL/Clean (0.0414 vs 0.0361) and LINK/Moderate (1.0656 vs 1.0655, a tie) |
| L5 | Topology generalization with a safety boundary | EXP08A `exp08a-locked-partial`; EXP08A-D `exp08ad-locked-diagnostic` | ranking holds over 4 topologies × N ∈ {10,20,50}; safety gate fails at one condition | Moderate, Stressed | absolute safety does **not** generalize; cause is unnormalised consensus gain (controller) |
| L6 | Link/node-fault recovery | EXP08B/C; EXP10B | traffic responds during the fault window; recovery measured | perm ≤ 30 %, blackout ≤ 5 s | recovery is not safety: unsafe 9/49 (link), 9/50 (node), **identical across methods** |
| L7 | State-event comparison | EXP10B | Causal lower RMSE in 17/17 | final matrix | State-event is unsafe **50/50 with no fault** at N20REF/Stressed and SCALE/Stressed |
| L8 | Scalability anchor at N = 50 | EXP10B; EXP06A | see S8 | N = 50, DI | graph convention differs from EXP06A → absolute traffic not comparable |
| L9 | ACK-impairment tolerance | EXP07B `exp07b-locked` | Stressed RMSE 0.1173 reliable vs 0.1173 at 20 % ACK loss | Stressed | **saturation, not robustness**: adaptive scale pinned at floor s_min = 0.20 |
| L10 | Physical-mismatch behaviour | EXP09B `exp09b-locked-partial`; EXP10B | Moderate 0.0892 → 0.7317 m (+720 %) | arm B7 | absolute robustness **rejected**; cause is missing integral action (controller) |
| L11 | Sensor/estimator-noise behaviour | EXP09C `exp09c-locked-partial`; EXP10B | Moderate DATA ×1.69, Stressed ×1.36 | arm C3 | Clean bandwidth bound **rejected** (×2.34); ESTIMATOR/Moderate is the one dominated Moderate cell |
| L12 | Timestep sensitivity | EXP09C-dt | RMSE stable; DATA 202.89 / 182.91 / 133.03 Hz at dt = 0.01/0.02/0.04 s | Stressed | every rate in the paper is a rate **at dt = 0.02 s** |

## REJECTED

| # | Claim as pre-registered | Experiment / tag | Statistic that rejected it | Attribution |
|---|---|---|---|---|
| R1 | Stressed ACK-inclusive Pareto superiority | EXP07C `exp07c-locked-negative`; EXP10B | Stressed non-dominated **37.5 %** at w = 0.50, airtime and broadcast; K2b **+10.67 Hz** CI excludes zero | ACK traffic is real traffic |
| R2 | Universal topology safety | EXP08A `exp08a-locked-partial` | safety gate fails systematically at one sweep condition | unnormalised consensus gain scales with in-degree (**controller**) |
| R3 | Absolute link-fault safety | EXP08B `exp08b-locked-partial`; EXP10B | unsafe **9/49** connected seeds, identical for P10, P20 and Causal | formation geometry + controller, **not** the communication policy |
| R4 | 5-s blackout safety robustness | EXP08C `exp08c-locked-partial`; EXP10B | unsafe **9/50** eligible seeds under matched no-fault eligibility | a dark node is unreachable by any policy |
| R5 | ≤ 25 % RMSE degradation under B7 physical mismatch | EXP09B `exp09b-locked-partial`; EXP10B | **+720 %** at Moderate, +521 % at Stressed | no integral action → steady offset (**controller**) |
| R6 | Clean estimator-noise traffic < 2× | EXP09C `exp09c-locked-partial` | ratio **×2.34** against the noiseless arm | measurement noise crosses the hard-innovation threshold |
| R7 | DATA-rate invariance to outer dt | EXP09C-dt | 202.89 / 182.91 / 133.03 Hz at dt = 0.01/0.02/0.04 s | trigger is evaluated once per outer step by construction |

---

## Claims explicitly NOT made

These are not rejected claims — they were never asserted, and the audit
checks that they do not appear:

- universal superiority over optimally tuned periodic communication
  (P20 has lower RMSE in **16 / 17** cells);
- any reduction in **total** radio traffic once acknowledgements are priced;
- "fully decentralized without feedback" — the policy is a **causal
  ACK-assisted decentralized communication policy** and depends on the
  reverse channel;
- any hardware, airtime or energy measurement;
- any aerodynamic wind model (the external forcing is a nominal-mass
  equivalent acceleration proxy);
- any measured sensor model (the estimator sigmas are assumptions).
