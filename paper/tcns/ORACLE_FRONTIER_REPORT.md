# Centralized online-oracle frontier report

**Verdict:** `O1_STRONG_HEADROOM` on Stage A; final O1 support in 3 of 5
nonstationary scenarios; `GO_ACK_BELIEF_POLICY` under the frozen decision
matrix.

**Boundary:** `centralized_state_oracle` is privileged and not implementable.
This report establishes scheduler headroom on development scenarios. It is
not held-out evidence and does not establish general predictive validity.

## 1. Freeze and provenance audit

Before O1 was designed, commits `0c634b9`, `84849c3`, and `0487e2a` were
pushed without rewriting history. The exact verified local/remote HEAD was

`0487e2a5f3e255f59eb0c824be430991eb8d7474`.

The worktree was clean and `tests/test_lock_regression.m` passed after that
push. The O1 Stage-A protocol, implementation and decision rule were then
committed and pushed at
`16537d1c214b06eb08d820ec20c3853b22a4439a` before any O1 result was viewed.
Stage B was separately preregistered and pushed at
`58e9aa9c9327d0443a9be464ff48b890bf4e8081` before S3/S4/S5 were run.

The two recorded MATLAB R2025a campaigns are:

- Stage A: run `2026-09-07_160426`, source git `16537d1`, 250 runs, 2 min
  10 s;
- Stage B: run `2026-09-07_162102`, source git `58e9aa9`, 375 runs, 4 min
  37 s.

Both returned technical `PASS`. In both, periodic formation metrics reproduce
the archived Gate-6 artifact within (5\times10^{-16}), cost within
(3.6\times10^{-14}), and DATA count and trace hash exactly. Thus the
comparator is the same frontier that rejected Gate 4, not a refitted subset.

## 2. Exact O1 diagnostic

At current decision sample (k), O1 reads actual plant state, actual
receiver-held payloads and therefore the exact communication-induced command
residual (d_c(k)). It freezes the **current** formation, leader acceleration
and residual in the exact Gate-3 sampled recurrence

\[
y^0_{r+1}=A_hy^0_r+B_c[d_c(k)+(\pi-\mathbf 1)a_L(k)].
\]

Let (Z(k)) be the resulting (H=25)-sample follower-position error response
and (G_{ij}(k)) the exact Gate-3 response of a successful current update on
link (j\to i). The sole ranking quantity is

\[
q_{ij}(k)=\frac{p_s}{N-1}
\left(\lVert Z(k)\rVert_F^2-
\lVert Z(k)+G_{ij}(k)\rVert_F^2\right),
\]

or equivalently

\[
q_{ij}(k)=-\frac{2p_s}{N-1}\langle Z,G_{ij}\rangle_F
-\frac{p_s}{N-1}\lVert G_{ij}\rVert_F^2.
\]

This is the validated cross-term formulation, not an AoI/error weighted
heuristic. The scheduler transmits exactly when (q_{ij}(k)>\lambda), with
one fixed delay-derived observation interval and no retry bonus. The 14
frozen (lambda) values span 0 through 1. The policy consumes the current
packet outcome only after selection.

O1 never reads future channel outcomes, jitter draws, disturbances, formation
changes, leader trajectory or plant trajectory. In S3 it also does not read
the Gilbert-Elliott latent state; in S5 it does not read the seeded link-down
mask when ranking. O1 has centralized current receiver truth and therefore
sends no ACK. Nevertheless, the x-axis remains the frozen

\[
C_{0.25}=\mathrm{DATA}+0.25\,\mathrm{ACK}\quad[\mathrm{Hz/channel}].
\]

The full information privileges and the current-regime interpretation for S4
are recorded in `ORACLE_FRONTIER_PROTOCOL.md` and
`ORACLE_STAGE_B_PROTOCOL.md`.

## 3. Stage-A decisive result

Stage A used only preregistered development scenarios S2/S6 and five paired
seeds. Each entry below is O1 minus periodic over all 101 points of the
complete shared domain; negative favors O1. “Run” is the longest contiguous
sequence meeting the preregistered magnitude threshold (2% RMSE or 5% cost).

