# AF2 passive ACK-free belief calibration report

**Verdict:** `AF2_CALIBRATION_PASS`  
**Scenarios:** S2 and S6 development only  
**Active scheduling:** not executed  
**Authoritative run:**
`results/tcns_af2_passive_ack_free_calibration/2026-09-07_215747`  
**Producing commit:** `f688525`  
**MATLAB:** R2025a

## Result

The exact AF0 communication-filtration PMF passed every frozen AF2 condition
in both S2 and S6.  Each scenario contains 55,000 scored link/sample
observations from five paired development seeds and 10,396,980
candidate-state probability forecasts.

| Metric | Frozen limit | S2 | S6 |
|---|---:|---:|---:|
| Support violations | 0 | 0 | 0 |
| Maximum normalization residual | \(10^{-12}\) | \(2.22\times10^{-16}\) | \(2.22\times10^{-16}\) |
| Mean NLL | report | 0.64051 | 0.64051 |
| Mean conditional entropy | report | 0.62550 | 0.62550 |
| \(|\mathrm{NLL}-H|\) | 0.05 | 0.01501 | 0.01501 |
| Mean Brier score | report | 0.33887 | 0.33887 |
| Mean conditional Bayes Brier | report | 0.33333 | 0.33333 |
| \(|\mathrm{BS}-B_0|\) | 0.03 | 0.00553 | 0.00553 |
| ECE | 0.03 | \(3.87\times10^{-5}\) | \(3.87\times10^{-5}\) |
| MCE, bins with at least 100 forecasts | 0.10 | 0.00365 | 0.00365 |
| MAP receiver-identity accuracy | report | 0.79635 | 0.79635 |

S2 and S6 have identical state-identity calibration statistics because they
use the same P10 send schedule, channel law, and seed-indexed network traces.
Their plant trajectories differ, which is reflected in the control-residual
diagnostics below.

## Control-residual diagnostics

| Metric | S2 | S6 |
|---|---:|---:|
| Vector-component correlation, \(E[d^c]\) vs realized \(d^c\) | 0.9270 | 0.9290 |
| Vector RMSE | 0.02286 | 0.02246 |
| Vector bias norm | \(2.93\times10^{-4}\) | \(1.87\times10^{-4}\) |
| Correlation, \(E[\lVert d^c\rVert]\) vs realized norm | 0.6792 | 0.6765 |
| Norm RMSE | 0.02283 | 0.02242 |
| Norm bias | \(-4.59\times10^{-4}\) | \(-2.82\times10^{-4}\) |
| Correlation, \(E[\lVert d^c\rVert^2]\) vs realized square | 0.5333 | 0.5863 |
| Second-moment RMSE | 0.00504 | 0.00528 |
| Second-moment bias | \(-9.97\times10^{-5}\) | \(-5.40\times10^{-5}\) |

The PMF is well calibrated as a distribution; the posterior mean is not
expected to reproduce each stochastic realization.  The residual results
are therefore explanatory diagnostics, not an added pass/fail threshold.

## Reliability detail

The newest matured packet has theoretical mass 0.8 and was realized with
frequency 0.79635.  The immediately previous packet has theoretical mass
0.16 and empirical frequency 0.16071.  All older states pooled below
probability 0.1 have mean forecast \(2.139\times10^{-4}\) and empirical
frequency \(2.296\times10^{-4}\).

The mean support size is 189.0 and the maximum is 299 packet identities.
No truncation or probability-mass approximation was used.

## Interpretation boundary

AF2 establishes that the geometric packet-memory PMF matches the simulator's
receiver outcomes under the fixed passive P10 schedule, static IID erasure,
and deterministic delay.  It does **not** establish:

- calibration after endogenous state-dependent scheduling;
- that the PMF is the full posterior conditional on all local plant
  observations;
- sender-local availability of the Gate-3 cross-term;
- predictive validity of \(\bar q\);
- Pareto headroom for a deployable scheduler.

The next authorized gate is AF3.  It must compute the expectation over packet
states, not evaluate a nonlinear score at an expected receiver state.  The
track stops before AF4/AF5 if exact Gate-3 value requires undeclared global or
receiver truth, or if the candidate collapses to prior expected-error
triggering.

## Reproduction

```matlab
run('tests/test_tcns_ack_free_receiver_belief.m')
run('tests/test_tcns_af2_residual_moments.m')
run('experiments/tcns_af2_passive_ack_free_calibration.m')
```

Machine-readable outputs are `tidy.csv`, `calibration_bins.csv`,
`scenario_summary.csv`, `run_provenance.csv`, and `summary.json` within the
authoritative run directory.

