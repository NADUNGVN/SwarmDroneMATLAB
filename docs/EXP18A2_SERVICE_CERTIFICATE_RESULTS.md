# EXP18A2 service-certificate development results

## Canonical run

- Run: `2026-08-31_123541`
- Matrix: 400/400 revised-candidate trajectories
- Reference: canonical EXP18A run `2026-08-31_121134`
- Runtime: 3 min 27 s on 16 process workers
- Integrity: 14/14 gates, zero protocol violations
- Development decision: `ELIGIBLE_TO_WRITE_HOLDOUT_PREREGISTRATION` (7/7)

Every row matches the canonical EXP18A absolute trace, channel-state and
estimator hashes for its seed/context/MAC. Confirmatory seeds remain unopened.

## Capacity map

The certificate retains five feasible core context--MAC cells:

| Context | Access | Service ratio | Failures | Mean standalone ACKs |
|---|---:|---:|---:|---:|
| N5 Moderate bg0 | CSMA | 2.942 | 0/20 | 60.35 |
| N5 Moderate bg0 | ALOHA | 1.156 | 0/20 | 156.10 |
| N5 Stressed bg0 | CSMA | 2.313 | 0/20 | 36.50 |
| N10 Moderate bg0 | CSMA | 1.421 | 0/20 | 52.20 |
| N10 Stressed bg0 | CSMA | 1.117 | 0/20 | 3.45 |

All background-0.30 core cells, all N10 ALOHA cells, and N5 Stressed ALOHA
are certificate-infeasible. Together with boundaries there are 11 infeasible
context--MAC cells; all emit exactly zero standalone ACKs. Abstention does not
mean those trajectories are safe: several still fail because neither feedback
route can repair insufficient DATA service.

## Access-layer result retained

Against the legacy `1/N` ALOHA selector, the frame-aware candidate reduces
absolute collision frames in the four N10 ALOHA core cells by 69.0--85.7%.
This satisfies the newly registered absolute-burden gate. EXP18A v1's separate
10% collision-*rate* gate remains failed and is not overwritten.

## Why holdout is still deferred

The preregistration eligibility gate is necessary, not automatic. In feasible
CSMA cells the candidate still emits standalone ACKs and is generally more
expensive than frame-aware piggyback; the N5 Stressed bg0 CSMA cell remains
jointly worse than both fixed routes. In feasible N5 Moderate ALOHA the
candidate behaves near legacy adaptive but is worse than piggyback in raw RMSE
and offered load.

Therefore the capacity layer is retained, but the marginal-value layer is not
yet frozen for confirmation. EXP18A3 adds a parameter-free freshness-headroom
factor based on the existing AoI threshold. This is a new development version,
not a rescore of EXP18A2.

