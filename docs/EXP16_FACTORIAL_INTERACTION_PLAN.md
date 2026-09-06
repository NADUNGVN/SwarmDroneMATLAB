# EXP16 preregistered feedback-route-by-MAC interaction plan

## Scientific question

EXP14I validated three directional route choices, but separate within-cell
tests do not by themselves establish a statistical interaction. EXP16 tests
the narrower causal claim that changing the configured shared-medium access
mechanism changes the relative downstream value of adaptive standalone ACKs
versus piggyback-only confirmation.

The primary design is a matched 2-by-2 factorial:

| Factor | Level 0 | Level 1 |
|---|---|---|
| configured MAC | fully sensed p-persistent CSMA | slotted ALOHA |
| feedback route | piggyback-only | adaptive standalone + piggyback |

All four factorial cells use the same N=5 ring2 formation, Moderate
Gilbert--Elliott DATA/ACK model, zero background load, analytical access
scaling `pAccess=min(pConfigured,1/N)=0.20`, policy parameters, estimator,
initial state and mission horizon. For each seed, the same absolute random
arrays and channel-state realization are supplied to all cells. Thus the MAC
factor changes access semantics, not the exogenous loss realization.

A fixed-deadline hybrid ACK route is retained under each MAC as a secondary
practical baseline. It is excluded from the primary interaction estimand.

## Provenance boundary

- Version: `EXP16-FACTORIAL-INTERACTION-HOLDOUT-v1`.
- Design source: the completed EXP14I result and the IoT-J readiness audit.
- New holdout seeds: `16022001:16022100`.
- The seed block is disjoint from EXP14 and EXP14C--I.
- Development/smoke seed: `16021999`; it is not in the holdout block.
- The 100-seed count matches the preceding holdout. In EXP14I the paired
  interaction standardized effects were approximately 0.71 for RMSE and
  0.93 for offered utilization; the larger count deliberately permits
  substantial shrinkage on new traces rather than choosing a minimum powered
  sample after inspecting EXP16.
- Opening the holdout freezes the registry, code snapshot, estimands,
  multiplicity family, safety guard and claim ceiling.
- No route, threshold, hypothesis or exclusion rule may change after the
  first holdout run. Negative results remain reportable.

## Frozen matrix

Every seed runs six arms:

1. CSMA + adaptive standalone/piggyback;
2. CSMA + piggyback-only;
3. CSMA + fixed-deadline hybrid baseline;
4. ALOHA + adaptive standalone/piggyback;
5. ALOHA + piggyback-only;
6. ALOHA + fixed-deadline hybrid baseline.

The matrix contains `100 × 6 = 600` simulations. The primary factorial uses
arms 1, 2, 4 and 5. The two hybrid arms are descriptive references only.

## Primary estimands

Lower is better. For outcome `Y`, define the within-seed route contrast

`D_m(Y) = Y(adaptive,m) - Y(piggyback,m)`

for MAC `m`, and the interaction

`I(Y) = D_ALOHA(Y) - D_CSMA(Y)`.

The registered sign reversal is:

- CSMA: `D_CSMA(Y) > 0`, so piggyback-only is better;
- ALOHA: `D_ALOHA(Y) < 0`, so adaptive ACK is better;
- interaction: `I(Y) < 0`, so the relative adaptive-ACK effect moves in the
  registered direction when CSMA is replaced by ALOHA.

For implementation, all alternatives are oriented below zero:

1. `Y(piggyback,CSMA) - Y(adaptive,CSMA) < 0`;
2. `Y(adaptive,ALOHA) - Y(piggyback,ALOHA) < 0`;
3. `I(Y) < 0`.

The outcomes are formation RMSE and offered airtime utilization. Their six
one-sided paired t-test p-values form one Holm family at familywise
`alpha=0.05`. A metric supports reversal only if its two simple effects and
interaction reject after Holm adjustment. The global registered claim
requires all six rejections.

For every estimand, report the seed-level mean, 95% paired t interval and a
deterministic 10,000-resample paired percentile-bootstrap interval. The
interaction is computed per seed before inference; MAC cells are not treated
as independent samples.

## Safety and divergence

Divergence is retained as a failure and makes its continuous pair ineligible.
The continuous primary family requires all 100 complete seed-level contrasts.
In addition, the observed failure count of the registered winning route may
not exceed the losing route under either MAC:

- CSMA: piggyback failures no greater than adaptive failures;
- ALOHA: adaptive failures no greater than piggyback failures.

This is an observed guard, not a population-safety test. Wilson intervals are
reported for all six arms. Zero observed failures does not establish a zero
population rate.

## Secondary analysis

The fixed-deadline hybrid arms are compared descriptively with adaptive and
piggyback routes within each MAC using paired intervals. Mean true AoI,
channel utilization, collisions, DATA attempts, ACK attempts and standalone
ACK count are mechanism outcomes. They are not part of the confirmatory
family and cannot rescue a failed primary claim.

## Integrity gates

Performance analysis opens only after all gates pass:

- registry hash and leaf count;
- complete and unique 600-row matrix;
- exactly six arms for every seed;
- one absolute trace/channel realization and estimator realization per seed
  across both MAC levels;
- finite eligible outputs and explicit divergence accounting;
- causal conservatism, bounded queue/history and physical terminal accounting;
- exact MAC, route, feedback-mode and access-scaling semantics;
- no standalone ACKs in piggyback-only arms and adaptive decisions only in
  adaptive arms;
- fixed-deadline hybrid baseline executes under the legacy causal-broadcast
  contract.

## Claim ceiling and next gate

EXP16 may confirm a feedback-route-by-configured-MAC interaction only in the
matched N=5 Moderate abstract shared-medium cell. It may not establish a
general MAC selector, an IEEE 802.11 result, genuine hardware ALOHA, N=10/N=20
scalability, security robustness, energy savings or real-radio validity.

If the claim is supported, the next preregistered study maps robustness across
load, burst/loss, swarm size and reverse asymmetry/hidden terminals before any
hardware purchase. If it is not supported, no policy retuning is permitted;
the selector claim is narrowed or closed before hardware work.