### Budget matched

| Scenario | Mean \(\Delta E\) m | Median m | Domain favoring O1 | Max advantage m | Max disadvantage m | Crossings | Meaningful run |
|---|---:|---:|---:|---:|---:|---:|---:|
| S2 Formation switching | -0.02381 | -0.01937 | 100.0% | 0.05880 | 0 | 0 | 101/101 |
| S6 Dynamic excitation | -0.01460 | -0.01087 | 100.0% | 0.05462 | 0 | 0 | 98/101 |

### Performance matched

| Scenario | Mean \(\Delta C\) Hz/channel | Median | Domain favoring O1 | Max advantage | Max disadvantage | Crossings | Meaningful run |
|---|---:|---:|---:|---:|---:|---:|---:|
| S2 Formation switching | -1.7088 | -0.5030 | 100.0% | 41.1356 | 0 | 0 | 101/101 |
| S6 Dynamic excitation | -0.5696 | -0.4015 | 100.0% | 1.9128 | 0 | 0 | 101/101 |

Both scenarios meet every frozen convincing criterion, so the Stage-A
classification is `O1_STRONG_HEADROOM`. The relevant shared budget domains
are 1.248--10.905 Hz/channel for S2 and 1.248--12.227 Hz/channel for S6. No
claim is made outside those observed overlaps.

## 4. Stage-B breadth result

The exact policy family and decision rule were then expanded to S3/S4/S5.

### Budget matched

| Scenario | Mean \(\Delta E\) m | Median m | Favoring | Max advantage m | Max disadvantage m | Crossings | Meaningful run |
|---|---:|---:|---:|---:|---:|---:|---:|
| S3 Burst loss | +0.00166 | -0.00800 | 79.2% | 0.01198 | 0.06140 | 1 | 63/101 |
| S4 Congestion | +0.02595 | +0.02669 | 0.0% | 0 | 0.06995 | 0 | 0/101 |
| S5 Topology perturbation | -0.00431 | -0.00859 | 82.2% | 0.02348 | 0.10034 | 2 | 62/101 |

### Performance matched

| Scenario | Mean \(\Delta C\) Hz/channel | Median | Favoring | Max advantage | Max disadvantage | Crossings | Meaningful run |
|---|---:|---:|---:|---:|---:|---:|---:|
| S3 Burst loss | -0.0014 | +0.2112 | 31.7% | 2.1686 | 0.4429 | 1 | 13/101 |
| S4 Congestion | +0.7135 | +0.3442 | 0.0% | 0 | 11.9275 | 0 | 0/101 |
| S5 Topology perturbation | -0.2468 | -0.0768 | 52.5% | 1.4980 | 0.3160 | 2 | 46/101 |

The frozen classifications are:

- S3: `MARGINAL_OR_NARROW`;
- S4: `NO_HEADROOM`;
- S5: `CONVINCING`.

Together with S2 and S6, convincing support is 3 of 5 scenarios, above the
project threshold of 2. This is evidence of non-universal but material
scheduler headroom: it is strong for formation switching and dynamic
excitation, persists under the topology perturbation, becomes narrow under
burst loss, and is absent under the tested time-varying congestion model.

## 5. Traffic-allocation diagnostics

The table uses the protocol-preselected explanatory point
(lambda=10^{-3}), averaged over five seeds. Counts are per complete 30 s
run. ACK count is zero in every O1 run. (R_{event}>1) indicates traffic
concentration relative to event duration; it was never optimized.

| Scenario | Evaluation \(C_{0.25}\) | \(R_{event}\) | Useful deliveries | Failed DATA | No-information attempts | Mean value event / quiet |
|---|---:|---:|---:|---:|---:|---:|
| S2 | 7.423 | 0.868 | 1896.4 | 469.8 | 476.0 | 0.001447 / 0.001269 |
| S3 | 9.681 | 1.000 | 1539.6 | 1363.0 | 1366.2 | 0.002871 / n/a |
| S4 | 9.008 | 1.010 | 2059.0 | 502.2 | 661.6 | 0.001628 / 0.001252 |
| S5 | 9.128 | 1.137 | 2082.8 | 658.6 | 664.0 | 0.020474 / 0.002275 |
| S6 | 7.671 | 1.101 | 1950.0 | 471.6 | 477.0 | 0.001568 / 0.001243 |

