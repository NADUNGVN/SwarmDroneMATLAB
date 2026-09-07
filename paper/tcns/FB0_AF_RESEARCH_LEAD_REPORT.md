# FB0--AF research package for Research Lead

**Package decision:** `STOP_ACK_FREE_ACTIVE_POLICY_AT_AF3`  
**Earliest valid stop reason:**
`EXACT_GATE3_VALUE_NOT_IDENTIFIED_BY_I_J_0`  
**Explicit-ACK stop preserved:**
`44d354fcba8f70576eb9c0e28206a23fae717aa8`
(`explicit_ack_stop_ab0`)  
**Held-out/scalability/manuscript expansion:** not executed

## 1. Executive result

The authorized sequence produced a useful but negative systems result:

1. feedback economics confirms that O1 headroom is highly sensitive to the
   cost of receiver feedback outside S2;
2. ACK-free receiver-memory inference is close prior art, but the exact
   candidate combination retained a narrow conditional novelty margin;
3. the no-feedback packet-memory PMF is exact under the declared
   communication filtration and is extremely well calibrated on passive
   S2/S6 P10 traces;
4. nevertheless, this belief identifies only the isolated action response,
   not the Gate-3 baseline/action cross-term that created O1 headroom;
5. therefore the exact expected Gate-3 value is not computable from the
   authorized sender information, and AF4/AF5 are stopped.

This outcome does not refute O1 scheduling headroom.  It shows that removing
ACK cost also removes the receiver/global information needed to realize O1's
validated ranking signal under the current distributed architecture.

## 2. Gate outcomes

| Stage | Decision | Evidence | Consequence |
|---|---|---|---|
| FB0 | `PASS` | Frozen offline ACK-price break-even analysis completed for S2--S6. | ACK-free research economically motivated, but not assumed viable. |
| FB1 | `CONDITIONAL_PASS` | No inspected paper covers the full three-part candidate; Viel et al. 2022 covers the belief/expected-error core. | Novelty can rest only on exact Gate-3 cross-term integration. |
| AF0--AF1 | `PASS_WITH_DECLARED_SCOPE` | Exact geometric packet-identity PMF, O(M) construction, tests and matched-support checks pass. | Proceed to passive calibration only. |
| AF2 | `CALIBRATION_PASS` in S2 and S6 | 110,000 observations, zero support violations, all preregistered calibration limits pass. | Proceed to AF3 only. |
| AF3 | `STOP` | Same belief/action responses admit exact expected values of opposite sign when the unavailable baseline projection changes. | No AF4; no active `ack_free_belief_value_v1`; no AF5. |

## 3. FB0 feedback economics

For every O1 point within the observed periodic performance domain, FB0
computed

\[
\eta_r^\star=\frac{C_P(E_r)-D_r}{A_r},
\qquad
f_r^\star=\frac{\eta_r^\star}{0.25}.
\]

No trajectory was rerun.  The source was the frozen AB0/O1 archive and no
extrapolation beyond the periodic performance domain was allowed.

| Scenario | Eligible O1 points | Median \(\eta^\star\) | Median raw \(f^\star\) at 0.25 | Full feedback affordable |
|---|---:|---:|---:|---:|
| S2 | 4/14 | 0.7260 | 2.904 | 100.0% |
| S3 | 11/14 | 0.2198 | 0.879 | 27.3% |
| S4 | 11/14 | -0.7414 | -2.966 | 0% |
| S5 | 11/14 | -0.0474 | -0.190 | 9.1% |
| S6 | 11/14 | 0.0946 | 0.378 | 36.4% |

S4 remains an explicit negative boundary.  Negative \(\eta^\star\) means O1
DATA alone is already uneconomic at that matched performance; free or cheaper
feedback cannot rescue those points.

Authoritative FB0 artifact:
`results/tcns_fb0_feedback_economics/2026-09-07_175224`.

## 4. FB1 novelty boundary

The closest collision is Viel et al., *Automatica*, 2022.  That work already
provides ACK-free packet-loss hypotheses for what neighbors may hold, expected
receiver-state error moments, and a distributed formation trigger with
stochastic Lyapunov analysis.  Dolk--Heemels and Garcia--Antsaklis further
establish no-ACK event-triggered control, while Soleymani et al. establish
finite-horizon marginal control VoI and Chiariotti--Fabris establish
signaling-free VoI-aware formation scheduling.

Therefore none of these are available novelty claims.  The only candidate
difference was:

> integrate a no-feedback receiver packet-identity PMF with the exact
> sampled, action-specific Gate-3 finite-horizon quadratic formation-impact
> cross-term.

No inspected source covered that complete combination, so FB1 permitted a
falsification attempt.  It did not grant a novelty claim.  Full details and
primary links are in `FB1_ACK_FREE_NOVELTY_AUDIT.md`.

## 5. AF0--AF2 result

Under static IID erasure probability 0.2 and deterministic four-sample DATA
delay, let \(r_1,\ldots,r_M\) be matured attempts from oldest to newest.  The
exact communication-filtration recursion is

