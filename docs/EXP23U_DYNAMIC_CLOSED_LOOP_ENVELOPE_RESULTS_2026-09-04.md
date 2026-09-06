# EXP23U — Dynamic common-PHY operating-envelope results

Run: `results/exp23u_dynamic_closed_loop_envelope/2026-09-04_203719`

Status: **DYNAMIC_CLOSED_LOOP_OPERATING_ENVELOPE_VALID (21/21 gates)**.

All 360/360 trajectories completed on 60 fresh paired seeds. All 240 dynamic
events occurred after positive scheduled state, emitted one exact 24-byte
REVOKE on the common PHY and suppressed the sender in the event frame. Every
physical reuse respected the old fence. Early delivered/REVOKE-blackout rows
reacquired 120/120; late rows and permanent RESPONSE-blackout rows remained
suppressed as preregistered. There were zero false-valid, scheduled-collision,
safety or divergence failures, and replay/clock/recipient/airtime accounting
closed.

Relative to no-event static coherence:

- early revoke: RMSE +2.32% (delta CI `[0.001041, 0.001584]` m), cost -3.97%
  (delta CI `[-0.011239, -0.010592]`);
- late revoke: RMSE +8.26% (delta CI `[0.004046, 0.005203]` m), cost -3.98%;
- early permanent RESPONSE blackout: RMSE +14.98% (delta CI
  `[0.007443, 0.009304]` m), cost +7.07% (delta CI
  `[0.019073, 0.019827]`).

The RESPONSE-blackout arm is epsilon-dominated by periodic. Delivered versus
lost REVOKE has identical local suppression/reuse history, confirming that
safety does not depend on REVOKE delivery.

The result exposes a design boundary: waiting for the entire old tuple fence
is safe but causes long communication outages, while permanent cumulative
retry can erase the static cost advantage. This motivates witness-confirmed
early reactivation and bounded retry/backoff; online graph migration is still
unvalidated.
