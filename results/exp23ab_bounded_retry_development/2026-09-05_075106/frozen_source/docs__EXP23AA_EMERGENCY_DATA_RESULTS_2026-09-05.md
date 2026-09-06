# EXP23AA protected emergency DATA development result

Date: 2026-09-05  
Canonical result: `results/exp23aa_emergency_data_development/2026-09-05_073757`  
Status: `PROTECTED_EMERGENCY_DATA_DEVELOPMENT_FEASIBLE`  
Scope: development evidence only; the graph stimulus is not coupled to online plant state.

## Decision

The protected emergency-DATA mechanism passes all 19 preregistered development gates over 120 trajectories (20 new seeds x 6 paired arms). It repairs the closed-loop safety failure exposed by EXP23Z without claiming that a shared slot is safe during an incomplete migration certificate.

The result supports continuation to bounded control-plane retry/backoff. It does not authorize a submission claim, a fresh-seed confirmation, or a plant-coupled geometry claim.

## Mechanism result

- Ordinary migration moves UAV 10 from old slot 7 to certified slot 9 after one local conflict edge appears.
- While that node is suppressed, protected arms offer DATA in reserved slot 10, outside both the old and candidate colorings.
- Exact recipient-level physical outcomes are bound after the overlay; no shared-slot success is assumed.
- All protected and ordinary arms are collision-free and have zero replay, accounting, clock, cross-plane, or causal-instrumentation mismatches.
- All 60 ordinary migration rows reacquire.
- Under permanent RESPONSE loss, the lease remains fail-silent while protected emergency DATA restores separation safety in 20/20 rows.
- The unprotected silent comparator retains the EXP23Z boundary: 20/20 separation failures.
- Permanent REVOKE loss has exactly zero effect on protected local state, performance, and cost.

## Main paired effects

| Candidate vs reference | RMSE change | Cost change | Interpretation |
|---|---:|---:|---|
| migration, no emergency vs periodic (IID-20) | +5.01% | -7.90% | migration saves cost but is not yet accuracy-competitive |
| migration, emergency vs migration, no emergency (IID-20) | -1.95% | +0.57% | protected service improves tracking for small incremental cost |
| emergency vs silent fallback under RESPONSE blackout | -53.14% | +4.55% | emergency DATA converts fail-silent scheduling into safe closed-loop service |
| emergency RESPONSE-blackout vs periodic (IID-20) | +2.94% | -1.27% | safety is restored, with a small remaining accuracy gap and lower total cost |
| emergency REVOKE-blackout vs emergency nominal | 0% | 0% | exact REVOKE-loss independence |

Mean minimum separation under the protected RESPONSE-blackout arm is 0.5003 m, versus 0.1701 m for the silent comparator. The protected arm's mean RMSE is 0.08565 m and mean cost is 0.25275, compared with 0.08320 m and 0.256 for periodic IID-20.

## Remaining weakness exposed by this run

Protection solves the DATA-service failure, but the management transaction still retries indefinitely. Mean management airtime rises from 0.17279 in ordinary migration to 0.36039 under permanent RESPONSE loss, and mean control attempts rise from 192.55 to 379.6. The next gate therefore bounds and backs off CLAIM retry while retaining emergency service, collision safety, and ordinary reacquisition.

## Integrity and scope guards

- Matrix coverage: 120/120 unique rows.
- Seeds: 16087001--16087020; development seeds, not fresh confirmation seeds.
- Registry: 86 frozen leaves; short registry hash `76584149`.
- `geometryCoupledToPlant=false`.
- `freshSeedEvidence=false`.
- `submissionClaimPermitted=false`.
- The incomplete `_073456` run is invalid because postprocessing expected 18 gates after a nineteenth gate had been added. It produced no validation-gate or verdict artifact and is not scientific evidence.

## Canonical SHA-256

| Artifact | SHA-256 |
|---|---|
| `trajectory_tidy.csv` | `20219C7B2ABFB25EE1D102AFF7DB4AB5B0196A3F314614EF585DB73362A68C1C` |
| `summary.csv` | `9FF928409CA6F3AE90AD86E8045E75A6012541E25FDF02E0F127CD8588117BD5` |
| `paired_contrasts.csv` | `3766E9B98E072FA20BC67FDA8BC6AEBE326077001DAA4A08DABAB97E4211FC0C` |
| `validation_gates.csv` | `DAF0D0A5797410D8A094639A32C82AA516E52C51719725929F0B968B791362D3` |
| `emergency_verdict.json` | `FCA1323993CDAC85349B8E2704CCEE1E9AA010F5814FD8205B552501C78FD125` |

