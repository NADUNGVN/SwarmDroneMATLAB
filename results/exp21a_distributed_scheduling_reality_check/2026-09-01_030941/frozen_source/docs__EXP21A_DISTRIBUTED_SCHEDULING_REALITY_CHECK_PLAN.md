# EXP21A — Distributed scheduling reality check

**Status:** frozen design, written before any EXP21A outcome is generated

**Study type:** development/falsification; simulation only

**Candidate tuning:** prohibited after the first outcome is generated

**Hardware and manuscript promotion:** prohibited by this study

## 1. Why this study exists

EXP20A stopped the semantic-policy branch because periodic collision-free TDMA
explained the remaining formation frontier.  That result is not yet a networked
communication result: the scheduler had a common slot clock, a conflict-free
assignment, no schedule-acquisition traffic, no lease repair, and no churn.

EXP21A asks one narrow question:

> Does the periodic-TDMA advantage over the current frame-aware policy survive
> when slot ownership is obtained and maintained by causal, distributed,
> lossy two-hop reservation messages whose airtime is charged?

The distributed arm is an **Aydin-inspired two-hop reservation projection**,
not a reproduction of Aydin et al. and not a new semantic trigger.  The source
paper's relevant mechanisms are explicit slot negotiation, positive/negative
responses, two-hop reuse constraints, migration, and repair.  EXP21A retains
those mechanisms at the abstraction level supported by the existing simulator.

## 2. Fixed arms

Every seed/cell group contains seven arms:

1. `frame-piggyback`: current causal event-triggered ALOHA reference;
2. `ideal-tdma-p8p333`: ideal centralized periodic TDMA at 8.333 Hz;
3. `ideal-tdma-p10`: ideal centralized periodic TDMA at 10 Hz;
4. `local-static-p8p333`: fixed node-to-slot map executed from local clocks,
   without reservation control;
5. `distributed-reservation-p8p333`: two-hop reservation at 8.333 Hz;
6. `distributed-reservation-p10`: rate sensitivity only; and
7. `zmac-like-hybrid`: the EXP20A hybrid prior-art projection.

The registered primary distributed arm is 8.333 Hz.  The 10-Hz arm cannot
replace it in any primary decision.

## 3. Reservation mechanism and causality

The reservation frame contains `N` 1-ms data slots.  Every 0.5 s, active nodes
broadcast a 24-byte request for their current or proposed slot.  Each observer
uses only requests it received in that epoch to emit one aggregate response
(12-byte base plus 4 bytes per heard request).  A source accepts or renews a
slot only after at least one delivered positive response and no delivered
negative response.  Accepted sources broadcast a 16-byte commit.  Conflicting
proposals known to an observer receive a negative response and must migrate in
a later epoch.  Reservation knowledge expires after 1.5 s.

All request, response, and commit transmissions are serialized and rounded up
to at least one MAC slot.  Their occupied slots block DATA and their full
airtime is included in charged offered utilization.  Reception loss is drawn
at absolute `(seed, epoch, receiver, sender)` indices before any arm runs.
The policy never reads future draws, receiver DATA-delivery truth, or a global
conflict oracle.

At churn time, one node loses its local reservation state.  Other nodes retain
their stale view until normal lease expiry; there is no instantaneous global
reset.  Clock offset and drift alter only the node's local slot phase.

## 4. Fixed cells and randomization

Thirty fresh development seeds, `16030001:16030030`, are used.  The eight
cells are:

- N5 Stressed: nominal, clock error, control-loss, and churn;
- N10 Moderate: nominal, clock error, hidden-control topology, and compound.

Clock cells use independent node offsets uniformly distributed over
`[-0.25,0.25]` ms and drift over `[-40,40]` ppm.  Control loss is 0.05 in
nominal/clock/churn cells and 0.25 in the control-loss cell.  Churn resets node
2 at 6 s.  The hidden cell restricts control visibility to a two-hop ring while
physical interference remains all-to-all.  The compound cell applies clock
error, control loss 0.25, two-hop visibility, and churn together.

Every run lasts 12 s and the inherited evaluation interval begins at 8 s.
All seven arms in a seed/cell group share the same plant, estimator, channel,
background, control-loss, proposal-choice, clock-offset, and clock-drift draw
tensors.  Random draws are absolute rather than consumed conditionally.

The matrix therefore contains `30 x 8 x 7 = 1680` retained trajectories.

## 5. Fixed metrics and accounting

Primary performance metrics are formation RMSE, observed safety failure, and
charged offered utilization.  Charged utilization is DATA + ACK + piggyback +
public-feedback + reservation-control airtime divided by mission duration.
Control overhead fraction is reservation-control airtime divided by mission
duration.  The study also records collisions, AoI, per-node goodput, reservation
epochs, requests/responses/commits, control receptions/losses, NACKs, migrations,
schedule conflicts, first convergence time, churn recovery time, and future
random reads.

Dominance uses the inherited 1% engineering margin: A is no worse than B by
more than 1% on neither RMSE nor charged utilization, is at least 1% better on
one axis, and has no more observed safety failures.

## 6. Integrity gates

Performance analysis opens only if all gates pass:

1. exact 1680-row matrix, declared seeds, cells, and arms;
2. unique `(seed,cell,arm)` keys;
3. identical exact channel/plant/control trace hashes within every group;
4. no future random read or protocol invariant violation;
5. bounded DATA queues and histories;
6. DATA/ACK terminal recipient accounting closes;
7. control reception accounting closes;
8. all named scheduling mechanisms activate where eligible;
9. reservation control has positive, charged airtime;
10. static and distributed arms use only local clock/schedule state;
11. every unsafe/diverged run is retained; and
12. source/registry hashes are recorded before performance analysis.

Scientific failure is not an integrity failure.

## 7. Frozen stop/go decision

Let the primary nominal cells be N5 Stressed and N10 Moderate.  Let the five
single-fault cells be the two clock cells plus N5 control-loss, N5 churn, and
N10 hidden.  The compound cell is a descriptive stress guard.

The verdict is `DISTRIBUTED_SCHEDULING_PATH_SUPPORTED` only if all conditions
hold for `distributed-reservation-p8p333`:

1. every integrity gate passes;
2. it dominates `frame-piggyback` in both nominal primary cells;
3. it has no more safety failures and mean RMSE no worse than the current arm
   in at least four of the five single-fault cells;
4. mean control-overhead fraction is at most 0.15 over its eight cells;
5. at least 90% of nominal runs first reach a conflict-free full assignment by
   2 s, and at least 90% of churn runs recover within 2 s;
6. in both nominal cells its mean RMSE is no more than 25% above ideal TDMA
   8.333 Hz and its charged utilization is no more than 0.10 higher; and
7. the compound cell has no more observed safety failures than the current arm.

If condition 2 fails, the verdict is `IDEAL_SCHEDULING_ARTIFACT`.  If condition
2 passes but any later robustness, overhead, convergence, ideal-gap, or
compound guard fails, the verdict is `SCHEDULING_GAIN_FRAGILE`.  An integrity
failure yields `INTEGRITY_FAILURE_NO_PERFORMANCE_VERDICT`.

A supported path authorizes a later fresh-seed confirmatory scheduling study;
it does not authorize a hardware or manuscript claim by itself.

## 8. Source provenance and scope boundary

- Aydin et al., IEEE Access 2024, DOI `10.1109/ACCESS.2024.3381859`.
- EXP20A frozen plan and retained results in this repository.

No claim of faithful reproduction, optimality, named-standard compliance, or
hardware readiness is permitted from EXP21A.
