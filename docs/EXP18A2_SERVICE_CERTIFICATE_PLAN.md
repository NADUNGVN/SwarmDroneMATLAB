# EXP18A2 — Service-certificate abstention development

## Amendment status

EXP18A2 is a new development version created only after EXP18A v1 was frozen
with verdict `REJECT_OR_REVISE_CANDIDATE`. It does not rescore or overwrite the
two failed v1 gates. It may reuse the 20 EXP18A development seeds, but those
seeds remain permanently ineligible for confirmation.

Only the revised context-aware arm is rerun. The unchanged legacy-selector,
frame-piggyback and frame-adaptive rows are read from canonical run
`results/exp18a_context_aware_development/2026-08-31_121134`. Every v2 row must
match the reference absolute trace/channel/estimator hashes for the same
seed/context/MAC.

## Why v1 was amended

The v1 busy-slack proxy produced zero feasibility blocks even in cells with
common closed-loop failure. Busy occupancy is not a successful-update-rate
certificate. The amendment adds an analytical screen before ACK marginal
value; it does not change the semantic DATA trigger.

## Capacity screen

Let `p` be the frame-aware access probability, `L` DATA slots, `N` nodes,
`b_ext` declared/calibrated background occupancy and `s_D` the minimum
stationary DATA-success estimate over active topology links.

For ALOHA, the per-node successful-update-rate approximation is

```text
lambda_A = [p / slot] (1-p)^[N(2L-1)-1] (1-b_ext)^L s_D.
```

For p-persistent CSMA, use the renewal approximation

```text
P_idle = (1-p)^N,
E[C] = P_idle + (1-P_idle)L,
lambda_C = [p(1-p)^(N-1) / (E[C] slot)] (1-b_ext)^L s_D.
```

The required semantic update rate is not fitted:

```text
lambda_req = 1 / AoI_threshold.
```

The route layer is eligible only if `lambda/lambda_req >= 1`. Otherwise it
abstains and sends no standalone ACK. Abstention says that neither ACK route
is certified at that operating point; it is not a safety guarantee or a claim
that piggyback makes the plant safe.

## Matrix

- Same development seeds `16024001:16024020`.
- Same 10 network contexts and 2 access types.
- One v2 context-aware arm: 400 simulations.
- Same frame-aware access geometry as EXP18A.
- Reverse-asymmetric boundary retains nominal ACK calibration mismatch.

## Pre-performance development gates

1. 400 complete unique rows, exact reference trace hashes, causal/integrity and
   physical accounting pass.
2. The certificate yields at least five feasible core context--MAC cells and
   includes both N values and both access types; otherwise route coverage is too
   narrow for a future holdout.
3. In feasible core cells, candidate failure count does not exceed either
   frame-aware fixed route.
4. In feasible core cells, the candidate is not jointly worse than both fixed
   routes on RMSE and offered utilization in more than two cells.
5. In certificate-infeasible cells, standalone ACK count is exactly zero.
6. At least one feasible cell contains admitted standalone ACKs and at least
   one contains value blocks, showing that the second layer remains active.
7. In all four N10 ALOHA core cells, absolute collision frames per trajectory
   decrease by at least 10% relative to the legacy selector. This replaces no
   v1 result: v1's collision-*rate* gate remains failed. Absolute collision
   burden is registered here because rate changes denominator when access
   attempts fall and background collisions impose a floor.
8. The reverse calibration mismatch remains explicit.

Passing these development gates permits writing an EXP18B preregistration; it
does not itself support superiority, safety, hardware or named-MAC claims.

