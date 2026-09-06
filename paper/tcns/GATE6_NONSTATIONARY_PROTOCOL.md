# Gate-6 nonstationary frontier protocol

**Classification:** decisive development falsification before acceptance
criteria are frozen and before any held-out evaluation.

## Question

Gate 5 established that the current control-aware frontier is dominated by
periodic communication in stationary Stressed conditions. Gate 6 tests the
predeclared secondary hypothesis: adaptivity should be most valuable when the
marginal value of information changes within a mission.

## Frozen scenarios

All scenarios use N=5, the exact DI controller/plant, 30 s horizon, 8 s general
warm-up and the same Moderate channel unless the scenario explicitly changes
it. The scenario builder is `utils/tcnsGate6Scenario.m`.

- **S1 Stationary-Moderate:** negative-control scenario; unchanged formation,
  IID loss 0.20 and delay 0.08 s.
- **S2 Formation-switching:** continuous 90-degree desired-formation rotation
  on 10--14 s and return on 20--24 s. Performance windows include four seconds
  of post-maneuver response.
- **S3 Gilbert-Elliott burst loss:** forward good/bad transitions per 0.02 s
  tick are 0.04/0.06; good/bad drop probabilities are 0.05/0.95. The
  stationary mean drop probability is approximately 0.41 and a bad-state run
  averages about 0.33 s. ACKs remain reliable with Moderate delay.
- **S4 Time-varying congestion:** Moderate, Congested, Clean, Moderate channel
  segments beginning at 0, 10, 16 and 22 s. Congested uses loss 0.40, delay
  0.18 s and jitter standard deviation 0.04 s. ACK delay/jitter follows the
  same schedule; ACK loss remains zero.
- **S5 Topology perturbation:** 30% of configured directed DATA links are
  unavailable on 12--18 s and then return. The affected links are seeded and
  method-blind; controller graph and cost denominator remain fixed.
- **S6 Dynamic excitation:** method-blind 0.8 m/s² sine-acceleration episodes
  excite follower 3 in x on 12--16 s and follower 4 in y on 20--24 s.

S2--S6 change different sources of information value. They are not multiple
severity levels of one cherry-picked scenario.

## Frozen policies and seeds

- Periodic sample periods:
  `1, 2, 3, 4, 5, 8, 10, 15, 20, 25, 40`.
- Control-aware position-degradation budgets:
  `0.05, 0.075, 0.10, 0.15, 0.20, 0.30, 0.40, 0.60, 0.80, 1.20, 1.60` m.
- Conditional retry: 0.10 s for every control-aware arm.
- Frozen Causal-v3: retained as a one-point historical reference, never used
  to define either comparison frontier.
- Paired development seeds: 27020001--27020005.

No parameter may be changed by scenario or after observing results.

## Metrics and matching

Communication cost is `DATA+0.25 ACK` per configured channel per second,
restricted to 8--30 s. Performance is formation RMSE in scenario-specific,
predeclared windows: full 8--30 s for S1/S3, maneuver plus recovery for S2,
10--30 s for S4, outage plus four-second recovery for S5, and excitation plus
two-second recovery for S6.

Each family is weak-Pareto filtered on five-seed mean cost and mean primary
RMSE. For every scenario, fixed 101-point linear matching covers the complete
shared observed budget domain and the complete shared observed performance
domain without extrapolation. Differences are control-aware minus periodic;
negative favors control-aware.

Event/quiet communication and event allocation concentration are recorded as
mechanism diagnostics. They do not replace frontier evidence.

## Technical gate

The campaign is technically valid only if:

1. all 690 scheduled rows are present, finite and reproducible;
2. every control-aware run has zero causal/protocol violations;
3. all runs paired by scenario and seed use the same forward trace;
4. no run diverges;
5. each scenario yields at least three points per family frontier and both
   matching domains are nonempty;
6. raw rows retain saturation, failure, event/quiet and all parameter fields.

Saturation is reported and marks theorem scope; it does not delete an
operating point from the empirical frontier.

## Scientific go/no-go rule frozen before execution

A nonstationary scenario supports the current control-aware mechanism only if
all four conditions hold:

1. mean budget-matched RMSE difference is negative;
2. more than 50% of the complete budget overlap favors control-aware;
3. mean performance-matched communication-cost difference is negative;
4. more than 50% of the complete performance overlap favors control-aware.

Interpretation over S2--S6:

- support in at least 2 of 5 scenarios: `PROMISING`, proceed to freeze final
  acceptance criteria;
- support in exactly 1 scenario: `WEAK`, do not launch the robustness grid
  until the dependence is diagnosed without parameter retuning;
- support in 0 scenarios: `STOP_CURRENT_MECHANISM`; document falsification and
  reconsider the mechanism or contribution rather than tuning it to win.

S1 is a negative control and is never counted toward the threshold.

