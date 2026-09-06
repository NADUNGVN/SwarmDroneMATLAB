# EXP22L: fresh event-driven frontier gate-repair rerun

**Frozen before EXP22L randomized outcomes:** 2026-09-01  
**Parent:** invalid EXP22K (`2026-09-01_194517`)  
**Invalidity cause:** comparison of full-kernel logical attempts with
mission-horizon physical attempts  
**Tuning, robustness, promotion and submission claims:** prohibited

EXP22L repeats the frozen EXP22K candidate and four analytically derived
periodic rates without modification. It uses fresh seeds
`16053001:16053030`, for 180 trajectories.

The corrected integrity separation is:

- full-kernel protocol: zero GRANT without a decoded request; exact discovery
  plus request STATUS partition; analytical control-attempt bound; acquisition
  by frame `N`;
- mission-horizon replay: physical management attempts equal the continuous
  schedule's horizon-truncated expected attempts; recipient outcomes match;
  charged management airtime equals attempts times the 32-byte control airtime.

Decision rules remain exactly those frozen for EXP22K: the 2%-below-cost
periodic arm rejects the candidate if it has at most 1% worse RMSE and at least
1% lower fully charged offered utilization in either cell. Paired bootstrap
confidence intervals use 10,000 resamples. Only a valid non-rejected result may
open robustness continuation.
