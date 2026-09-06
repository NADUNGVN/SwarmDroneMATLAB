# EXP18A3 — Freshness-headroom marginal ACK development

## Motivation

EXP18A2 correctly abstains where estimated service capacity cannot meet the
semantic update requirement, but its marginal benefit still credits an ACK for
possibly suppressing a DATA frame even when the confirmed sample has already
consumed most of its AoI budget.

For entry `ij`, EXP18A3 adds

```text
h_ij(t) = max(0, 1 - [t-g_ij]/AoI_threshold)
```

and changes only the benefit term:

```text
B_i(t) = sum_j s_ji tau_D r_ij(t) h_ij(t).
```

There is no fitted coefficient. Generation time is carried in the accepted
DATA/ACK entry, and `AoI_threshold` is the already-declared semantic threshold.
Capacity abstention, frame-aware access and every comparator remain unchanged.

## Development-only rerun

- Same 20 EXP18 development seeds; never usable for confirmation.
- Same 10 contexts and 2 access types.
- One revised arm, 400 trajectories.
- Exact trace/channel/estimator match to canonical EXP18A references.

## Stricter decision gates

All EXP18A2 integrity, capacity-coverage, abstention, failure and collision-
burden gates remain. In addition:

1. feasible CSMA core cells must emit zero standalone ACKs and exactly alias
   frame-aware piggyback on registered physical/control outcomes;
2. the feasible N5 Moderate ALOHA core cell must retain standalone ACK activity;
3. in that ALOHA cell, the candidate must not be jointly worse than both fixed
   routes and must have zero observed failure increase;
4. no more than one feasible core cell may be jointly worse than both fixed
   routes overall.

Passing permits an EXP18B preregistration only. It is not confirmation.

