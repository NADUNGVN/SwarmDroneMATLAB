# EXP23AR routed common-PHY plant smoke diagnosis

Date: 2026-09-06  
Scope: smoke seed `16096301`; development seeds `16096401:16096420` remain
unopened.

## Status

`ROUTED_PLANT_COMPOSITION_REPAIR_REQUIRED`

The exact EXP23AQ routed transaction was embedded in the 10.5 s closed-loop
mission and executed on the same PHY as formation DATA.  The smoke test is
valuable but does **not** pass the frozen EXP23AR safety gate, so no full
development matrix was run and
`closedLoopManagementRelayingValidated=false` remains correct.

## Contracts that held

- EXP23AR registry and routed-mission embedding tests pass.
- Normal routed transaction completes and reactivates every affected node.
- All routed arms preserve the pre-request decision state and physical
  schedule exactly.
- Runtime attempts, integer management bytes and derived airtime equal the
  routed kernel/schedule accounting exactly.
- DATA receiver outcomes replay exactly; no scheduled or observed collision
  occurs.
- Mission embedding preserves the EXP23AQ transaction DATA tuples and every
  management attempt.
- The RESPONSE-blackout negative control remains visible.

## Falsified composition assumption

The existing protected service grants one emergency DATA opportunity per
transaction frame.  That was sufficient for the earlier direct-management
transaction, but a routed frame can be much longer because it serializes the
multi-hop management flood on the same PHY.  Under permanent RESPONSE loss,
the maximum routed frame and emergency inter-opportunity interval are both
approximately `0.9523 s`.  The protected arm then violates the radial
certificate (`maximum ratio = 1.3457 > 1`) even though it remains collision
free and has no numerical safe-failure flag.

The paired arm without emergency DATA is worse (`maximum radial ratio =
6.5074`, mission RMSE `0.38026 m`).  Emergency DATA still has causal value, but
frame-count protection is not a valid service guarantee after multi-hop
routing.

| Arm | Motion | Reactivated | Max emergency gap (s) | Radial ratio | Mission RMSE (m) |
|---|---:|---:|---:|---:|---:|
| periodic IID-20 | n/a | n/a | n/a | n/a | 0.11269 |
| routed normal + protected DATA | 1 | 1 | 0.08959 | 0.74174 | 0.13886 |
| routed RESPONSE blackout + protected DATA | 1 | 0 | 0.95229 | 1.3457 | 0.23025 |
| routed RESPONSE blackout, no protected DATA | 1 | 0 | n/a | 6.5074 | 0.38026 |
| routed PREPARE blackout + protected DATA | 0 | 0 | 0.16056 | 0.73885 | 0.10419 |
| routed COMMIT blackout + protected DATA | 1 | 0 | 1.0130 | 0.76199 | 0.14437 |

## Scientific consequence

EXP23AQ proves the routed management state machine, but that result cannot be
lifted automatically to closed-loop validity.  A protected service contract
must be stated in physical time (a maximum inter-service interval or minimum
service curve), not in transaction-frame count.  The next design step is a
deadline-bounded DATA/control interleaver that preserves routed packet order,
outcomes, attempts, bytes and fail-silent state semantics while preventing a
long routed control frame from starving protected formation DATA.

This repair must be registered as a new development experiment.  The failed
EXP23AR gate must not be relaxed or relabeled.
