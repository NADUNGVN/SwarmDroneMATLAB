# EXP22E-CL: queue-compatible ELCS-F closed-loop results

**Run:** `results/exp22e_elcs_closed_loop_repair_validation/2026-09-01_175319`  
**Verdict:** `ELCS_F_FALLBACK_REPAIR_CLOSED_LOOP_VALID`  
**Matrix:** 120/120 rows  
**Gates:** 17/17

## Integrity result

The repaired protocol eliminates the exact EXP22D failure on disjoint seeds:

- zero skipped DATA opportunities;
- exact scheduled/fallback success, erasure and collision replay;
- exact event/kernel collision witnesses;
- zero false-valid edge-frames, owner-lock violations, scheduled-region
  collision witnesses, cross-plane overlaps, future-random reads,
  receiver-truth reads, protocol violations, unsafe rows and divergences; and
- exact STATUS/GRANT recipient partitions and 32-byte airtime charge.

The maximum affine-clock equation residual is `4.44e-16 s`; the minimum
inter-group gap is `0.244 ms`. Zero- and affine-clock arms share identical
kernel, channel, estimator and logical-opportunity hashes per seed/cell.

## Descriptive operating point

These values characterize integration and are not a superiority claim.

| Cell | Clock | RMSE (m) | Mean true AoI (s) | Offered util. | Busy-union util. | Goodput (Hz) | Management util. |
|---|---:|---:|---:|---:|---:|---:|---:|
| N5 6-DOF | zero | 0.030147 | 0.040945 | 0.350925 | 0.350720 | 87.797 | 0.081067 |
| N5 6-DOF | affine | 0.030112 | 0.040957 | 0.350925 | 0.350732 | 87.797 | 0.081067 |
| N10 ring2 | zero | 0.050867 | 0.065545 | 0.376883 | 0.264550 | 92.772 | 0.091819 |
| N10 ring2 | affine | 0.050866 | 0.065426 | 0.376883 | 0.272223 | 92.772 | 0.091819 |

Affine clock changes offered load and goodput by exactly zero. Its paired RMSE
change is `-0.116%` at N5 and `-0.0012%` at N10. At N10, skew increases the
busy union by about `2.90%` without changing logical service outcomes.

There remain 40 N5 and 33 N10 early fallback collision frames per arm over 30
rows. They are genuine pre-certification contention outcomes, not replay
mismatches. Mean first full certification is frame 5 at N5 and frame 10 at
N10.

## Decision

The queue-compatible repair is valid for robustness and direct-baseline
development. Promotion remains prohibited. The next gate must establish
whether this operating point is non-dominated by a full-mission guarded
periodic static-TDMA frontier and native D-STR under exactly paired physical
conditions. If a simple periodic point dominates ELCS-F, further robustness
testing cannot rescue the current efficiency claim; the allocation/control
overhead must be redesigned first.
