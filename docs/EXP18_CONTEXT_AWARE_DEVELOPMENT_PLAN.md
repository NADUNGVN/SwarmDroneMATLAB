# EXP18 — Feasibility-first context-aware feedback development

## Status and evidence boundary

EXP18 is a new method cycle after the frozen EXP17 continuation failure. EXP17
may be used as development evidence, but no EXP18 confirmatory seed is opened
until the policy, comparator set, estimands and continuation rule are frozen.
Nothing in EXP18 changes the validity or interpretation of EXP14--EXP17.

The immediate stage is **EXP18A development**, not a holdout. Its purpose is to
reject, simplify or freeze one candidate. Iterative changes are permitted only
inside the declared development seed block and must be logged as new candidate
versions. A later EXP18B must use disjoint seeds.

## Failure diagnosed by EXP17

The MAC-only selector fails for two separable reasons.

1. Some cells are service-infeasible before feedback routing is considered.
   N10 ALOHA has mean offered utilization around 1.70--1.76 and collision rate
   around 0.95. Both routes fail there.
2. In feasible cells, an ACK can suppress a redundant DATA update or a useful
   refresh. Configured MAC type does not determine which effect dominates.

The new design is therefore hierarchical: access feasibility first, causal
marginal ACK value second.

## Causal information set

At node `i` and decision time `t`, the policy may read only:

- configured swarm size and frame/slot parameters;
- configured access semantics;
- local carrier/background-busy EWMA;
- the local finite queue and pending cumulative ACK entries;
- state samples and generation times actually accepted by node `i`;
- a declared/calibrated stationary ACK-delivery estimate.

It may not read realized loss state, collision truth, future access draws,
receiver truth unavailable to the node, formation outcome, or comparator
behavior. A calibrated delivery estimate is an input, not an oracle; later
development must include an intentionally misspecified-calibration boundary.

## Layer 1: frame-aware access feasibility

Let `L_D` be the number of MAC slots occupied by a bare DATA frame and `N` the
number of contending nodes. The access probability is

```text
p_CSMA  = min(p_configured, 1/N),
p_ALOHA = min(p_configured, 1/[N(2 L_D - 1)]).
```

For fully sensed p-persistent CSMA, `1/N` maximizes the probability of exactly
one attempt among `N` symmetric contenders in an idle slot. For multi-slot
ALOHA, `2 L_D - 1` is the vulnerable start interval of a DATA frame. The ALOHA
rule is the `G=1` operating point of the standard independent-start
approximation. It is an analytical design point, not a claim of exact
optimality for finite queues, retries or burst loss.

This layer changes service opportunity, not DATA-generation semantics. It
therefore avoids repeating the harmful EXP14 load guard, which dropped
requested semantic updates.

## Layer 2: feasibility-and-value standalone ACK rule

For `m` pending cumulative entries, define physical frame times

```text
tau_D    = slots(DATA bytes) * slot time,
tau_A(m) = slots(ACK base + m entries) * slot time.
```

The reserved forced-refresh load proxy is

```text
rho_D = N tau_D / T_max,
sigma_i(t) = 1 - busy_i(t) - rho_D.
```

`sigma_i <= 0` is an ACK-service infeasibility declaration. It suppresses the
standalone ACK but does not claim that the plant is safe.

For an ACK entry confirming sender `j` at generation time `g_ij`, node `i`
forms the motion envelope

```text
a_ij(t) = t - g_ij,
d_ij(t) = ||v_ij(g_ij)|| a_ij + 0.5 a_max a_ij^2,
r_ij(t) = max(0, 1 - d_ij/epsilon_p).
```

`r_ij` is a conservative redundancy score: once possible semantic drift
consumes the existing position-trigger budget, the ACK receives no predicted
DATA-suppression credit. The predicted airtime benefit and congestion-adjusted
cost are

```text
B_i(t) = sum_j s_ji tau_D r_ij(t),
C_i(t) = tau_A(m) / sigma_i(t),
V_i(t) = B_i(t) - C_i(t),
```

where `s_ji` is the declared/calibrated stationary success estimate for an ACK
from `i` to `j`. A standalone ACK is eligible only when `sigma_i>0` and
`V_i>=0`; otherwise it waits for a later recheck or piggyback. The rule adds no
outcome-fitted busy threshold. Its numerical quantities are inherited from
frame geometry, existing semantic thresholds, bounded acceleration and the
calibration input.

This is a decision proxy, not a theorem that an admitted ACK improves control.
The EXP14G negative focal effects remain valid and motivate the semantic-drift
discount.

## EXP18A development matrix

Development seeds: `16024001:16024020`. These seeds can never be used for the
later confirmatory family.

Contexts reuse the eight EXP17 core definitions and the reverse-asymmetric and
hidden-terminal boundaries under both configured CSMA and ALOHA access. Four
arms isolate the two layers within each access type:

1. `legacy-selector`: EXP17 MAC-only route with `1/N` access;
2. `frame-piggyback`: frame-aware access, piggyback only;
3. `frame-adaptive`: frame-aware access, legacy adaptive ACK;
4. `context-aware`: frame-aware access plus the new feasibility/value rule.

The matrix has `20 x 10 x 2 x 4 = 1600` simulations with one absolute trace
per seed/context shared across both MAC types and all arms. Development
outcomes are RMSE, offered airtime, true AoI, failure count, collisions,
queueing, standalone ACK count, access probability and feasibility/value block
counts.

## Development decision rules

The candidate is not automatically promoted. Before an EXP18B preregistration,
all of the following must hold descriptively in EXP18A:

1. no protocol/integrity violation and no failure-count increase relative to
   both frame-aware fixed-route comparators in any context;
2. in every N10 ALOHA core context, offered utilization and collision rate
   decrease by at least 10% from the legacy selector;
3. the context-aware arm is not jointly worse than both frame-aware fixed
   routes on RMSE and offered utilization in more than two core context--MAC
   cells;
4. value blocks activate in at least one feasible cell; feasibility blocks
   must activate whenever the observed residual-slack proxy becomes
   nonpositive, but zero such blocks is allowed if frame-aware access prevents
   that state;
5. results under reverse-calibration mismatch are reported, not tuned away.

If these conditions fail, the candidate is rejected or redesigned under a new
development version. If they pass, EXP18B will freeze fresh seeds, a comparator
family and multiplicity correction before running.

## Claims prohibited during EXP18A

- superiority, robustness or safety;
- an optimal access probability;
- accurate online identification of channel state;
- named IEEE MAC behavior;
- hardware readiness.
