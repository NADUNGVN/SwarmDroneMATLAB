# EXP14C — Post-holdout development of MAC-aware causal feedback

## 1. Status and separation from EXP14

EXP14C is a new development experiment, not an amendment to EXP14A/B. It is
motivated by two retained EXP14 findings:

1. piggyback-only dominates hybrid feedback in the fully sensed primary CSMA
   mechanism contrast;
2. hybrid reverses that ordering under slotted ALOHA, while the frozen
   `p=0.2` design collapses at N=20.

EXP14C may design and screen a new method, but it may not change, rerun or
replace any EXP14 row. The development seeds are `16016001:16016008`; they are
disjoint from EXP13 (`13013001:13013004`), EXP14
(`14014001:14014100`) and Study-1 final seeds. No confirmatory claim is allowed
from these eight seeds. A selected design requires a new preregistered holdout
identifier and new seeds.

EXP15 remains reserved for trace/radio/HIL validation.

## 2. Research question

Can receiver-confirmed semantic triggering select explicit ACK effort and
contention effort from locally observable MAC state so that it:

- retains piggyback's lower overhead under carrier-sensed CSMA;
- retains standalone confirmation where ALOHA otherwise over-triggers DATA;
- prevents the N=20 offered-load/collision collapse;
- never reads collision, delivery or receiver-state truth unavailable to the
  sender?

## 3. Public contract

The new simulator method is `mac-aware-broadcast`; the new feedback enum is
`adaptive`. Existing method and feedback values retain their exact semantics.

`cfg.shared.macAware` is additive and has the following validated fields:

| Field | Development default | Meaning |
|---|---:|---|
| `busyWindow` | 0.25 s | EWMA horizon for locally carrier-sensed busy state |
| `csmaMinAckDelay` | 0.10 s | piggyback-first delay before CSMA standalone ACK |
| `alohaMinAckDelay` | 0.02 s | short standalone delay under ALOHA |
| `maxAckDeferral` | 0.50 s | earliest age at which a deferred ACK may be forced |
| `ackRecheckInterval` | 0.02 s | bounded re-evaluation interval |
| `ackBusyCeiling` | 0.75 | busy level permitting ordinary standalone ACK |
| `ackForceBusyCeiling` | 0.90 | busy level permitting max-deferral recovery ACK |
| `newInfoBusyCeiling` | 0.80 | guard for freshness-adaptive new information |
| `refreshBusyCeiling` | 0.65 | stricter guard for refresh-only DATA |
| `loadGuardEnabled` | true | enable branch-aware DATA load guard |
| `accessScalingEnabled` | true | set `p=min(p_configured,1/N)` |

The causal local signal is `net.localBusyEWMA(node)`. It is updated only from
carrier-sensed active transmitters and background occupancy on the absolute MAC
slot grid. It never uses frame success, loss, collision masks, receiver truth
or future events. Hidden interferers that a node cannot sense remain hidden.

Adaptive feedback always piggybacks when an unsent local DATA frame exists.
Otherwise it delays standalone feedback according to the MAC type and local
busy estimate. A max-deferral ACK is forced only below the declared hard busy
ceiling. Pending ACK state remains bounded and silence is never interpreted as
success.

The branch-aware load guard never blocks hard position/velocity innovation or
the max-silence recovery branch. It may suppress freshness-adaptive DATA and
refresh-only DATA when the local busy estimate or local queue indicates
overload. Every suppression is counted.

## 4. Development matrix

Six fixed cells use the Moderate Gilbert--Elliott DATA/ACK channel:

1. N5 ring2, fully sensed CSMA, 6-DOF;
2. N5 ring2, slotted ALOHA, 6-DOF;
3. N5 ring2, CSMA with 30% background occupancy, 6-DOF;
4. N5 ring2, CSMA with hidden terminals, 6-DOF;
5. N10 ring2, fully sensed CSMA, double integrator;
6. N20 ring2, fully sensed CSMA, double integrator.

Every seed/cell uses one absolute trace across six arms:

1. frozen hybrid;
2. frozen piggyback-only;
3. adaptive ACK only (`p` frozen, guard off);
4. access scaling only (hybrid ACK, guard off);
5. adaptive ACK plus load guard (`p` frozen);
6. full MAC-aware v2 (adaptive ACK, load guard and access scaling).

The matrix contains `8 × 6 × 6 = 288` runs. Thresholds above are fixed before
the matrix; EXP14C is mechanism attribution, not a threshold optimizer.

## 5. Outcomes and development decision

Primary development diagnostics are RMSE, safety-failure numerator, true AoI,
offered/channel utilization, collision frames, DATA/ACK attempts, local busy
estimate, load-guard suppressions and adaptive ACK decisions. All negative
cells remain in the report.

A candidate may proceed to a new holdout only if:

- it has no more safety failures than frozen hybrid in every N5/N10 cell;
- N20 offered utilization is below 1.2 and its safety failures are strictly
  fewer than frozen hybrid;
- it does not lose both RMSE and offered utilization to frozen hybrid in ALOHA;
- causality, memory and three-way terminal accounting gates all pass.

These are development selection rules, not paper claims. Failure closes this
design and motivates a different controller rather than post-hoc threshold
changes.

