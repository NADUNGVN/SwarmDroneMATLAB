# Gate-5 development frontier protocol

**Classification:** development-only stationary frontier; not final held-out
evidence and not an operating-point selection exercise.

**Scientific purpose:** replace comparisons against Periodic10 alone with a
complete, automatically processed communication/performance sweep before
constructing nonstationary regimes in Gate 6.

## Frozen design before execution

- Plant/controller: exact double-integrator subsystem and fixed N=5 graph
  used by Gates 1--4.
- Network: frozen EXP10 Stressed stationary scenario.
- Horizon/evaluation: 30 s / metrics after 8 s.
- Paired development seeds: 27020001--27020005.
- Communication cost: `(DATA + 0.25 ACK) / configured channel / second`.
- Formation performance: repository formation RMSE after 8 s.
- Periodic sweep in sample periods:
  `1, 2, 3, 4, 5, 8, 10, 15, 20, 25, 40`, corresponding to
  `0.02--0.80 s` at the implemented 50 Hz control clock.
- Control-aware sweep:
  \(\epsilon_d=\{0.05,0.075,0.10,0.15,0.20,0.30,0.40,0.60,0.80,
  1.20,1.60\}\) m.
- Conditional retry remains 0.10 s for every control-aware arm.
- Frozen Causal-v3 is retained as a historical reference but cannot define
  either competing frontier because it is a single operating point.

The grids span rather than target P10. No grid value will be removed because
it is dominated, saturated, divergent or unfavorable; Pareto filtering occurs
only in derived tables and raw rows remain intact.

## Automatic analysis

For each policy family, aggregate mean cost and mean RMSE over the five paired
seeds. Construct the conventional lower-left Pareto frontier using weak
dominance, without importing the paper's separate 1% reporting margin.

Let control-aware be family A and periodic be family B. On a fixed 101-point
grid over the complete common observed cost interval, linearly interpolate
both frontier errors and report `error_A - error_B`. On a second 101-point grid
over the complete common observed error interval, invert both frontiers and
report `cost_A - cost_B`. Extrapolation is forbidden. Negative differences
favor control-aware.

This first Gate-5 analysis uses frontiers of seed-aggregated means. It is not a
replacement for the paired bootstrap/effect-size analysis required by Gate 9.

## Gate criteria

The experiment infrastructure passes only if:

1. all scheduled runs produce finite machine-readable rows;
2. every control-aware run has zero causal/protocol invariant violations;
3. both families contain at least three non-dominated operating points;
4. the frontiers have nonzero overlap in both cost and formation performance;
5. both 101-point matching tables are produced without extrapolation;
6. all methods paired by seed report the same forward trace hash;
7. the complete raw grid, dominated points, saturation diagnostics and any
   negative comparison remain saved.

No performance advantage is required for this development gate to pass. If
periodic dominates in this stationary scenario, that is evidence supporting
the stated nonstationary-value hypothesis to be tested—not assumed—in Gate 6.

