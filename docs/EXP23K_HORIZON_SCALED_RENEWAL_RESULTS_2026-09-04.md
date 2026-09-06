# EXP23K — Horizon-scaled renewal development results

Run: `results/exp23k_horizon_scaled_development/2026-09-04_164602`

Status: **`ELCS_W_HORIZON_DEVELOPMENT_FEASIBLE`**.

This is a same-seed development result. It validates the overhead mechanism,
not a fixed long-lease method or a robustness claim.

## Integrity and safety

- All 60 horizon-scaled trajectories completed and pair exactly with their
  EXP23I channel, clock, estimator and occupancy realizations.
- Registry hash `73805627` over 48 leaves; all 16/16 validation gates pass.
- The realized kernel configuration is exactly renewal period `117` frames,
  refresh lead `6`, fence `1`, and lease duration `124` frames.
- Exact replay, variable-payload management accounting, recipient accounting,
  common-PHY busy union and causal-information contracts close.
- Zero false-valid, scheduled-collision, safety and divergence failures;
  terminal certification and cumulative-transaction closure are 60/60.

## Mechanism result

Relative to short-horizon cumulative ELCS-W on the same seeds:

- management airtime decreases from `0.41468587` to `0.05116160` s,
  or `87.6626%`;
- the paired management-airtime CI is
  `[-0.37095680, -0.35632619]` s;
- retry CLAIMs decrease to `13.33` per run;
- RMSE changes from `0.05446432` to `0.05446215` m (`-0.00398%`).

Against periodic TDMA, the horizon-scaled candidate has mean total offered
utilization `0.28123413` versus `0.28672000`, a `1.9133%` advantage. The
paired cost-difference CI is
`[-0.00572516, -0.00524301]`, entirely below the frozen 1% cheaper target.

All three preregistered development criteria therefore pass: management
reduction exceeds 75%, candidate cost is at least 1% below periodic, and RMSE
inflation relative to short-horizon cumulative is below 1%.

## Boundary of the result

The conflict graph is static in EXP23K. A `124`-frame lease therefore remains
valid without confronting a newly appearing interference edge. Treating that
fixed long lease as a final method would exchange communication overhead for
an unmodeled stale-certificate risk. The result only shows that reducing
steady-state renewal frequency has enough quantitative headroom to solve the
EXP23I cost gap.

## Next admissible step

Define a causal topology-coherence contract and a local revocation protocol.
The resulting mathematics must bound the time from a new conflict edge to
transmission suppression and must expose, rather than hide, collisions during
that bounded discovery interval. Only after kernel falsification under edge
addition/removal, missed beacons and asymmetric loss may a fresh closed-loop
study compare the adaptive-horizon candidate with periodic and short-horizon
ELCS-W.

