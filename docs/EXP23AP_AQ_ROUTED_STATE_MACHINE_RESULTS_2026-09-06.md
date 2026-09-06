# EXP23AP/AQ routed state-machine result ledger

## Audit lineage

EXP23AP run `results/exp23ap_routed_state_machine_common_phy/2026-09-06_081712`
passed its reported 18/18 gates on 500 seeds, but a post-run audit found that
the named implementation-version gate did not explicitly assert the continuous
builder version hash.  Its raw results are retained; its scientific status is
`SUPERSEDED_BY_CONTINUOUS_VERSION_IDENTITY_AUDIT` in
`superseded_verdict.json`.  No seed from EXP23AP was reused.

EXP23AQ canonical run:
`results/exp23aq_routed_state_machine_confirmation/2026-09-06_081945`.

Status: `ROUTED_MANAGEMENT_STATE_MACHINE_CONFIRMATION_VALID` (19/19 frozen
gates).

## Confirmed result

All 500 newly registered IID routed transactions complete.  The analytical
transaction failure upper bound remains 0.000909554397; the empirical result is
a trajectory sanity check, not a substitute for that rare-event certificate.
The three isolated all-success-plus-blackout traces preserve the intended
fail-safe boundary:

- PREPARE blackout: no barrier, motion, evidence, response, or commit;
- RESPONSE blackout: the barrier closes, but certification and commit do not;
- COMMIT blackout: certification succeeds, but remote nodes remain suppressed.

Normal transactions use 328--436 physical attempts (mean 348.552) and
12,952--19,144 physical bytes (mean 13,853.104).  Kernel state hashes and
integer attempts/bytes/airtime replay exactly in the continuous builder.
Across all normal and fault traces there are zero receiver collisions,
cross-packet writes, forbidden reads, premature activations, or bundle-envelope
violations.  Every clock-impaired replay preserves management accounting.

Normal 11-index schedules last 2.295593--2.781123 s; convergence occurs in
1.440754--2.333214 s.  The worst registered fault schedule lasts 3.970624 s.
All remain below the frozen 5.034618 s conservative bound and 6.5 s budget.

This evidence promotes `managementRelayingValidated=true`.  It does not promote
`closedLoopManagementRelayingValidated`, repeated renewal, fresh-seed system
evidence, broad robustness, or submission readiness.  The next gate must drive
the plant and its DATA traffic with this exact continuous routed schedule.

## Canonical SHA-256

- `routed_state_registry.json`: `14B8FBDB494A55A3440630CCE0BAE908895ADAD0519C661B6BE14FB86943B32F`
- `normal_routed_transactions.csv`: `3FA7A66D6D2587544B86B4C45B99A2506624CB130A6A6109865585327E49713A`
- `routed_fault_trajectories.csv`: `846CF9046F28F0BC0E8411C8F039FAE61717B0849FD7F89EACE8C4E490E88B05`
- `dynamic_bundle_envelopes.csv`: `FB63925FF3D496FA3D4BD7A6DE50B6E1FCA84D9F6B44FFBABEE13AFC8D1C6889`
- `routed_transaction_certificate.json`: `82E3EBA51AC4CAD1FE08370209F04D651F6469BC331FC5DAF2C5326369646506`
- `validation_gates.csv`: `2E7CF0EAE65A717476D56D454C4603508E5A2CB426AC91F0CD9627A193804681`
- `routed_state_verdict.json`: `1421AFC8ACA659B945C6693CD2A49342A6DDDFED4AF7B0DB01B11336670EBC2E`
- `workspace.mat`: `2E54AA3C662B3C2B7368E40BECE148A3E32023642467CF9A0B6B5429DFA2223D`
