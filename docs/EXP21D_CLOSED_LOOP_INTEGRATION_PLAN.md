# EXP21D-CL: D-STR closed-loop integration plan

**Frozen before randomized closed-loop outcomes:** 2026-09-01  
**Stage:** prior-art integration and falsification  
**Upstream gate:** EXP21D-K run `2026-09-01_070545`, 17/17 gates  
**Policy optimization:** prohibited  
**New-method or submission claim:** prohibited

## 1. Question and scope

EXP21D-CL asks whether the source-mapped D-STR baseline remains a meaningful
communication/control reference after its complete acquisition process is put
on the same continuous physical timeline as the formation controller.

This is not a performance reproduction of the D-STR paper. The first
integration version is deliberately source-native in its information
assumptions: synchronized slots, formation-wide management reach, static
topology and zero exogenous erasure. It changes only the payload/PHY accounting
to the common Study-2 values. Later registered boundary stages will add DATA
erasure, restricted management visibility and local state loss/rejoin without
retuning the kernel.

## 2. Causal composition

The D-STR state machine is evaluated from absolute, seed-indexed draws. For
logical superframe `f`, its state transition reads only draws with index at
most `f`. Precomputation is permitted only as a deterministic replay artifact:
the event engine owns monotone cursors and exposes a DATA or management start
only when its absolute start time enters the current interval. No controller
state, receiver truth, future delivery result or final D-STR assignment may
enter a scheduling decision.

Every logical superframe is translated in order as

1. `TG`, `TGn`, `TS`, `TSo`, and `TSn` management slots;
2. the frame's locally declared DATA slots; and
3. a slot duration `T_slot = 8B/R + G` comprising exact transmit airtime and
   the already validated guard.

The translated DATA sender in each slot is exactly `debug.txSlotThis(f,:)`
from the kernel, not the terminal assignment. Consequently bootstrap
collisions, temporary assignments, growth, shrink and continued management
traffic remain present in the closed loop.

## 3. Common physical accounting

The native integration and its periodic reference use the same DATA bytes,
PHY rate, receiver topology, interference graph, exact DATA airtime, mission
horizon and controller. D-STR management frames use the same conservative
frame-byte charge in version 1. For each management slot the implementation
records:

- number of physical transmit attempts;
- busy-time union, charged once even for simultaneous attempts;
- offered airtime, charged once per transmitter;
- recipient attempts and physical collision/erasure/success outcomes; and
- logical type and source frame.

The reported D-STR charged utilization is DATA offered airtime plus management
offered airtime divided by the mission horizon. Channel utilization is the
union of DATA, management and declared background busy intervals. Guard time
occupies the schedule but is not counted as radio transmit energy.

## 4. Integration stages

### Stage A — deterministic contracts

No randomized closed-loop matrix may run until all contracts pass:

1. translated starts are monotone and remain within the mission horizon;
2. every kernel DATA attempt maps to exactly one scheduled start;
3. every kernel management attempt maps to exactly one scheduled start;
4. DATA and management intervals do not overlap under synchronized timing;
5. event-engine DATA collisions equal kernel collision witnesses at zero loss;
6. management attempt, busy-union and airtime accounting close exactly;
7. repeated seed/config replay is bit-identical;
8. truncating the mission exposes an exact prefix of a longer replay;
9. only due schedule entries are consumed; and
10. an end-to-end controller smoke case completes with zero protocol
    invariant violations.

### Stage B — native closed-loop comparison

Cells: `N=5 Stressed` and `N=10 Moderate`, inherited from EXP21C. The channel
has zero exogenous loss and zero background occupancy so the test isolates
distributed schedule acquisition and shrink traffic.

Arms:

- common-PHY periodic centralized TDMA at 8.333 Hz, an ideal service
  reference rather than a distributed baseline;
- D-STR native acquisition from the Start/Assignment/Resolved state machine;
- D-STR oracle-warm schedule, used only to decompose acquisition cost from
  steady-state service cost and never labeled implementable.

All arms generate current state at the 50-Hz outer tick with latest-generated-
wins admission. This makes service opportunities, rather than an 8.333-Hz
generator, determine D-STR freshness. The periodic reference retains its
declared 8.333-Hz rate.

Stage B is an integration-validity study. It may establish whether D-STR
acquisition and fully charged management traffic are benign or damaging in
the closed loop; it cannot promote a new method.

### Stage C — frozen boundary continuation

Only after Stage B passes its integrity gates, run the same D-STR parameters
under: 5% DATA-beacon erasure, restricted management reach, and one local
state-loss/rejoin event. All unsafe, unresolved, frame-disagreement and
terminal in-flight rows are retained. Clock uncertainty is composed only
after exact zero-clock equivalence passes.

## 5. Native Stage-B gates

The native integration is valid only if:

- the seed/cell/arm matrix is complete and unique;
- channel, estimator and D-STR absolute trace hashes are paired as declared;
- every source-to-timeline mapping contract passes;
- future-random and receiver-truth decision-read counts are zero;
- exact DATA airtime and management accounting close;
- all zero-loss physical outcomes match their kernel witnesses;
- no terminal recipient count is discarded;
- every divergence and safety failure is retained; and
- the registry still prohibits policy optimization and submission claims.

There is no superiority threshold in EXP21D-CL. The next candidate is designed
only from a reproducible residual failure of D-STR and the other mandatory
prior-art families.

## 6. Stop rules

- Any mismatch between kernel attempt identity and event-timeline identity
  invalidates the integration; results are not interpreted.
- Any need to change D-STR transition parameters after viewing Stage-B outcomes
  creates a new version and new seeds.
- A warm-start result cannot substitute for native acquisition.
- Failure under a boundary outside the source assumptions is reported as a
  scoped boundary, not attributed as failure of the published claim.

