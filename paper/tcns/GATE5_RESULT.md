# Gate-5 stationary frontier result

**Verdict:** infrastructure `PASS`; stationary performance hypothesis
`FALSIFIED` for the current control-aware mechanism relative to the periodic
frontier on this development design.

**Accepted run:**
`results/tcns_gate5_stationary_frontiers/2026-09-07_010403`

**Source commit:** `88b6705`; MATLAB R2025a.

## Evidence

All 115 scheduled DI simulations completed: 23 arms (11 periodic periods, 11
control-aware degradation budgets and one frozen Causal-v3 reference) over
five paired development seeds. Every control-aware protocol invariant is zero,
every seed shares its forward trace across arms, and no run diverges. Two of
the lowest-rate Periodic-40-step runs touch acceleration saturation briefly;
they remain in the raw dataset and are flagged.

Every one of the 11 periodic points and 11 control-aware points is
non-dominated within its own family. The common mean-frontier domains are:

- communication budget: 2.862--25.975 `DATA+0.25 ACK` Hz/channel;
- formation RMSE: 0.1119--0.4924 m.

Across the preregistered 101-point budget-matched grid, the control-aware RMSE
minus periodic RMSE is positive at every point. Its grid mean is
`+0.03023 m`. Across the 101-point performance-matched grid, control-aware cost
minus periodic cost is also positive at every point, with grid mean
`+2.092 Hz/channel`. Thus the fraction of either overlap favoring
control-aware is exactly zero in this stationary development study.

Frozen Causal-v3 is retained only as a historical single-point reference. It
has mean RMSE 0.1169 m at 20.988 Hz/channel and does not define a comparison
frontier.

## Interpretation

This result confirms the original warning against attempting to tune until a
method beats Periodic10. Here the conclusion is stronger than a P10 point
comparison: the full periodic frontier dominates the full control-aware
frontier on their shared stationary domain.

This does not yet falsify the project's secondary hypothesis, because the
Gate-5 channel and formation demand are stationary. Gate 6 was explicitly
ordered to test formation maneuvers, burst loss, time-varying delay,
topology perturbation and dynamic excitation—settings where information value
is time-varying. The present result prevents stationary superiority language
and makes Gate 6 a real go/no-go test rather than a demonstration exercise.

If comparable automatic frontier analysis shows consistent periodic
dominance in the nonstationary regimes as well, the current Gate-4 policy must
be stopped or scientifically reframed. No retry interval, epsilon value or
scenario parameter may be changed merely to reverse that conclusion.

## Limitations carried forward

- Five development seeds are sufficient for frontier mechanics, not final
  inferential statistics; Gate 9 still requires paired uncertainty/effect
  analysis.
- Matching here interpolates frontiers of seed-aggregated means. Final matched
  inference should also operate on paired seed-level outcomes.
- The configured graph includes communication into the analytical leader even
  though its controller ignores neighbor states. Gate 4 deliberately retained
  legacy behavior on those links so that only the proposed method did not
  receive a cost removal. A later common controller-relevant communication
  graph may be tested only if applied identically to every method and recorded
  as a separate design.
- `DATA+0.25 ACK` remains one accounting choice. DATA-only, airtime, broadcast
  and shared-medium conclusions remain separate required analyses.

