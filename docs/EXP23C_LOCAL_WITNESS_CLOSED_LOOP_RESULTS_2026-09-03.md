# EXP23C — ELCS-W local-witness closed-loop integration results

Run: `results/exp23c_local_witness_closed_loop_integration/2026-09-03_161908`

Status: **valid integration evidence; not a performance-promotion result**.

## Frozen execution

- 30 fresh paired seeds (`16059001:16059030`).
- Two cells: N5 6-DOF zero-loss and N10 ring-2 zero-loss.
- Two arms: zero clock and bounded affine clock.
- 120/120 unique trajectories completed in 2 min 29 s.
- All required pre-run suites passed (93 checks total).
- Registry hash: `36192552` over 32 leaves.

## Gate verdict

All 18/18 frozen gates passed, giving `ELCS_W_CLOSED_LOOP_VALID`.

The important closure facts are:

- every conflict edge has a deterministic one-hop witness even though the
  experiment contains 4 hidden conflict edges per N5 realization and 17 per
  N10 realization;
- the maximum witness response load is 8 entries and remains within the
  frozen 96-byte control MTU;
- there are zero false-valid edge-frames, zero scheduled collision frames,
  zero unsupported certificates and zero protocol-invariant violations;
- all nodes certify in frame 1 in the zero-loss integration condition, with
  zero retry CLAIMs and exact nominal attempt/byte bounds;
- every logical DATA opportunity is served, and all receiver-level success,
  erasure and collision outcomes match the pre-drawn witness schedule;
- observed management attempts, recipient outcomes, variable packet bytes
  and airtime equal the schedule exactly; the largest byte-to-airtime
  residual is `5.55e-17` s;
- no control/DATA cross-plane overlap occurs;
- the affine clock equation residual is at most `4.44e-16` s and the minimum
  certified inter-group gap is `0.352` ms;
- no trajectory is unsafe, divergent or terminally uncertified.

## Closed-loop measurements

| Cell | Clock arm | Mean RMSE (m) | Mean true AoI (s) | Total offered util. | Channel busy util. | Management util. | DATA goodput (Hz) |
|---|---|---:|---:|---:|---:|---:|---:|
| N5 6-DOF | zero | 0.02991497 | 0.04060531 | 0.29045333 | 0.29045333 | 0.01269333 | 90.4167 |
| N5 6-DOF | affine | 0.02991362 | 0.04055058 | 0.29045333 | 0.29045333 | 0.01269333 | 90.4167 |
| N10 ring-2 | zero | 0.05087037 | 0.06554535 | 0.30976000 | 0.19200000 | 0.01536000 | 95.8333 |
| N10 ring-2 | affine | 0.05085771 | 0.06536995 | 0.30976000 | 0.20021272 | 0.01536000 | 95.8333 |

The clock arms retain identical logical attempts, offered airtime and
goodput. The higher N10 busy-time utilization under affine clocks is an
expected physical effect: clock skew separates some spatially reused
transmission intervals, increasing their time-union without increasing
offered airtime. It is not extra traffic.

The paired affine-minus-zero RMSE changes are very small and their 95% paired
bootstrap intervals include zero in both cells:

- N5: `-1.34e-6` m, CI `[-1.42e-5, 1.14e-5]`;
- N10: `-1.27e-5` m, CI `[-2.73e-5, 8.56e-7]`.

Consequently EXP23C supports clock-composition validity, not a claim that
clock error improves control.

## Scientific decision

The earlier all-to-all management assumption has now been removed from the
candidate integration: management reach is exactly the one-hop neighbor
graph, while hidden conflict edges are certified through local witnesses.
The common-PHY closed-loop implementation is valid enough to proceed to a
new frozen frontier test.

The previous EXP22M frontier result does not transfer automatically because
ELCS-W changes control payload sizes, renewal airtime and DATA timing. The
next experiment must therefore recompute the periodic cost-match and exact
1%-lower-cost references from the EXP23C parent cost, then test them on
disjoint fresh seeds. Method promotion remains forbidden until that test and
subsequent loss/traffic robustness gates pass.
