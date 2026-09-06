# EXP23AR routed common-PHY plant closed-loop plan

Frozen: 2026-09-06, before execution of development seeds
`16096401:16096420`.

## Question and literature gate

EXP23AQ validates the routed receiver-lifted migration state machine and its
continuous management schedule.  It does not show that the resulting physical
DATA opportunities drive the estimator/controller and plant correctly.
EXP23AR tests exactly that missing composition; it does not search for a new
scheduler.

The experiment reuses established mechanisms rather than claiming them:

- FPRP/DTSS motivate localized reservation and receiver response;
- E-TDMA/Aydin/DTSA motivate topology-responsive distributed schedules;
- delayed-feedback AoI and DELTA motivate explicit receiver-knowledge state;
- the repository's EXP23AI supplies the online plant/tube, protected-DATA,
  affine-clock, receiver-replay and radial-safety contracts.

The candidate-specific question not answered by those sources is whether the
exact routed version/witness transaction remains causally and physically
correct after composition with closed-loop formation DATA on one PHY.

## Frozen inheritance

- Parent: EXP23AQ run `2026-09-06_081945`, status
  `ROUTED_MANAGEMENT_STATE_MACHINE_CONFIRMATION_VALID`, 19/19 gates.
- Plant/geometry/accounting base: EXP23AI configuration and six-arm structure.
- N=10, ring-2 DATA graph, IID 20% DATA and routed-link erasure, 250 kb/s PHY.
- Mission 10.5 s, request at 4.0 s, command ramp 2.0 s.
- Exact EXP23AQ routed transaction: four repetitions per hop, three PREPARE
  attempts, four CLAIM opportunities, two evidence-prefix attempts, two COMMIT
  attempts and 11 transaction frames.
- Registered reliability upper bound target `1e-3`; post-request transaction
  budget 6.5 s.
- Affine clock bounds and full-mission safe guard are unchanged from EXP23AI.

The 11-frame transaction is first built with the unchanged EXP23AQ state
kernel and routed continuous builder.  A mission embedding adds only:

1. old-schedule DATA before the request;
2. protected DATA in registered emergency slots whenever an affected sender is
   suppressed;
3. terminal old/new schedule DATA after the transaction;
4. a time shift of the exact management events by the request time.

The embedding must reproduce every transaction DATA tuple and every management
attempt exactly.  DATA receiver outcomes are then independently rebound from
the physical graph and overlaid with the registered absolute-time IID trace.

## Development matrix

Twenty paired seeds and six arms (120 rows):

1. periodic IID-20 reference;
2. routed normal closure with protected DATA;
3. routed RESPONSE blackout with protected DATA;
4. routed RESPONSE blackout without protected DATA (negative control);
5. routed PREPARE blackout with protected DATA;
6. routed COMMIT blackout with protected DATA.

Seed `16096301` is reserved for contract smoke tests.  The matrix is
development evidence; no final superiority or robustness claim is permitted.

## Non-negotiable gates

- exact parent and selected routed-policy identity;
- online decision state and pre-request physical schedule are identical across
  paired routed arms;
- no future-random or receiver-truth decision read;
- routed state hash, attempts, integer bytes and airtime replay exactly;
- transaction management events are unchanged by mission embedding;
- no management/DATA overlap, route receiver collision or cross-packet write;
- shared-medium executor observes exactly the bound DATA outcomes and all
  management attempts/bytes;
- motion begins only after the routed quiescence barrier;
- protected service maps each suppressed sender to a distinct reserved slot;
- every protected arm satisfies the radial/physical/sender-graph safety
  contracts, has no scheduled collision, safe failure or divergence;
- the no-emergency RESPONSE-blackout negative remains visible;
- all downstream renewal, robustness, fresh-confirmation and submission flags
  remain false.

## Decision

A complete pass may set `closedLoopManagementRelayingValidated=true` for this
development cell.  It does not validate repeated renewal, a broad operating
envelope, prior-art superiority, fresh confirmatory evidence or submission
readiness.  Any failure returns to mechanism diagnosis without relaxing a
registered gate.

