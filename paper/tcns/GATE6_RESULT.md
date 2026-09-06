# Gate-6 nonstationary result and stop decision

**Technical verdict:** `PASS`

**Scientific verdict:** `STOP_CURRENT_MECHANISM`

**Accepted run:**
`results/tcns_gate6_nonstationary_frontiers/2026-09-07_012209`

**Source commit:** `9d5d8c0`; MATLAB R2025a.

## Technical validity

All 690 preregistered simulations completed: six scenarios, 23 arms and five
paired development seeds. Every output row is finite, no trajectory diverges,
all control-aware causal/protocol invariant counts are zero, and all arms
within a scenario/seed consume the same exact forward trace. Every scenario
has 11 periodic and 11 control-aware frontier points and both 101-point
matching domains are nonempty.

Forty-nine runs touch command saturation. They remain in the raw data. Most
occur under the S5 topology outage (22 periodic, 22 control-aware and two
historical-reference runs); the remaining three are low-rate periodic S3/S4
runs. These points are valid empirical saturated-system outcomes but outside
the current linear theorem scope.

## Preregistered matched result

All differences below are control-aware minus periodic and cover the complete
shared observed domain. Positive is unfavorable to control-aware.

| Scenario | Mean budget-matched RMSE difference [m] | Budget overlap favoring control | Mean performance-matched cost difference [Hz/channel] | Performance overlap favoring control | Support |
|---|---:|---:|---:|---:|---:|
| S1 Stationary-Moderate | +0.0220 | 0% | +1.479 | 0% | no |
| S2 Formation-switching | +0.0111 | 0% | +1.081 | 0% | no |
| S3 Gilbert-Elliott burst loss | +0.0187 | 0% | +1.177 | 0% | no |
| S4 Time-varying congestion | +0.0196 | 0% | +1.249 | 0% | no |
| S5 Topology perturbation | +0.0186 | 0% | +1.456 | 0% | no |
| S6 Dynamic excitation | +0.0183 | 0% | +1.337 | 0% | no |

The frozen scientific rule required support in at least two of S2--S6. The
observed count is zero. This is not a borderline threshold failure: periodic
is better at every one of the 101 budget-matched and every one of the 101
performance-matched points in every scenario.

## Mechanism diagnosis supported by the logs

The control-aware event-traffic concentration divided by event-duration
fraction would exceed one if traffic were preferentially allocated to event
windows. Averaged across control-aware sweep arms, it is:

- S2 formation switching: 1.032 (range 0.967--1.146);
- S3, whose event window is the full evaluation interval: exactly 1 by
  construction;
- S4 time-varying congestion: 1.002 (0.992--1.013);
- S5 topology perturbation: 0.967 (0.813--1.281);
- S6 dynamic excitation: 1.071 (1.026--1.102).

Thus the present mechanism does not materially concentrate communication in
the intervals for which adaptivity was hypothesized to matter. This is
consistent with its construction: the worst-case ACK-confirmed-plus-all-
outstanding set often remains above budget until ACK contraction, and the
fixed conditional retry then spreads effort through time. The causal set is a
valid uncertainty certificate, but validity alone does not make its worst-case
radius a useful value-of-information scheduler.

This is a diagnosis from the observed mechanism logs, not a theorem that no
control-aware scheduler can succeed.

## What is falsified and what survives

Falsified for the current Gate-4 policy and tested cost definition:

- a full-frontier advantage over fixed periodic communication in stationary
  conditions;
- the hypothesis that this particular possible-set budget trigger gains an
  advantage under formation switching, burst loss, congestion switching,
  temporary topology loss or follower excitation;
- the claim that its traffic is meaningfully concentrated around high-value
  intervals.

Still valid:

- the exact sampled model and scope audit from Gate 1;
- the deterministic staleness/state uncertainty bounds from Gate 2;
- causal sender information-set containment;
- the exact degradation recurrence and structured finite-horizon/ISS-UUB
  certificate from Gate 3;
- the negative result itself, including the evidence that a well-swept
  periodic frontier is a stronger comparator than Periodic10.

The conclusion is specific to `DATA+0.25 ACK`, the tested DI/N=5 scenarios and
the present policy. Airtime/MAC/scalability claims have not been made.

## Enforced stop

Gate 7 robustness-grid execution, Gate 8 scalability, final acceptance freeze
and held-out evaluation are **not authorized** for the current mechanism.
Continuing them would spend computation validating a mechanism that failed its
predeclared scientific premise.

Any continuation requires an explicit new scientific decision, for example:

1. retain Gates 1--3 as the core and pursue a theory-first paper about
   communication-induced uncertainty/robustness and conditions or limits of
   freshness scheduling;
2. design a genuinely predictive/probabilistic VoI scheduler whose action is
   based on expected finite-horizon reduction, keeping the Gate-4 policy as a
   falsified ablation;
3. reconsider the target contribution before implementing another policy.

It is not permissible to tune retry, the epsilon grid or scenario definitions
until the current policy appears to beat periodic.

