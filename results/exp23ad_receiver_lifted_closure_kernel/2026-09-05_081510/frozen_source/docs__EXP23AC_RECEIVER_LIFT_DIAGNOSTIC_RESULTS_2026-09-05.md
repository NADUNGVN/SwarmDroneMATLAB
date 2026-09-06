# EXP23AC receiver-lifted dependency diagnostic result

Date: 2026-09-05  
Canonical result: `results/exp23ac_receiver_lift_diagnostic/2026-09-05_080210`  
Status: `ONE_SENDER_LOCALITY_REJECTED_BY_RECEIVER_LIFT`

## Decision

The direct path from the one-sender migration kernel to online plant-state tubes is rejected. Changing only UAV 10's advertised state can change sender-conflict edges not incident to UAV 10 after the physical graph is lifted through intended broadcast receivers.

The next mechanism must migrate the receiver-lifted dependency closure—the endpoints of every changed sender-conflict edge—not merely the node whose physical state changed.

## Evidence

- All five formation-command candidates remain safe; minimum separation ranges from 0.4372 to 0.5140 m.
- Candidate 3 (`[-1.05, 0.55, 0]`) has minimum separation 0.4772 m and maximum UAV-10 acceleration 0.3499 m/s^2.
- Across the registered online tube scan, 89 sender-conflict graph-change rows occur.
- 86/89 are rejected specifically as `nonlocal_graph_change` by the production local-union builder.
- The remaining 3 graph changes are locally admissible removals, but none changes UAV 10's slot; therefore none exercises a real local migration.
- No admissible local, slot-changing plant-coupled event exists in the scanned envelope.

## Why the locality premise fails

The receiver-lifted conflict edge between senders (a) and (b) depends on physical detectability at every intended receiver of either sender. If moving UAV (i) is an intended receiver of (a), a change in physical relation (I_{ib}) changes conflict edge (F_{ab}). Neither endpoint must be (i). Thus

\[
\Delta I\text{ incident to }i \centernot\implies
\Delta F\text{ incident to }i.
\]

This is not a numerical corner case; it follows from the broadcast receiver lift itself. Selecting a radius that happens not to trigger it would narrow the test but would not repair the theorem.

## Scope consequence

- EXP23X–AB remain valid for their declared fixed/local graph-input scopes.
- They do not establish online plant-coupled graph migration.
- A safe extension must compute the changed-edge endpoint closure, suppress that set before the new tube becomes active, jointly recolor it against fixed outside nodes on the union graph, and require positive causal closure before reactivation.

## Canonical SHA-256

| Artifact | SHA-256 |
|---|---|
| `formation_candidates.csv` | `C5009B5CA12BD33505799006434918713CD1BC8BCABF493BF3BC3C582C51E812` |
| `admissible_local_events.csv` | `4B4F02206EF0B324B413538897AF8C782BA596F03A40B62B4CEBC0C571BC1BB4` |
| `receiver_lifted_graph_changes.csv` | `B0A640B840D8171ECF4C58D52FCA962A91AAF9A80E2E18113352A3E24302D5B5` |
| `receiver_lift_verdict.json` | `481172419B219EC9D383CD6A0B822AD01BEB0E00F63C790E0DF42B94A351BEB0` |

