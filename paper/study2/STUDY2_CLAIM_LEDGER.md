# Study 2 claim ledger after EXP17

This ledger governs the Study 2 manuscript draft. A supported claim may be
used only with its scope. A bounded or rejected claim may not be converted to
a positive statement by omitting its comparator, MAC, support condition, or
accounting unit.

## Supported

| ID | Claim | Evidence | Required scope |
|---|---|---|---|
| S2-1 | ACK-confirmed sender age is conservative relative to receiver truth | Theorem 1 and zero protocol violations in frozen matrices | honest cumulative feedback, monotone updates, consistent initialization |
| S2-2 | Broadcast aggregation improves the Moderate causal-unicast mechanism | EXP14A: −59.05% offered utilization and −3.50% RMSE | N5 Moderate abstract shared medium |
| S2-3 | Analytical access scaling is necessary for the tested N20 repair | EXP14C/D; fixed p collapses, scaled selected has zero development failures | N20 ring2, declared p-persistent model |
| S2-4 | Selected adaptive/scaled feedback improves over access-only | EXP14E, 6/6 Holm tests over N5/N10/N20 CSMA | registered CSMA cells and comparator only |
| S2-5 | Positive confirmation lead is not sufficient for receiver benefit | EXP14G: adverse N5 true-AoI and N10 formation-loss effects | supported focal events, 0.75-s horizon |
| S2-6 | Frozen MAC selector chooses the better registered feedback route | EXP14I, 6/6 Holm tests and 3/3 cell guards | N5/N10 CSMA and N5 ALOHA cells |
| S2-7 | Configured access mechanism changes the relative adaptive-versus-piggyback effect | EXP16: both formal within-seed interactions and all four simple effects pass the frozen six-test Holm family | matched N5 Moderate abstract CSMA/ALOHA cell only |

## Bounded / descriptive

| ID | Statement | Boundary that must accompany it |
|---|---|---|
| L2-1 | Initial Causal-Broadcast family contributes Pareto points | its default is dominated by delayed belief in Clean, Moderate and Stressed |
| L2-2 | Adaptive feedback becomes nearly piggyback-only at N20 | only 11/300 parents contain an eligible event; no focal effect or equivalence is identified |
| L2-3 | Candidate has 0/100 observed failures in EXP14I cells | Wilson upper bound is 3.70%; no population safety claim |
| L2-4 | ALOHA standalone feedback has favorable focal mean signs | EXP14G intervals are heterogeneous and cross zero |
| L2-5 | The theory connects service to age and formation error | A7 minorization, bounded motion, grounding and unsaturated-region assumptions must be checked |
| L2-6 | EXP16 has 0/100 observed failures in all six arms | each Wilson upper bound is 3.70%; observed guards are not population safety evidence |
| L2-7 | Adaptive and fixed-deadline hybrid are close under ALOHA | their RMSE and offered-load paired intervals cross zero; no equivalence or adaptive-over-hybrid claim is identified |
| L2-8 | The formal EXP16 interaction is replicated in the N5 Moderate bg0 base cell | EXP17 supports that cell but only 1/8 core contexts overall; the result is a local operating-region claim |
| L2-9 | Some mechanism components persist outside the base cell | 11/48 global-Holm tests pass, but incomplete simple-effect/interaction sets cannot be promoted to selector support |
| L2-10 | A parameter-free capacity screen and fixed-route implementation pass development audit | EXP18A4 passes 14/14 integrity and 6/6 development gates with exact 400/400 route aliasing; EXP18B remains unopened, so no confirmatory performance claim is permitted |

## Rejected

| ID | Rejected proposition | Evidence |
|---|---|---|
| R2-1 | The initial default is universally frontier optimal | delayed-belief points dominate the default in all three primary regimes |
| R2-2 | Fixed p=0.2 scales to N20 | initial hybrid fails 100/100 with offered demand 2.849 |
| R2-3 | The fixed load guard monotonically improves congestion and control | it lowers N20 demand but worsens RMSE/AoI and causes 6/12 failures |
| R2-4 | Standalone ACK is universally better than piggyback | piggyback is better at N5/N10 CSMA; direction reverses under ALOHA |
| R2-5 | Positive ACK lead certifies positive AoI/control value | focal replay yields significant adverse receiver effects |
| R2-6 | Configured MAC type alone selects the better feedback route over the declared load/loss/N envelope | EXP17 supports only 1/8 core contexts and fails the frozen continuation gate |
| R2-7 | The current general selector is ready to advance automatically to hardware validation | EXP17 continuation verdict is `DO_NOT_PROCEED_WITH_GENERAL_SELECTOR` |
| R2-8 | The two attempted marginal ACK-value heuristics are ready for confirmation | EXP18A2 was not scientifically frozen and EXP18A3 failed its exact-route development gate; both are stopped |

## Explicitly not claimed

- universal optimality across MAC protocols, loads, topologies, or radios;
- a named-standard MAC result or a general route-by-MAC interaction outside the matched EXP16 cell;
- N20 focal ACK value or adaptive/piggyback equivalence;
- population safety superiority or noninferiority;
- measured radio energy, named-standard compliance, HIL or flight readiness;
- hardware readiness of the current MAC-only selector after the EXP17 stop gate;
- confirmatory superiority, optimality or hardware readiness of the EXP18A4
  development-only capacity-gated selector;
- adversarial ACK integrity or security;
- a 6-DOF nonlinear stability theorem.