\[
b_m=p b_{m-1}+(1-p)\delta_{r_m},
\]

or

\[
P(R=r_0)=p^M,
\qquad
P(R=r_m)=(1-p)p^{M-m}.
\]

Construction is \(O(M)\) time/storage.  No probability mass is pruned.

AF2 used five development seeds, passive P10, and the 8--30 s window in both
S2 and S6.  Results per scenario:

| Metric | S2 | S6 |
|---|---:|---:|
| Observations | 55,000 | 55,000 |
| Candidate forecasts | 10,396,980 | 10,396,980 |
| Support violations | 0 | 0 |
| NLL minus entropy | 0.01501 | 0.01501 |
| Brier minus Bayes Brier | 0.00553 | 0.00553 |
| ECE | \(3.87\times10^{-5}\) | \(3.87\times10^{-5}\) |
| MCE | 0.00365 | 0.00365 |
| \(E[d^c]\) vector-component correlation | 0.9270 | 0.9290 |

Authoritative AF2 artifact:
`results/tcns_af2_passive_ack_free_calibration/2026-09-07_215747`.

The exactness scope is deliberately limited to the communication-only
filtration.  Conditioning on a complete closed-loop plant-observation history
or on endogenous active action times remains a documented proof gap.

## 6. AF3 stop derivation

The requested expected value is

\[
\bar q_{ij}(k)=
-\frac{2p_s}{m}\sum_s b_s\langle Z_s,G_{ij,s}\rangle_F
-\frac{p_s}{m}\sum_s b_s\lVert G_{ij,s}\rVert_F^2.
\]

AF0 supplies \(b_s\), and sender payload history supplies \(G_{ij,s}\).  It
does not supply \(Z_s\), the total no-action formation response.  That response
depends on the receiver's physical state, other incoming receiver memories,
leader memory, and the global formation residual.  These are absent from the
declared no-feedback sender information set.

The executable exact-kernel witness used belief
\([0.04,0.16,0.80]\) and obtained:

- known isolated term: 0.0155414497;
- hidden family \(Z_s=-G_s\): \(\bar q=+0.0155414497\);
- hidden family \(Z_s=+G_s\): \(\bar q=-0.0466243491\).

Thus identical receiver-memory belief and action responses do not identify
even the sign of the exact value.  A full dynamically reachable
indistinguishable-history impossibility theorem remains marked `PROOF GAP`;
the repository nevertheless has no authorized causal computation for the
missing projection.  Proceeding would require oracle truth or an unvalidated
surrogate, so the mandatory stop applies.

## 7. What was deliberately not done

- no AB0.3--AB0.10 explicit-ACK belief implementation;
- no ACK frequency/retry/cost/lambda/scenario/comparator tuning;
- no AF4 forced-action study using a substituted score;
- no `ack_free_belief_value_v1` implementation;
- no AF5 frontier;
- no held-out seeds, scalability campaign, or manuscript claim expansion.

## 8. Reproducibility and commits

Key commits in chronological order:

- `91a95bb0d511c3bd06e0dc1d129f9fbe813749c7` -- FB0 protocol;
- `aa4f847cbc2eca44b3a14dd92f868155cd17e800` -- FB0 result/report;
- `f8fa8228dc89c615319719b1d6b3b7038bcfcab7` -- FB1 audit;
- `f0ba0f316c4659b5f89855dd777e8bbc408af674` -- AF0--AF1 derivation/tests;
- `42af0b7a9d33ecb5be35fec313852c709a7e4879` -- AF2 protocol;
- `f68852595c672a233674b4f7668dc913150ba102` -- AF2 implementation;
- `fb8fc5b691d49ccf9574eab3dedb600bba42b6b5` -- AF2 result/report;
- `e08f97724edd226d35fdd0d61dbd495565fe40d1` -- AF3 stop witness/report.

Reproduction commands:

```matlab
run('tests/test_lock_regression.m')
run('tests/test_tcns_fb0_feedback_economics.m')
run('tests/test_tcns_ack_free_receiver_belief.m')
run('tests/test_tcns_af2_residual_moments.m')
run('tests/test_tcns_af2_calibration_artifact.m')
run('tests/test_tcns_ack_free_value_identifiability.m')
```

All six tests passed together after the AF3 stop commit.  MATLAB R2025a was
used.  FB0 and AF2 preserve seed/config/git provenance in machine-readable
JSON/CSV artifacts.

## 9. Recommendation

Return to Research Lead at this stop point.  Do not resume adaptive-policy
engineering under the present information architecture.  Any next track must
be separately authorized and must solve the economics of communicating or
locally certifying the missing cross-term statistic.  The scientifically
honest paper-level evidence currently consists of:

- validated centralized scheduling headroom with a clear S4 boundary;
- quantified feedback price sensitivity;
- an exact and calibrated ACK-free receiver-memory PMF;
- a demonstrated information-structure barrier between receiver-memory
  belief and total formation-impact value.

