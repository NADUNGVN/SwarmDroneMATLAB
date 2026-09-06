# EXP21D-K — D-STR prior-art kernel conformance plan

**Status:** amended before the registered 800-row run; see
`docs/EXP21D_DSTR_KERNEL_AMENDMENT_01.md`

**Study type:** prior-art mechanism reproduction, conformance, and
falsification; no closed-loop performance claim

**Primary source:** A. Samandari, A. Willig, B. Wu, and P. Martin,
"Distributed Self-allocated Time Slot Reuse: Multi-hop Communication in
Rigid UAV Formations," 2025, `arXiv:2511.12888`.

**No-source-code boundary:** public protocol text and thesis are available,
but no author implementation was located.  The kernel is therefore a
rule-mapped mechanism reproduction, not bit-identical source-code
reproduction.  Every implemented state transition must be mapped to source
text in `docs/EXP21D_DSTR_RULE_MAP.md`.

## 1. Why this study is necessary

EXP21A used a custom Aydin-inspired reservation projection.  The post-EXP21
audit found that D-STR is closer to this project's actual traffic: periodic
peer broadcast of UAV position/velocity, decentralized self-allocation,
implicit reception evidence, management-slot collision detection, dynamic
superframe length, and multi-hop reuse.

Before a new scheduling protocol may be proposed, this study asks:

> Can the published D-STR state machine be reproduced under its native
> synchronized/static/no-external-interference assumptions, and does the
> resulting event/accounting kernel expose the exact failure mechanisms when
> those assumptions are relaxed?

## 2. Frozen protocol settings

The registered primary settings use source-evaluated protocol values where
stated below, plus declared kernel accounting choices:

- five management slots: `TG`, `TGn`, `TS`, `TSo`, `TSn`;
- ten initial transmission slots (the source-evaluated upper default);
- collision threshold `CT = 3`;
- growth margin `GM = 3` slots;
- shrink threshold `ST = 5` superframes;
- failed-shrink cache timeout `FST = 10` superframes;
- time-slot retention probability `TSR = 0.75`;
- 512-byte beacon/control frame;
- 1 Mbit/s reference PHY for airtime accounting; and
- maximum 200 superframes.

The first node is active and resolved in transmission slot 1 before all other
nodes join.  This follows the source assumption that exactly one node is
first; simultaneous-first-node resolution is out of scope for the native
baseline.

The isolated kernel advances synchronized *logical* superframes.  It does not
re-simulate continuous oscillator phase, drift, or guard overlap: those were
validated separately by EXP21B and integrated into closed-loop delivery by
EXP21C.  Consequently, `restricted-management` isolates loss of
formation-wide reach while retaining logical slot alignment; it is not a
second continuous-time timing experiment.  EXP21D-CL must compose this
state-machine output with the EXP21B/C timing layer before making an
asynchronous-clock claim.

All random slot selections and retention decisions are pre-drawn by absolute
`(seed,frame,node)` indices.  No result-dependent draw consumption is
permitted.

## 3. Frozen factor matrix

One hundred fresh development seeds `16033001:16033100` are used for each of
two swarm sizes (`N=5`, `N=10`) and four conditions:

1. `native`: compact rectangular hexagonal formation at 10 m spacing, 10 m
   safety-neighborhood radius, formation-wide management reach, zero
   exogenous erasure, no churn;
2. `beacon-loss`: same topology with independent 0.05 post-collision beacon
   erasure; management slots retain zero exogenous erasure so this factor
   changes DATA-beacon evidence only;
3. `restricted-management`: the same DATA neighborhood and interference
   abstraction as native, but management reach is restricted to the local
   safety-neighborhood graph instead of the formation-wide channel; and
4. `churn-rejoin`: native graph, with node 2 losing schedule state at superframe 60
   and rejoining through the normal Start/Assignment states.

The complete registered matrix contains `100 x 2 x 4 = 800` rows.  Conditions
2--4 are boundary projections, not claims about the source protocol.
All four conditions at a fixed `(seed,N)` consume the same absolute
`choice`, retention, DATA-delivery, and management-delivery arrays; condition
logic cannot change random-draw consumption.

## 4. Protocol semantics that are frozen

Each node is in `Start`, `Assignment`, or `Resolved` state.  A decoded beacon
provides superframe metadata, sender identity, and the sender's prior
three-state reception record for each transmission slot:

