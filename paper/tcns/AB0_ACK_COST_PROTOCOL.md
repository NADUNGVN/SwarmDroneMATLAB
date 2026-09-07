# AB0 ACK-cost-adjusted O1 protocol

**Status:** frozen before adjusted-cost results are generated

**Input:** immutable O1 Stage-A run `2026-09-07_160426` and Stage-B run
`2026-09-07_162102`, collectively tagged
`centralized_state_oracle_frozen`.

## Purpose

Quantify how much of O1's apparent communication advantage comes from free
receiver truth. This is an offline cost sensitivity calculation. It does not
rerun or alter any plant, network, action, loss, delay or formation trajectory.

## Frozen accounting models

All models retain the Gate-6 normalization, evaluation window, periodic
frontier and performance metric.

- **C0:** recorded O1 cost,
  (C_0=(N_{DATA}+0.25\,0)/(T_en_{ch})).
- **C1:** one hypothetical ACK transmission per O1 action whose DATA payload
  is actually accepted by the receiver. The ACK is charged at the delivery
  tick, not the original DATA-generation tick:
  (C_1=(N_{DATA}+0.25N_{accepted})/(T_en_{ch})).
- **C2:** exact queued causal-protocol ACK-generation semantics from
  `deliverDataWithAck`: at a delivery tick, emit at most one cumulative ACK
  per directed payload link if and only if its receiver `acceptedGenTime`
  advances. Thus (N_{C2}) is the count of unique
  `(delivery tick, receiver, sender, payload class)` tuples among accepted O1
  actions. ACK loss/delay does not change ACK transmissions charged at
  generation. There are no node blackouts in S2--S6; S5 link failure is
  already reflected in DATA acceptance.

Periodic baselines remain ACK-free because their schedule requires no
receiver feedback. Only O1 is sensitivity-charged. DATA and ACK events are
counted in the predeclared 8--30 s evaluation interval. Delivery tick is the
first sampled time not earlier than the logged continuous arrival time.

## Frozen analysis

For each C0/C1/C2 and S2--S6:

1. recompute five-seed mean operating points;
2. weak lower-left Pareto filter the complete 14-point O1 and 11-point
   periodic families;
3. match over the complete shared budget and performance domains on the same
   101-point grid without extrapolation;
4. report mean and median matched differences, domain fractions favoring O1,
   crossings, maximum advantage/disadvantage, meaningful contiguous runs and
   the unchanged `CONVINCING`, `MARGINAL_OR_NARROW`, or `NO_HEADROOM` class.

The meaningful thresholds remain 2% RMSE, 5% cost, 21 points for a convincing
contiguous interval and 11 points for a narrow interval. Support count is the
number of convincing scenarios among S2--S6.

## Stop rule

- If C2 convincing support is at least 2 of 5, proceed to exact belief
  definition and passive calibration.
- If C2 convincing support is below 2 of 5, classify
  `STOP_ACK_BELIEF_IMPLEMENTATION` and return to Research Lead without belief
  scheduler implementation.

## Technical validity

The audit is valid only if:

- all 625 saved O1/periodic rows are recovered with no trajectory rerun;
- all 350 O1 run/action groups match their recorded send counts;
- C0 exactly reproduces the frozen scenario classifications and matched means
  to numerical tolerance;
- (C_0\le C_2\le C_1) for every O1 run;
- C2 tuple counts implement at-most-one ACK per link/tick;
- no held-out seed or new policy behavior is used.
