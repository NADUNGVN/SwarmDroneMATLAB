# Predictive-VoI online-policy sanity protocol

**Classification:** smallest post-Gate-6 online development falsification.

**Status at freeze:** implementation and protocol prepared; no online-policy
frontier result has been observed.

## Question

Does the causal, in-flight-aware one-shot value from Lemmas PV-1--PV-2 produce
a real communication/performance frontier and allocate its own actions toward
state-driven events, or does it immediately collapse to another policy that
periodic communication dominates everywhere?

This is not final evidence and uses no held-out seed.

## Frozen design

- Scenarios: Gate-6 S2 formation switching and S6 dynamic excitation.
- Seed: 27020001 only, already used for development.
- Plant/controller: exact N=5 DI subsystem; 30 s horizon; 8 s evaluation
  start; Moderate static IID forward loss 0.2; deterministic four-sample DATA
  and ACK delays; reliable ACKs.
- Value horizon: H=25 samples=0.50 s.
- Predictive decision: transmit link \(j\to i\) iff
  \(\nu_{ij}(k)>\lambda\), subject only to the one-sample refractory interval.
  There is no fixed retry, AoI threshold, or receiver/drop oracle.
- VoI-price sweep:
  `0, 1e-8, 3e-8, 1e-7, 3e-7, 1e-6, 3e-6, 1e-5, 3e-5,
  1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 1`.
- Periodic sweep: `1, 2, 3, 4, 5, 8, 10, 15, 20, 25, 40` samples, identical
  to Gates 5--6.
- References only: frozen Causal-v3 and the stopped Gate-4 control-aware
  policy at \(\epsilon_d=0.4\) m and retry 0.10 s. Neither reference defines a
  frontier or a decision threshold.
- Cost: evaluation-window `DATA + 0.25 ACK` per configured channel per second.
- Performance: scenario-specific primary formation RMSE from Gate 6.

The price grid is deliberately broad and log-spaced. It was frozen without
viewing any S2/S6 policy result and is not refined inside this experiment.

## Required audits

1. all 56 scheduled runs complete with finite results;
2. all causal/protocol invariants are zero;
3. every arm in a scenario consumes the same forward trace;
4. no run diverges, and saturation is retained rather than censored;
5. at least five distinct predictive communication costs exist per scenario;
6. at least three unsaturated predictive points exist per scenario;
7. both periodic and predictive families yield at least three Pareto points
   and a nonempty automatic matching domain;
8. the causal score observes multi-candidate beliefs, known failed packets,
   and a finite in-flight discount;
9. increasing price is reported without requiring strict traffic monotonicity,
   because endogenous state/ACK trajectories differ across arms.

## Frozen go/no-go rule

For each scenario, compute the complete 101-point shared budget and
performance matching domains. A scenario has **frontier headroom** when either
more than 25% of its budget overlap has lower predictive RMSE or more than 25%
of its performance overlap has lower predictive cost.

Across all non-endpoint price arms (`0 < lambda < 1`) that transmit at least
once in the evaluation interval, compute the mean allocation ratio of
predictive actions to the declared event windows. The mechanism concentration
test requires a ratio above 1.15 in both S2 and S6.

The decision is:

- `MECHANISM_PROMISING`: technical audits pass, at least one scenario has
  frontier headroom, and both scenarios pass event concentration;
- `STOP_PREDICTIVE_MECHANISM`: technical audits pass but the scientific rule
  fails;
- `INVALID_OR_OUT_OF_SCOPE`: a technical audit fails.

A promising decision authorizes a five-seed development frontier with the
same frozen grid. It does not authorize Gate 7, scalability, held-out seeds or
a superiority claim.

## Interpretation limits

The exact posterior applies only to this reliable-ACK deterministic-delay IID
scope. The policy's one-shot value remains an isolated-action quantity and is
not an exact global cost-to-go advantage. The Gate-4 falsification remains in
force regardless of this result.

