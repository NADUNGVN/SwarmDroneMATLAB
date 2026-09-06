# EXP18A4 — Capacity-gated fixed-route selector development

## Policy

EXP18A4 removes the failed marginal-value heuristic. It uses the unchanged
EXP18A2 capacity certificate followed by a closed route map:

```text
if service certificate fails: piggyback-only and abstain from route claim;
else if configured access is CSMA: piggyback-only;
else if configured access is ALOHA: legacy adaptive standalone feedback.
```

The selector is not advertised as universally optimal. Its intended advance
over the rejected EXP17 MAC-only rule is that it refuses to apply an ACK route
where the estimated per-node update capacity cannot meet the existing AoI
requirement.

## Development contract

- Same 20 development seeds, 10 contexts, 2 access types: 400 rows.
- Same frame-aware access geometry.
- Exact trace/channel/estimator match to canonical EXP18A.
- No new threshold, fitted parameter or outcome-dependent route.

Physical/control aliasing is mandatory on every seed:

- feasible CSMA -> canonical frame-piggyback;
- feasible ALOHA -> canonical frame-adaptive;
- certificate-infeasible -> canonical frame-piggyback.

The alias family includes RMSE, separation/failure, AoI, DATA/ACK attempts,
recipient success, collisions, queues, airtime, offered utilization, goodput
and control effort. Any nonzero difference rejects the implementation.

Development promotion additionally retains capacity coverage, infeasible zero
standalone ACK, N10 ALOHA absolute-collision repair and the explicit reverse
calibration mismatch. Passing permits preregistration only.

