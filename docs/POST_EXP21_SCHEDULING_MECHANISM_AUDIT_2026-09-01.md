# Post-EXP21 distributed-scheduling mechanism audit

**Audit date:** 2026-09-01

**Purpose:** determine the scientifically defensible next experiment after
EXP21B/C, using primary protocol papers, standards, and current work through
the audit date.

**Decision:** do not optimize a new scheduler yet.  First close the nearest
distributed-MAC prior art with a native D-ART/D-STR mechanism and make its
control transmissions collide on the same physical timeline.

## 1. What EXP21B/C changed

EXP21A's clock-fault result came from a 1-ms phase-quantized abstraction.
EXP21B replaces that abstraction with an exact continuous local-clock equation
and a sufficient finite-horizon guard; EXP21C verifies the same construction
inside the closed loop.  A certified guard produces zero DATA collisions and
zero failures in both registered cells, whereas the unguarded witness produces
99,752 collision frames and 60/60 failures.

The remaining bottleneck is therefore not whether TDMA can tolerate bounded
clock error under a valid assignment.  It is whether a distributed control
plane can causally establish and maintain that assignment when its own frames
contend, collide, disappear, or carry inconsistent schedule state.

## 2. Updated lineage map

### 2.1 UAV self-organizing STDMA

[Aydin et al. (IEEE Access 2024)](https://doi.org/10.1109/ACCESS.2024.3381859)
already cover decentralized aerial-swarm entry, slot requests, suggestions,
negative replies, slotted-ALOHA retry, one-/two-hop topology state, migration,
exit, and frame resizing.  Negative rather than positive replies reduce reply
traffic.  The work evaluates access delay and channel utilization in
OMNeT++/INET and includes a small COTS proof of concept.

Consequence: request/response/commit, NACK, two-hop avoidance, migration, and
dynamic frame size are prior art.  EXP21A was explicitly only an
Aydin-inspired projection and cannot serve as the required direct baseline.

### 2.2 D-ART and D-STR for periodic UAV safety broadcast

[Samandari's 2025 thesis](https://doi.org/10.26021/15895) and the
[D-STR preprint](https://arxiv.org/abs/2511.12888) are even closer to the
present traffic model.  They treat unacknowledged periodic local broadcast of
position/velocity safety beacons.

D-ART is the single-hop construction: one adapt slot plus beacon slots,
random self-allocation, a reception record piggybacked in later beacons,
collision-driven release, and superframe grow/shrink.  D-STR extends the same
idea to multi-hop spatial reuse.  It uses five management slots (`TG`, `TGn`,
`TS`, `TSo`, `TSn`), three-state reception records (nothing, decoded, energy
without decode), implicit reception evidence in later beacons, high-power
formation-wide grow/shrink signaling, and retention/reassignment rules.

Its important boundaries are equally explicit:

- rigid relative geometry and static neighborhoods;
- one first node, with simultaneous-first-node resolution out of scope;
- GPS time synchronization treated as solved;
- no external interference and a dedicated safety channel;
- high-power management messages assumed reachable formation-wide; and
- allocation can be temporarily accepted before an unheard neighbor later
  supplies contrary reception evidence.

Consequence: implicit reception records, energy-only NACK, self-allocation,
spatial reuse, and dynamic superframes are not new.  D-ART is the mandatory
single-hop prior-art baseline; D-STR is the mandatory hidden/multi-hop
reference if the branch remains positive.

### 2.3 Standard distributed schedule transactions

[RFC 8480 (6P)](https://datatracker.ietf.org/doc/html/rfc8480) defines
two-/three-step neighbor transactions for adding, deleting, and relocating
TSCH cells.  It specifies candidate cell lists, cell locking, transaction
timeouts, per-neighbor sequence numbers, duplicate handling, schedule
inconsistency detection, and clear/rebuild recovery.  It recommends dedicated
cells for 6P messages when available and permits shared cells otherwise.

[RFC 9033 (MSF)](https://www.rfc-editor.org/rfc/rfc9033.html) adds a shared
autonomous bootstrap path, negotiated cells, traffic-based cell adjustment,
and PDR-based collision detection followed by 6P relocation.  Its negotiated
cells are unicast and parent-oriented, not peer-broadcast swarm slots.

Consequence: transaction versioning, timeout, clear/rebuild, autonomous
fallback, PDR monitoring, and relocation are established mechanisms.  A new
method may adapt them to peer broadcast, but cannot claim the primitives.

### 2.4 Coalition and centralized hybrid UAV TDMA

[Song and Guo's DCFG-TDMA](https://doi.org/10.3390/e27030256) forms
noninterfering time coalitions and supports spatial reuse, but its protocol
uses a network header, periodic assignment broadcasts, three-hop neighbor
discovery, and a fixed 20% control-slot fraction.  It is distributed in the
coalition-game decisions but not leader-free in protocol operation.

[Xiao et al. (Scientific Reports 2025)](https://doi.org/10.1038/s41598-025-30533-0)
combine a CSMA request phase, leader-side centralized slot allocation, beacon
synchronization, queue/BER-aware retransmission reservations, and a TDMA data
phase.  This closes novelty for a generic CSMA-control/TDMA-data hybrid, but
not the leader-free peer-broadcast problem.

### 2.5 Control-aware allocation

[Chiariotti and Fabris (IFAC 2025)](https://doi.org/10.1016/j.ifacol.2025.12.071)
schedule first-order formation localization by maximum age, expected error,
or centrality-weighted value.  Their schedules are precomputable under ideal
localization opportunities and periodic synchronization beacons; all methods
consume the same resource count.  This occupies the broad claim of
AoI/VoI-aware formation scheduling.

The more recent
[control-certified wireless allocation preprint (2026)](https://arxiv.org/abs/2605.17791)
goes much further: a GCS/digital twin builds delay/reliability/interaction
certificates, tests stochastic Lyapunov drift, prunes a supply frontier, and
centrally packs actions under a TDMA budget in closed-loop ns-3 simulation.
Its network model assumes orthogonal collision-free TDMA patterns already
available to the allocator, with no spatial reuse.

Consequence: `control-certified`, Lyapunov-admitted, or VoI-aware TDMA is not a
defensible broad novelty label.  The residual question is below that
allocator: distributed acquisition and validity of peer-broadcast schedule
state under an imperfect control plane.

## 3. Residual gap after the update

The scoped gap that remains worth testing is:

> A causal, leader-free peer-broadcast scheduling protocol for non-rigid UAV
> swarm coordination that (i) executes on continuous local clocks with an
> explicit guard certificate, (ii) makes bootstrap/reservation/repair frames
> contend on the same interference graph, (iii) detects stale or inconsistent
> schedule state under lossy and hidden control visibility, (iv) provides
> bounded fallback/rejoin behavior, and (v) is evaluated by closed-loop
> freshness, formation safety, and fully charged airtime rather than only
> convergence, throughput, or access delay.

This is a scoped search conclusion, not a novelty claim.  The individual
ingredients are known.  A contribution would require a precise information
model and at least one nontrivial result that does not follow by merely
combining D-STR, 6P/MSF, and a guard interval.

Potentially defensible results are:

1. a schedule-validity condition joining temporal uncertainty and spatial
   conflict evidence, with a proof of collision freedom while valid;
2. a probabilistic bound on false-valid acceptance or recovery time under
   declared control-loss/visibility assumptions;
3. a causal fallback rule that limits closed-loop outage during schedule
   invalidity; and
4. a direct native-baseline result showing the gain survives D-ART/D-STR and
   centralized control-certified references at matched total airtime.

## 4. What cannot be claimed

The following labels are closed unless a materially different theorem is
proved:

- first distributed TDMA or self-stabilizing scheduler;
- first UAV slot self-allocation, migration, dynamic frame, or spatial reuse;
- first ACK/NACK- or reception-record-assisted schedule repair;
- first sequence/version-based schedule consistency mechanism;
- first AoI-, VoI-, error-, or control-aware formation scheduler;
- first hybrid CSMA/TDMA mechanism; or
- first control-certified wireless resource allocator for UAV swarms.

## 5. Mandatory baseline closure before a new candidate

The next experiment must be a mechanism/conformance study, not candidate
tuning.

1. Implement a native D-ART single-hop kernel from its state machine, adapt
   slot, reception record, collision threshold, growth, shrink, and retention
   rules.
2. Preserve an Aydin-style request/NACK/migration arm as a distinct family,
   but do not label the existing EXP21A projection as the published protocol.
3. Include a 6P/MSF-inspired transactional reference with shared-bootstrap
   contention, version/sequence consistency, timeout, and clear/rebuild.
4. Charge every beacon, record bit, management message, retry, guard, and
   collision on one event timeline.
5. Validate exact zero-loss/synchronized behavior before introducing loss,
   hidden visibility, clock uncertainty, and churn.
6. Only if prior art leaves a reproducible robustness/control gap may a new
   schedule-validity/fallback method be designed.

## 6. EXP21D decision

EXP21D is opened as **prior-art distributed-MAC closure** with two stages:

- EXP21D-K: isolated protocol-kernel conformance and collision accounting;
- EXP21D-CL: closed-loop comparison only after every kernel gate passes.

No fresh-seed confirmation or submission claim is authorized by EXP21D.  A
positive result only establishes whether a new candidate is scientifically
necessary and which exact failure mechanism it must address.