- `0`: no energy/no packet;
- `1`: exactly one decodable packet; and
- `2`: energy detected without a decodable packet.

An Assignment node randomly chooses a locally available slot.  It claims the
slot only after received neighbor records provide positive reception evidence;
otherwise it retries and increments the collision counter.  A Resolved node
retains its slot while subsequent received records support reception; after
failed evidence it releases with probability `1-TSR` and otherwise retains.

When no slot is available or `CT` failed attempts occur, the node transmits a
grow request in `TG`.  One decodable request carries its requested increment;
multiple requests create energy-without-decode and listening nodes transmit in
`TGn`.  Energy in `TGn` forces a `GM`-slot growth.  All management frames
occupy their named slot and collide under the same interference rule.

The shrink path follows `TS` proposal, `TSo` objection, and `TSn` undecodable-
proposal evidence.  Only Resolved nodes accumulate `ST` silent-superframe
counts.  Assignment nodes object irrespective of decoding `TS`; an objection
resets the local counter and enters the proposed slot in the `failed_shrink`
cache for `FST` superframes.  A NACK-only outcome uses truncated exponential
backoff.  Removing a slot shifts higher local slot indices while preserving
order.

The kernel computes physical delivery/collision truth, but protocol state
transitions may read only locally delivered beacons, local energy observations,
local state, and pre-drawn local randomness.

In particular, a locally accepted shrink shifts only that node's schedule
coordinates; a local state-loss event does not delete stale peer records; and
a grow exchange outside a node's management reach cannot suppress that
node's shrink decision.  Global physical state is used only for outcome
metrics and never to reconcile these local views.

The source uses a path-loss/SINR physical layer.  EXP21D-K is deliberately a
state-machine kernel and replaces that layer with a binary safety-neighborhood
conflict graph: a beacon is required at safety neighbors and simultaneous
transmitters conflict when they share such a receiver.  It therefore tests
protocol-transition conformance, not reproduction of the source's numerical
SINR or convergence distributions.  A later comparison must not label these
kernel numbers as the authors' reported performance.

## 5. Metrics

Each row records:

- first resolution and convergence frame;
- recovery after churn;
- final superframe length and number of active transmission slots;
- fraction of frames with a conflicting physical assignment;
- false-resolved node-frames, where local Resolved state is not supported by
  physical reception at every declared neighbor;
- beacon and management attempts, successes, erasures, and collisions;
- grow/shrink requests, NACKs, objections, and applied changes;
- offered and successful airtime;
- maximum local superframe disagreement; and
- future-random/global-truth read counters.

## 6. Integrity and conformance gates

Randomized interpretation opens only if all gates pass:

1. exact unique 800-row matrix and declared seed/factor coverage;
2. deterministic replay under identical trace and configuration;
3. all source-mapped deterministic transition tests pass;
4. every native row resolves to a physically valid assignment within 200
   superframes;
5. every native row also converges with no globally unused transmission slot;
6. all native nodes agree on final superframe length;
7. every recorded collision has positive simultaneous interference and every
   successful reception has exactly one decodable transmitter;
8. management/data/erasure terminal accounting closes;
9. all named management paths activate in deterministic witnesses;
10. zero future-random reads and zero protocol reads of hidden physical truth;
11. all unsafe/nonconverged outcomes are retained; and
12. registry/source hashes are frozen before aggregate analysis.

The executable registry requires 14 deterministic contract checks.  The run
stores an eleven-file frozen-source manifest and generates aggregate summaries
only after all 800 registered rows have been retained.

Scientific failure is not an integrity failure.  Conditions 2--4 may fail to
converge without invalidating a correctly implemented kernel.

A collective half-duplex collision in which every active node transmits in
the same data slot has no idle observer from which an implicit reception
record can return.  The deterministic suite preserves this as a nonconvergent
boundary instead of repairing it with physical-truth access.  The separate
TG/TGn witness therefore uses two colliding claimants and idle listeners.

## 7. Verdict

If all gates pass, the verdict is `DSTR_KERNEL_CONFORMANCE_VALID`, which
authorizes closed-loop prior-art comparison.  Any gate failure yields
`DSTR_KERNEL_INVALID_NO_CLOSED_LOOP`.

This study cannot promote a new policy, support a submission claim, or claim
that D-STR is robust outside its source assumptions.
