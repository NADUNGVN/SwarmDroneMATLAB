# FB0 feedback-economics report

**Technical verdict:** `PASS`  
**Trajectory reruns:** 0  
**Authoritative run:** `2026-09-07_175224`  
**Protocol commit:** `91a95bb`  
**Explicit-ACK architecture remains:** `STOP_ACK_BELIEF_IMPLEMENTATION`

## Result in one sentence

The frozen O1 headroom can pay for full feedback at price 0.25 throughout
S2's four performance-matchable operating points, but not throughout any
other scenario: median affordable feedback fractions are 87.9% in S3, 0% in
S4, 0% in S5, and 37.8% in S6 after operational clipping.

This result quantifies the feedback-economics boundary. It does not reopen or
rescue the stopped explicit-ACK architecture.

## Definition

For each frozen O1 operating point \(r\), FB0 uses

\[
C_r(\eta,f)=D_r+\eta f A_r,
\]

where \(D_r\) is O1 DATA cost and \(A_r\) is the rate of accepted deliveries
eligible for protocol-equivalent feedback. The unchanged periodic Pareto
frontier is interpolated at O1 formation RMSE \(E_r\), without extrapolation.
The full-feedback break-even price and the affordable feedback fraction at
the frozen price \(0.25\) are

\[
\eta_r^\star=\frac{C_P(E_r)-D_r}{A_r},\qquad
f_r^\star=\frac{\eta_r^\star}{0.25}.
\]

Negative \(\eta_r^\star\) means that O1 DATA alone already costs more than
periodic at the same interpolated performance. Values
\(\eta_r^\star\ge 0.25\) can afford one feedback for every accepted delivery.

## Scenario economics

Statistics include every O1 operating point inside the periodic frontier's
observed performance interval and having nonzero feedback rate. Raw
\(f^\star\) is shown so that negative headroom and headroom above 100% remain
visible; the operational fraction is clipped to \([0,1]\).

| Scenario | Eligible / 14 | Median \(\eta^\star\) | IQR \(\eta^\star\) | Min--max \(\eta^\star\) | Median raw \(f^\star\) | Positive headroom | Full feedback affordable |
|---|---:|---:|---:|---:|---:|---:|---:|
| S2 formation switching | 4 | 0.726 | 0.556--2.186 | 0.529--3.504 | 2.904 | 100.0% | 100.0% |
| S3 burst loss | 11 | 0.220 | 0.186--0.249 | -0.276--0.447 | 0.879 | 90.9% | 27.3% |
| S4 congestion | 11 | -0.741 | -0.814---0.173 | -0.814---0.073 | -2.966 | 0.0% | 0.0% |
| S5 topology perturbation | 11 | -0.047 | -0.070--0.173 | -0.075--0.387 | -0.190 | 27.3% | 9.1% |
| S6 dynamic excitation | 11 | 0.095 | 0.032--0.367 | 0.029--0.403 | 0.378 | 100.0% | 36.4% |

At price 0.25, the medians after clipping are therefore 100.0%, 87.9%, 0%,
0%, and 37.8% for S2--S6 respectively.

## Interpretation by regime

- **S2:** feedback cost is not the limiting factor inside the shared
  performance domain. The four eligible points tolerate a minimum price of
  0.529 per feedback, more than twice the frozen price. Ten lower-error O1
  points outperform the best observed periodic error and are deliberately
  excluded because matching them would require extrapolation.
- **S3:** the median price is just below 0.25. Most points have some DATA-only
  headroom, but only 3/11 can pay for full feedback. This explains why C2
  removes the scenario-level frontier classification despite a narrow C0
  advantage.
- **S4:** every eligible point has negative break-even price. This is the
  strongest negative boundary: removing feedback cannot make O1
  performance-matched cost-competitive.
- **S5:** headroom is concentrated in only 3/11 eligible points and only one
  can afford full feedback. The median point is already uneconomic before
  feedback.
- **S6:** every eligible point has positive DATA-only headroom, but the median
  can afford feedback on only 37.8% of eligible deliveries at price 0.25.
  Four of eleven points can afford full feedback.

Thus the ACK-free track is economically motivated in S6 and parts of S3/S5,
while S2 is a control-scheduling case whose headroom is large enough to absorb
the audited explicit feedback cost. The no-ACK mechanism still has to pass
novelty, exactness, calibration, and predictive-validity gates; FB0 alone says
nothing about those properties.

## Audit checks

All preregistered checks passed:

- 625 source rows, including 350 frozen O1 runs;
- five development seeds per arm and no failed runs;
- C1=C2 for all source O1 runs;
- nonnegative feedback rates;
- C2 reconstructed as DATA + 0.25 feedback rate to numerical tolerance;
- finite break-even quantities for all 48 eligible points;
- exact algebraic agreement \(f^\star=\eta^\star/0.25\);
- no held-out seeds and zero trajectory reruns.

The 22 excluded points are all outside the observed periodic performance
domain. None was extrapolated or silently discarded from the machine-readable
point table.

## Reproduction

From the repository root:

```matlab
run('tests/test_tcns_fb0_feedback_economics.m')
run('experiments/tcns_fb0_feedback_economics.m')
```

Authoritative outputs are under
`results/tcns_fb0_feedback_economics/2026-09-07_175224/`:

- `feedback_economics_points.csv`: all 70 O1 points and exclusion reasons;
- `scenario_summary.csv`: scenario-level economics;
- `periodic_frontiers.csv`: exact frozen comparator points;
- `summary.json`: integrity checks and provenance;
- `workspace.mat`, console log, metadata, and generated figure.

