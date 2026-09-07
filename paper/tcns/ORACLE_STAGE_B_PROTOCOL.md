# Centralized online-oracle Stage-B protocol

**Status:** frozen before Stage-B result generation

**Authorization:** Stage A returned `O1_STRONG_HEADROOM` with technical PASS
in run `2026-09-07_160426`; S2 and S6 were both `CONVINCING` under the
preregistered complete-domain rule.

## Unchanged scientific contract

Stage B expands the same `centralized_state_oracle`; it does not tune or
redesign it. The information set, current-truth residual, Gate-3 equation,
(H=25), strict rule (q_{ij}>\lambda), resource-price grid, periodic periods,
seeds, cost definition, evaluation windows, Pareto filtering, 101-point
matching and meaningful/contiguous-headroom rules remain exactly those in
`ORACLE_FRONTIER_PROTOCOL.md`.

Frozen matrix:

- scenarios: S3 Gilbert-Elliott, S4 time-varying congestion and S5 topology
  perturbation;
- development seeds: 27020001--27020005;
- periodic periods: `1, 2, 3, 4, 5, 8, 10, 15, 20, 25, 40` samples;
- O1 thresholds:
  `0, 1e-6, 3e-6, 1e-5, 3e-5, 1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 3e-2, 1e-1, 3e-1, 1`;
- 375 scheduled runs in total.

Periodic rows are again required to reproduce the archived Gate-6 artifact
from git `9d5d8c0`; no periodic arm is removed or refitted.

## Causal channel interpretation in the added regimes

The equation uses only the channel distribution currently declared at time
(k):

- S3 uses the frozen stationary marginal success probability (1-0.41). O1
  does not read the latent Gilbert-Elliott state or the current/future drop
  outcome.
- S4 uses the current segment's declared loss and nominal delay in (p_s) and
  the link-response kernel. Realized jitter is hidden at scheduling time and
  is used only by the channel and passive arrival log. A link is reconsidered
  no earlier than the current nominal-delay interval after its attempt; if
  jitter delays delivery further, a later attempt is allowed based on still
  stale current receiver truth.
- S5 does not read the seeded temporary link-down mask when ranking. Attempts
  on a failed link are consumed by the unchanged delivery layer and logged as
  failures. This avoids adding channel-state privilege not present in Stage A.

Kernel construction at a regime transition is lazy and uses only the current
nominal delay. This changes neither the value equation nor the sweep variable.
Exact realized arrival times are inspected only after an action has already
been selected, solely to resolve passive receiver-before/after diagnostics.

## Stage-B reporting and final O1 decision

Each scenario is classified `CONVINCING`, `MARGINAL_OR_NARROW`, or
`NO_HEADROOM` by the exact Stage-A rules. Report all matched statistics,
crossings, contiguous runs, event allocation, accepted useful deliveries,
failed/no-information attempts and per-link frequency.

The final O1 support count is the number of convincing scenarios among
S2--S6. The frozen project criterion is met when at least 2 of 5 are
convincing. Stage-B results cannot revoke or inflate the already recorded S2
and S6 data; they determine breadth of support.

Because Stage A strongly passes, O2 is not required by the decision protocol.
If Stage B is technically valid and the final support count remains at least
2, the research recommendation is `GO_ACK_BELIEF_POLICY`. This authorizes only
the later distributed approximation study after Research Lead review; it does
not claim that O1 itself is implementable.

Held-out seeds, Gates 7--10, scalability and distributed policy code remain
closed during Stage B.
