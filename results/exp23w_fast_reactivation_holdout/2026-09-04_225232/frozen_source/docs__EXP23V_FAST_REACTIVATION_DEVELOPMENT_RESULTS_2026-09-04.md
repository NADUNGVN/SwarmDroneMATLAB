# EXP23V — Witness-confirmed fast-reactivation development results

Run: `results/exp23v_fast_reactivation_development/2026-09-04_222905`

Status: **FAST_REACTIVATION_DEVELOPMENT_FEASIBLE (18/18 gates)**.

EXP23V completed 180/180 trajectories over the 60 deliberately reused paired
EXP23U seeds. It is a same-seed mechanism probe and is not confirmatory
evidence. All trace, estimator, clock and shared-background realizations match
their EXP23U source by seed. The result cannot promote a submission claim.

The fast mechanism reactivated in all 120/120 delivered-RESPONSE trajectories.
Early events reactivated a mean 59.98 frames before the conservative old fence
and late events a mean 84.25 frames before it. Fresh witness closure required a
mean 1.18 and 1.25 frames after eligibility, respectively. All 60 permanent
RESPONSE-blackout trajectories remained suppressed with blocked incident
witnesses.

Relative to the matching conservative old-fence arms:

- early-event RMSE decreased 2.27%, from 0.057038 m to 0.055742 m; paired
  delta -0.001296 m, bootstrap 95% CI `[-0.001585, -0.001051]`;
- late-event RMSE decreased 6.17%, from 0.060346 m to 0.056625 m; paired
  delta -0.003721 m, bootstrap 95% CI `[-0.004252, -0.003228]`;
- offered utilization increased 3.76% and 3.78%, with strictly positive
  paired delta CIs, because useful scheduled service resumes earlier;
- neither fast delivered arm is epsilon-dominated by the fixed periodic
  reference under the registered 1%/1% rule.

The early fast arm is effectively level with static coherence in RMSE
(-0.005%) while using 0.36% less offered utilization. This is descriptive
development evidence, not a fresh-seed claim.

Every candidate row has zero scheduled-collision frames, false-valid edge
frames, safety failures and divergence. Continuous DATA/control replay,
affine-clock composition, shared-background overlay, management byte/airtime
accounting, recipient accounting and causal forbidden-read checks all close.
The RESPONSE-blackout arm is unchanged from the conservative policy and is
epsilon-dominated by periodic; this negative fail-silent boundary is retained.

Decision: freeze the mechanism and open one disjoint, preregistered fresh-seed
confirmation. Online graph replacement is not tested here; only an unchanged
fixed graph, whose old/new union is exact, is covered.
