# EXP21D-C: D-STR affine-clock composition results

**Accepted run:** `results/exp21d_clock_composition/2026-09-01_114737`  
**Matrix:** 30 fresh seeds x 2 cells x 3 arms = 180 trajectories  
**Integrity:** 17/17 gates; `DSTR_AFFINE_CLOCK_COMPOSITION_VALID`

## 1. What was closed

EXP21D-C composes native D-STR with a single-epoch affine local-clock model over
the complete 12-second mission. It assumes no periodic synchronization event.
For the frozen bounds `Theta = 0.25 ms` and `Delta = 40 ppm`, the exact
finite-horizon certificate gives a common lead of `0.730029 ms` and sufficient
guard of `1.460058 ms`.

The two mission-guard arms share the exact native kernel schedule and the same
outcome-blind nominal cutoff. Consequently, they contain identical logical
DATA/control opportunities; only the mapping from nominal boundaries to
physical start times differs.

All 180 trajectories satisfy the affine clock equation with maximum residual
`1.78e-15 s`. The smallest inter-group physical gap is `0.295 ms`; maximum
within-group skew remains below the `3.072 ms` packet airtime. There are zero
skipped opportunities, outcome mismatches, DATA/control overlaps, protocol
violations, unsafe trajectories, unresolved kernels or invalid kernels.

## 2. Clock effect under the sufficient guard

Relative to mission-guard zero clock, the affine-clock arm has exactly the same
offered utilization and DATA goodput in both cells. Its RMSE difference is
`+0.0073%` at N5 and `+0.0318%` at N10; both bootstrap intervals cross zero.
True AoI changes by `+0.0672%` at N5 (interval touches zero) and `+0.1109%` at
N10. The latter interval excludes zero but its absolute effect is only
`47.2 microseconds`.

Clock skew expands the busy-time union within simultaneous logical groups:
channel utilization rises `0.216%` relative at N5 and `3.002%` at N10. This is
not extra offered airtime and does not change service outcomes. The distinction
between summed attempt airtime and busy-union occupancy is therefore retained.

The evidence supports the bounded conclusion that, once the sufficient guard
is installed, local-clock offset/drift is not the active closed-loop failure
mechanism in these zero-loss D-STR cells.

## 3. Conservative guard cost

The mission-safe guard is intentionally conservative because it covers a full
12-second epoch without assuming resynchronization. Relative to the previously
used `0.540022 ms` short guard, the zero-clock mission guard reduces offered
utilization by approximately 20.3% at N5 and 20.1% at N10, but also reduces
DATA goodput by 20.8% and increases RMSE by 8.81% and 10.54%. True AoI rises
18.11% and 15.07%.

This is a capacity cost of the stated clock contract, not evidence that the
short guard was valid over 12 seconds. A future candidate may shorten the
reset horizon only by explicitly charging and validating its synchronization
mechanism.

## 4. Research decision

Stage C is now complete. The remaining reproducible gap is not timing:

1. implicit DATA reception records are fragile schedule evidence under modest
   beacon erasure; and
2. restricted management visibility permits locally Resolved nodes to carry
   incompatible frame lengths, eliminating an executable shared schedule.

The next stage may design a candidate, but only against these mechanisms. Its
minimum ingredients are explicit bounded schedule epoch/version state,
receiver-verifiable evidence repair, and a safe non-scheduled fallback whenever
a common schedule certificate is absent or expires. Fast rejoin and larger
guard tuning are not primary contributions.

EXP21D-C opens candidate design only. It does not authorize method promotion,
holdout testing, superiority claims or manuscript construction.
