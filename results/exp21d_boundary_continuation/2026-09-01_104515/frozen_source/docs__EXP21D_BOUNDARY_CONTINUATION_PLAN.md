# EXP21D-B: D-STR closed-loop boundary continuation

**Frozen before randomized boundary outcomes:** 2026-09-01  
**Upstream gate:** EXP21D-CL v3 run `2026-09-01_080135`, 17/17 gates  
**Stage:** prior-art boundary falsification  
**Parameter optimization/new-method promotion/submission claim:** prohibited

## 1. Question

EXP21D-B determines which source-native D-STR assumption becomes the dominant
closed-loop failure mechanism once the exact kernel/event-timeline composition
is valid:

1. unreliable implicit DATA reception records;
2. incomplete management visibility and consequent frame disagreement; or
3. loss of one node's local schedule state followed by normal rejoin.

It does not search for a repair. Any later candidate must be derived from a
reproducible failure in this frozen matrix.

## 2. Matrix

The study uses 30 fresh seeds, the accepted N5 6-DOF and N10 ring2 cells, and
six arms:

- zero-loss native D-STR;
- zero-loss oracle-warm conflict coloring;
- native D-STR with independent 5% DATA-beacon erasure;
- oracle-warm coloring with the same 5% DATA-beacon erasure, separating pure
  physical loss from schedule-state corruption;
- native D-STR with management reach restricted to the physical neighbor
  graph; and
- native D-STR with node 2 losing all local schedule state at source frame 60
  and rejoining through the normal protocol path.

All arms reuse the same absolute D-STR choice, retention, DATA-delivery and
management-delivery arrays within each seed/cell. DATA erasure outcomes are
attached to the exact scheduled frame and replayed into the receiver cache
used by the controller; they are not applied only inside the scheduler.

## 3. Restricted-visibility interpretation

The source's formation-wide management assumption keeps every local frame
length equal. Once reach is restricted, the isolated kernel can produce local
frame disagreement. Its logical-frame loop then acts as an optimistic
alignment projection: it advances all nodes after the maximum declared frame
length even when a real node with a shorter local frame would start its next
management phase earlier.

Therefore each row carries `PHYSICAL_REPLAY_VALID`:

- `1` only if local frame agreement holds throughout the mission prefix;
- `0` if any disagreement occurs.

Controller metrics from invalid restricted-visibility rows are retained in the
tidy artifact but excluded from performance summaries and paired effect
estimates. The valid scientific result for those rows is loss of composable
schedule state, not their optimistic RMSE. This prevents a synchronized global
timeline from being misreported as a realistic distributed execution.

## 4. Outcomes

Primary mechanism outcomes are:

- terminal resolved/collision-free/frame-agreement status;
- first convergence and, for rejoin, recovery time;
- maximum local frame disagreement and false-Resolved node-frames;
- DATA collision, erasure and success outcomes with exact kernel/event match;
- management attempts, recipient outcomes and charged airtime;
- offered/busy utilization and service goodput; and
- formation RMSE, true AoI and observed safety failure only for physically
  valid replays.

The beacon-loss native-vs-warm contrast isolates schedule corruption beyond
pure packet erasure. Zero-native vs rejoin-native isolates recovery outage.
Restricted management is evaluated primarily by composability/validity rates.

## 5. Integrity gates

The study is valid only if:

1. all 360 seed/cell/arm rows are present exactly once;
2. shared and D-STR absolute trace hashes are paired as declared;
3. there are zero future-random and receiver-truth decision reads;
4. no D-STR DATA opportunity is skipped;
5. scheduled and observed DATA success/erasure/collision counts match exactly;
6. event-engine collision frames equal translated kernel witnesses;
7. management recipient and attempt-times-airtime accounting closes;
8. DATA/control-plane intervals do not overlap in the zero-clock model;
9. all restricted rows with any frame disagreement are marked physically
   invalid and excluded from performance inference;
10. rejoin is activated in every rejoin row and all finite/nonfinite recovery
    outcomes are retained;
11. terminal recipient/right-censor accounting closes;
12. protocol invariant violations are zero;
13. all unsafe/divergent/unresolved rows are retained; and
14. the registry still prohibits tuning, promotion and submission claims.

There is no pass threshold for robustness superiority. A negative boundary is
an intended outcome; only integrity/composability errors invalidate the study.

## 6. Decision rule

- If beacon loss leaves warm valid but destabilizes native schedule evidence,
  a candidate must protect schedule validity/evidence without assuming ACKs.
- If restricted reach destroys frame composability, a candidate must include
  explicit version/epoch consistency and fallback rather than only changing
  backoff or frame size.
- If rejoin dominates, bounded fallback and state reconstruction become the
  first target.
- If none creates a material gap, no new scheduler is justified by this line
  and the research must return to another communication-layer contribution.

