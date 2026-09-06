# EXP22K invalid targeted-frontier run

Run: `results/exp22k_event_driven_frontier_closure/2026-09-01_194517`

## Verdict

EXP22K completed all 180 trajectories, but only 12/13 integrity gates passed.
The run is invalid for scientific performance decisions. Its dominance output
must not be used for candidate promotion, rejection or robustness entry.

## Root cause

The failing `event_driven_request_discipline` gate combined three clauses. The
two actual protocol clauses passed for every candidate trajectory:

- `GRANT_WITHOUT_DECODED_REQUEST = 0`;
- `STATUS = DISCOVERY_STATUS + REQUEST_STATUS`, with zero residual.

The third clause incorrectly required mission-horizon physical management
attempts to equal full-kernel logical STATUS plus GRANT attempts. The kernel is
simulated for 400 frames to certify its schedule, whereas the continuous
closed-loop replay intentionally retains only frames whose start lies inside
the 12 s mission horizon. The resulting constant residuals were -243 attempts
for N5 and -988 for N10. They reflect two different horizons, not dropped or
unaccounted physical transmissions.

## Frozen repair

EXP22L separates the contracts:

1. request discipline is evaluated on the full kernel using only decoded-
   request and STATUS-partition counters;
2. physical management replay is evaluated inside the mission horizon by
   matching observed attempts, recipient outcomes and charged airtime to the
   continuous schedule's horizon-truncated expected values.

EXP22L uses fresh seeds `16053001:16053030`. The candidate, periodic rates,
PHY, clock, guard, cells and dominance rules remain unchanged. EXP22K
performance outcomes are not consulted.
