# Centralized quadratic cross-term diagnostic result

**Technical verdict:** `PASS`

**Scientific verdict:** `CROSS_TERM_MATERIAL`

**Accepted run:**
`results/tcns_cross_term_oracle_diagnostic/2026-09-07_113834`

**Source commit:** `403b9e6`; MATLAB R2025a.

## Technical evidence

All 15 frozen development runs completed: S1, S2, and S6 on paired seeds
27020001--27020005. The artifact contains 161,400 positive-isolated
link/time candidates, exactly 10,760 per run. Every run is unsaturated in the
evaluation interval. The static channel has the expected four-sample delay
and 0.8 delivery probability. The largest direct-versus-decomposed quadratic
identity residual is \(3.16\times10^{-15}\), well below the preregistered
\(10^{-12}\) tolerance.

The complete candidate-level dataset, run summaries, decision table, source
snapshot, metadata, console log, and generated figure are retained. No
candidate or threshold was selected after viewing the result.

## Frozen scientific decision

| Scenario | Non-beneficial fraction | Top-decile overlap | Pearson correlation | Cross term dominates | Median \(|C_{cross}|/E_{iso}\) | Event allocation of positive benefit |
|---|---:|---:|---:|---:|---:|---:|
| S1 Stationary nominal | 0.0000 | 0.7727 | 0.9081 | 1.0000 | 151.4 | n/a |
| S2 Formation switching | 0.0897 | 0.6446 | 0.5479 | 0.9979 | 141.0 | 0.960 |
| S6 Dynamic excitation | 0.00175 | 0.7342 | 0.8737 | 0.9998 | 138.8 | 1.238 |

The sign gate required a mean non-beneficial fraction of at least 0.10. It
does not pass: S2 reaches 0.0897 and S6 only 0.00175. The independent ranking
gate required top-decile overlap at most 0.80. It passes in both S2 and S6,
at 0.6446 and 0.7342. The preregistered OR within each scenario and AND across
both dynamic scenarios therefore yields `CROSS_TERM_MATERIAL`.

## Interpretation

The isolated action-response energy is not numerically close to total
quadratic marginal benefit. The cross contribution exceeds the isolated
energy for more than 99.7% of candidates and is roughly 139--151 times larger
at the per-run median. This does not mean the old score has the wrong sign in
most cases: the total fixed-input benefit remains positive for all S1
candidates, more than 91% in S2, and more than 99.8% in S6. It means the
global formation-error alignment controls the magnitude and materially
reorders the highest-value actions.

The strongest ranking loss occurs in S2, where the Pearson correlation falls
to 0.548 and only 64.5% of the isolated-score top decile remains in the total-
benefit top decile. Positive total benefit is not concentrated in S2's
formation-switch windows (allocation 0.960), whereas it is moderately
concentrated in S6's excitation windows (1.238). Thus “nonstationarity” is not
itself sufficient; the type of excitation matters.

This supplies a concrete mechanism explanation for the stopped online
policy. Its local score generally detects nonzero state novelty, but it lacks
the action-conditioned alignment with current global formation error needed
to rank competing transmissions correctly. The result supports the
information-identifiability checkpoint; it does not yet show that any richer
policy beats periodic communication.

## Strict scope boundary

This diagnostic is centralized and uses receiver truth. It freezes future
network inputs/payloads to the logged P10 trajectory and lets the candidate
correction persist throughout the 0.5 s horizon. It does not model later
packet replacement, in-flight redundancy, state-dependent future payloads,
or receding decisions. Consequently:

- `CROSS_TERM_MATERIAL` is not an online-policy result;
- the scatter is not a communication/performance frontier;
- the total-benefit values are not claimed to equal true endogenous branch
  returns;
- Gate 7, scalability, and held-out evaluation remain closed.

## Authorized next step

The result authorizes one preregistered true branch-at-decision diagnostic.
It must inject or suppress individual transmissions in paired simulations,
reuse exactly the same channel trace, and measure realized finite-horizon
formation-cost change. The immediate question is whether the fixed-input
cross-term score predicts true branch value well enough to justify designing
a richer causal information architecture.

Only if that branch diagnostic shows both ranking validity and centralized
action-space headroom may a receiver-residual/adjoint policy be designed. Its
extra reverse/control traffic must then be charged explicitly. Otherwise the
predictive mechanism family stops despite the present algebraic result.