S3's event window is the entire evaluation interval, so its concentration is
identically one and there is no quiet comparator. At (lambda=10^{-3}), S5
shows the clearest temporal value separation (about 9x event/quiet value) and
also passes the frontier rule. S6 combines modest event concentration with a
convincing frontier. S2 demonstrates that Pareto headroom does not require
raw traffic concentration above one: selection by value and link can matter
even when fewer attempts fall inside the nominal maneuver window. Conversely,
S4's higher event values do not translate into allocation or frontier
headroom. This is an important negative boundary, not a tuning target.

Across the ten controller-relevant links at the same explanatory point, the
five-seed mean evaluation scheduling-frequency max/min ratios are 1.60 (S2),
1.38 (S3), 1.85 (S4), 1.58 (S5), and 1.75 (S6). The oracle therefore does
allocate unevenly across links, but link selectivity alone is insufficient in
S4.

Every accepted action records predicted cross term, isolated energy, packet
arrival status and receiver residual before/after delivery. Mean accepted
position residual after update is exactly zero at the explanatory point, as
required by the current-state payload semantics. The aggregate action audit
contains 296,049 Stage-A and 531,946 Stage-B actions. It distinguishes channel
failure from accepted information and stale/unresolved no-information
attempts. Realized branch benefit is deliberately `NaN` for single-trajectory
O1 actions; estimating it would require a paired counterfactual rerun. The
separate frozen branch experiment remains the valid source for that measure.

## 6. Interpretation and decision

The decisive question for this gate was whether the cross-term signal creates
Pareto headroom over a well-tuned periodic frontier. The answer is **yes on
the frozen development set, but not universally**.

The strongest defensible branch-signal statement remains:

> On the preregistered S2/S6 counterfactual branch set, the cross-term
> predictor exhibits materially stronger association with realized
> transmission benefit than the isolated predictor and perfectly identifies
> beneficial actions within the tested top-value quartile.

O1 adds the separate result that this signal produces convincing complete-
domain frontier headroom in S2 and S6, and convincing but crossing-dependent
headroom in S5. It does not do so in S4.

Because Stage A passed strongly, O2 was not required and was not run. Under
the preregistered decision matrix, the research recommendation is
`GO_ACK_BELIEF_POLICY`: the next scientific gate should test whether a causal,
distributed ACK-based belief can approximate current receiver residual well
enough to retain O1 headroom. This report does **not** authorize held-out
seeds, Gates 7--10 or a large scalability sweep, and it does not promote O1
to a proposed algorithm.

## 7. Reproducibility artifacts

- Stage-A protocol: `paper/tcns/ORACLE_FRONTIER_PROTOCOL.md`
- Stage-B protocol: `paper/tcns/ORACLE_STAGE_B_PROTOCOL.md`
- Stage-A entry point: `experiments/tcns_o1_oracle_frontier_stage_a.m`
- Stage-B entry point: `experiments/tcns_o1_oracle_frontier_stage_b.m`
- Stage-A machine-readable result:
  `results/tcns_o1_oracle_frontier_stage_a/2026-09-07_160426/`
- Stage-B machine-readable result:
  `results/tcns_o1_oracle_frontier_stage_b/2026-09-07_162102/`

Each result directory contains tidy per-run rows, aggregate/frontier tables,
both matched domains, scenario decisions, periodic identity audit, per-link
logs, event time traces, figures, console diary and metadata. Full action CSVs
are stored losslessly as `oracle_actions.csv.zip` to stay below repository
file-size limits. The ignored MATLAB workspace and `.fig` binaries are not
required to reproduce any reported number or PNG.
