# Post-EXP19 literature and mechanism audit

**Audience:** internal research team preparing an IEEE Internet of Things
Journal / communication-venue contribution

**Audit date:** 2026-08-31

**Decision:** whether to open EXP20 around a causal, implementable
contention-to-scheduled access mechanism for UAV swarm coordination

## Direct answer

Do **not** open EXP20 under the current broad framing.

The literature now occupies each generic component of that framing:

1. contention-aware CSMA/TDMA hybridization and load-based mode changes;
2. decentralized, demand-aware, and flight-aware dynamic TDMA for UAV
   swarms;
3. event/error/age/semantic-aware access over a shared medium; and
4. ACK-derived distributed beliefs for goal-oriented random access.

The fourth point is decisive. Chiariotti et al.'s DELTA protocol, published
in IEEE Transactions on Networking in 2026, uses ACK/NACK observations to
maintain distributed beliefs about other sensors' semantic freshness, resolves
collisions, treats imperfect feedback, and benchmarks both random access and
scheduled policies. A second 2025 preprint develops a general distributed
Goal-oriented Medium Access formulation with Value of Information,
transmission cost, game-theoretic threshold policies, and bandit learning.
Therefore, neither "semantic distributed MAC" nor "ACK-belief-assisted
semantic access" is defensible as a broad novelty claim.

There is a narrower, conditional research gap:

> Distributed broadcast medium access for continuous-state multi-agent
> control under delayed, lossy, non-FIFO, private per-receiver feedback,
> without a common gateway or public ACK/NACK, with all coordination overhead
> charged and with closed-loop safety/control outcomes.

The audit did not identify a prior work covering that full information
structure. This is a scoped search result, not a priority claim. It is also not
yet a contribution: EXP19A found that access scheduling creates headroom, but
the semantic max-weight increment did not clear the registered promotion gates
and a periodic-TDMA point reproduced a major gain.

The next executable study should therefore be a prior-art baseline closure and
information-structure falsification study, not a new optimized candidate.

## Scope and assumptions

The audit asks a mechanism question, not whether any paper uses the words UAV,
AoI, ACK, or TDMA. Each work was classified by:

- access family and whether mode switching or slot reassignment is dynamic;
- centralized, decentralized, or common-gateway coordination;
- the local signal that drives access: traffic queue, collision/load,
  kinematics, estimation/control error, AoI/AoII, or generic VoI;
- whether feedback is public or private, immediate or delayed, and
  single-receiver or multi-receiver;
- whether scheduling/control overhead is modeled;
- whether evaluation closes the physical control loop; and
- whether simulation, radio testbed, or flight hardware is provided.

The time boundary is foundational work through 2026-08-31. Primary papers,
publisher records, author/institutional manuscripts, and the current project's
registered evidence were used. Surveys were used only for discovery. The
search stopped after the major claim families had primary support and targeted
queries for continuous-state, multi-receiver, private delayed ACK scheduling
returned no exact match; additional generic TDMA or AoI papers would not alter
the decision.

## Evidence by research lineage

### 1. Hybrid contention and scheduled access is established

Z-MAC combines CSMA and TDMA behavior, uses a distributed slot assignment,
gives slot owners priority, and changes behavior with contention level. It was
implemented in TinyOS and evaluated on sensor motes. The later adaptive
IEEE 802.15.4 hybrid MAC explicitly partitions contention access between
slotted CSMA/CA and TDMA according to queue state and detected collisions.
Thus, "switch from contention to scheduled access using local load/service
observations" is not novel by itself.

The overlap is even closer in a UAV context. Xiao et al. use a CSMA request
phase, centralized queue- and BER-aware time-slot allocation, and a TDMA data
phase for UAV formations, with semi-physical validation. This does not solve
the distributed multi-receiver problem, but it removes novelty from a generic
hybrid CSMA/TDMA UAV formulation.

Primary evidence:

- [Rhee et al., Z-MAC, IEEE/ACM Transactions on Networking](https://ieeexplore.ieee.org/document/4453818/)
- [Gilani et al., adaptive CSMA/TDMA hybrid MAC](https://www.sciencedirect.com/science/article/pii/S1570870511000175)
- [Xiao et al., dynamic slot allocation for UAV formation](https://www.nature.com/articles/s41598-025-30533-0)

### 2. Dynamic and decentralized UAV TDMA is established

Azem, Tahir, and Koeppl's DTSA is a non-periodic decentralized slot-selection
policy for quadcopter swarms. Nodes estimate other agents' states and compute
priority from relative position/velocity and collision-relevant geometry;
inactive or destination-reached agents relinquish demand. It was compared to
periodic TDMA in simulation and on real Crazyflie quadcopters. This work
directly prevents a novelty claim for "flight-aware decentralized dynamic TDMA
for UAV swarms."

Aydin et al. add self-organizing distributed slot assignment, two-hop slot
reuse, slot migration using positive/negative acknowledgement control
messages, demand-driven extra slots, frame doubling, entry/exit/recovery, and
explicit control-traffic evaluation. Their 2024 IEEE Access article includes
OMNeT++/INET evaluation and a COTS proof of concept. Samandari's 2025 thesis
and D-STR preprint further cover distributed self-allocation, dynamic
superframe size, and spatial reuse for rigid UAV formations.

Primary evidence:

- [Azem et al., DTSA](https://ar5iv.labs.arxiv.org/html/2202.00919)
- [Aydin et al., distributed TDMA for aerial swarms](https://napier-repository.worktribe.com/output/3595870/distributed-tdma-scheduling-for-autonomous-aerial-swarms-a-self-organizing-approach)
- [Samandari, 2025 PhD thesis](https://ir.canterbury.ac.nz/items/b5f2aa71-ddb3-4a38-840c-b7f7ec2a6775)
- [Samandari et al., D-STR preprint](https://arxiv.org/abs/2511.12888)

### 3. Event/control-error-aware shared-resource scheduling is established

Cervin and Henningsson compared time-triggered and event-triggered loops under
TDMA, FDMA, and several CSMA priority rules. Mamduhi et al. later proposed an
error-dependent scheduler for multiple heterogeneous LTI loops sharing a
constrained channel and provided stochastic-stability and performance bounds.
Consequently, state/error prioritization at a shared channel is established;
the novelty must lie in a different information structure or guarantee.

Primary evidence:

- [Cervin and Henningsson, shared-network event-triggered control](https://lup.lub.lu.se/search/publication/1445340)
- [Mamduhi et al., error-dependent data scheduling](https://www.sciencedirect.com/science/article/pii/S0005109817301279)

### 4. Distributed age/semantic random access is established

Chen et al. define packet age-gain and propose decentralized age-based
thinning for random access, including adaptive thresholds based on collision
feedback and extensions beyond Slotted ALOHA. Nayak et al. provide a
decentralized AoII policy under Slotted ALOHA. Tahir et al. address multiple
agents that share capacity-limited non-FIFO duplex channels and use a particle
filter to maintain beliefs over receiver AoI under random feedback delays.
These works remove novelty from decentralized AoI thresholds, semantic random
access, and delayed-feedback receiver-age belief individually.

Primary evidence:

- [Chen et al., IEEE Transactions on Information Theory 2022](https://ora.ox.ac.uk/objects/uuid%3Ab5c1cebe-9ad7-400c-a48d-aa4e0ff82d4f)
- [Nayak et al., ICC 2023](https://doi.org/10.1109/ICC45041.2023.10279616)
- [Tahir et al., IFIP Networking 2024](https://arxiv.org/abs/2312.12977)

### 5. ACK-belief-assisted goal-oriented MAC is now direct prior art

DELTA is the closest newly identified neighbor. It uses a public TDD feedback
phase: a successful uplink yields an ACK identifying the transmitter; a
collision or erasure yields a NACK. Nodes infer others' AoI and maintain a
belief/upper bound on their AoII. The protocol has zero-wait, collision
resolution, collision exit, and belief-threshold phases, analyzes common
knowledge, evaluates noisy/erased/deleted feedback, and compares Round-Robin,
Maximum-Age-First, and three random-access policies. Its model is binary
anomaly reporting to a common gateway with slot-synchronous public feedback,
not continuous-state peer-to-peer formation control.

The LIBRA/BETA preprint is broader in semantic scope: nodes observe local VoI,
share a collision channel, and learn distributed threshold policies with
limited feedback and no prior VoI distribution. It currently remains a
preprint, but it materially increases novelty risk for any generic
"distributed semantic MAC" claim.

Primary evidence:

- [Chiariotti et al., DELTA, IEEE Transactions on Networking 2026](https://www.research.unipd.it/retrieve/bd3d2509-7171-4b37-82db-5fc8c770de9f/Goal-Oriented_Medium_Access_With_Distributed_Belief_Processing.pdf)
- [Chiariotti and Zanella, GoMA/LIBRA/BETA preprint](https://arxiv.org/pdf/2508.19141)

### 6. Distributed reservation and self-stabilization are established

Distributed collision-free TDMA, reservation handshakes, and self-stabilizing
slot allocation under dynamic topology have long histories. Leone and
Schiller provide a self-stabilizing TDMA algorithm with convergence analysis;
DATP constructs collision-free schedules through distributed contention and
empirical interference tests; Aydin et al. provide UAV-specific migration and
recovery. Therefore, self-stabilization, distributed reservation, or dynamic
frame sizing cannot independently support novelty.

Primary evidence:

- [Leone and Schiller, self-stabilizing TDMA](https://journals.sagepub.com/doi/10.1155/2013/639761)
- [DATP, event-triggered distributed TDMA](https://www.sciencedirect.com/science/article/abs/pii/S0140366411001678)

## Reconciliation with EXP19A

EXP19A found real access-layer headroom: collision-free round-robin scheduling
strongly improved RMSE and offered utilization over frame-piggyback at the N=5
boundaries and repaired N=10 safety failures. However:

- the two semantic oracle schedulers did not pass the registered promotion
  rule;
- the N=10 failure repair came with an offered-load increase;
- periodic TDMA reproduced a major improvement and dominated the urgency
  oracle at the registered N=5 Stressed boundary; and
- the semantic increment over collision-free round-robin was much smaller than
  the access-mode increment.

The literature and the experiment point in the same direction. The available
gain is primarily collision removal/service regularization, while generic
semantic scheduling is already occupied and did not show independent headroom
in the current system.

## Residual gap and why it is different

The only gap worth testing is the information asymmetry created by peer
broadcast and private delayed acknowledgements. It differs from the closest
works as follows:

| Dimension | DELTA / common-gateway GoMA | Tahir partial-observability | Current residual question |
|---|---|---|---|
| receiver structure | one common gateway | one common receiver | multiple peer receivers per broadcast |
| feedback visibility | public ACK/NACK outcome | agent-specific delayed feedback | private, delayed, lossy per-neighbor cumulative ACK |
| timing | slotted, feedback in each round | random non-FIFO duplex delay | multi-slot data/ACK queues and asynchronous delivery |
| semantic state | binary anomaly/AoII or generic iid VoI | AoI | continuous kinematic innovation plus per-neighbor freshness |
| knowledge | public feedback supports common knowledge | particle belief over receiver AoI | heterogeneous local filtrations; no common receiver truth |
| outcome | AoII/reward | AoI | closed-loop formation error, safety, and charged airtime |

This distinction is meaningful because DELTA's coordination proof explicitly
uses public announcements to keep protocol phase and belief bounds common
knowledge. Private delayed per-neighbor ACKs can create inconsistent beliefs
and split-brain reservations. Existing self-stabilizing TDMA solves generic
allocation faults, but it does not assign access according to continuous
control semantics under this feedback structure.

The gap is nevertheless conditional. A publishable contribution would need
more than combining existing blocks. It should produce at least one of:

1. an impossibility or lower-bound result showing what cannot be coordinated
   from private delayed ACKs without extra signaling;
2. a self-stabilizing reservation/access protocol with a stated information
   filtration and a convergence/service guarantee under bounded feedback
   asymmetry; or
3. a closed-loop guarantee linking the resulting service process to formation
   error/safety, followed by hardware or trace-based validation.

## Recommended next study: EXP20A baseline closure

Do not optimize a new policy yet. Freeze a baseline-closure study whose purpose
is to try to falsify the residual gap.

### Mandatory arms

1. current frame-aware Causal-v3/piggyback route;
2. periodic TDMA frontier already used in EXP19A;
3. a faithful DTSA next-sender baseline using the paper's kinematic priority,
   potential-sender set, age counter, and no-ACK assumption;
4. DELTA under its native public-feedback/common-gateway assumptions as an
   optimistic semantic-MAC reference;
5. DELTA with feedback projected onto the project's delayed private
   per-neighbor observation structure;
6. Chen-style age-gain thinning over the existing random-access channel;
7. a Z-MAC-like contention-level/slot-owner hybrid access baseline; and
8. collision-free round-robin plus the EXP19A semantic oracle references.

Aydin's full STDMA is a required second-stage baseline if the initial
single-hop screen is positive. Its entry/migration/frame-resize control plane
is too substantial to replace with a label on round-robin.

### Primary diagnostic contrasts

- public-feedback DELTA versus private-delayed-feedback DELTA isolates the
  price of lost common knowledge;
- DTSA versus periodic TDMA isolates flight-aware dynamic allocation;
- age-gain thinning versus current Causal-v3 isolates generic AoI gain from
  continuous-state/ACK semantics;
- Z-MAC-like hybrid versus collision-free round-robin isolates generic access
  switching from a new semantic mechanism; and
- every scheme must charge synchronization, feedback, reservation, and
  schedule-control traffic under the same airtime accounting.

### Stop/go rule before a new candidate

Stop the access-scheduling branch if either condition holds:

1. periodic TDMA or DTSA explains the closed-loop frontier across the
   registered boundaries; or
2. DELTA/age-gain baselines match the current mechanism once the same feedback
   information is provided.

Only open a new candidate if all of the following are observed:

1. public-feedback semantic MAC loses a material amount of performance when
   projected onto delayed private multi-receiver feedback;
2. the current ACK-confirmed semantic memory retains a reproducible advantage
   in that projection;
3. periodic TDMA/DTSA cannot reproduce the advantage at matched total airtime;
4. the effect is visible in control/safety outcomes, not only AoI; and
5. the result survives charged control-plane overhead.

No confirmatory holdout should be opened until these development gates pass.

## Publication and hardware implication

For an IoT-J/communication submission, hardware becomes effectively mandatory
if this branch survives. The nearest UAV-TDMA works already include Crazyflie
or COTS proof-of-concept evidence, and Xiao et al. include semi-physical
validation. A simulation-only incremental combination would be weak against
that record. Hardware should still wait until EXP20A and the theory gate are
positive.

## Bibliographic integrity finding

The current `munari2025feedback` entry in `paper/references.bib` assigns DOI
`10.1109/TCOMM.2025.3548035`. That DOI belongs to *Timely Status Updates in
Slotted ALOHA Networks With Energy Harvesting*, not the Munari--Badia feedback
paper. Crossref returns `10.1109/TCOMM.2025.3583639` for *What's My Age of
Information Again? The Role of Feedback in AoI Optimization Under Limited
Transmission Opportunities*. This audit records the correction but does not
edit the manuscript bibliography under the research-first rule.

Verification links:

- [correct Munari--Badia DOI](https://doi.org/10.1109/TCOMM.2025.3583639)
- [DLR record for the paper currently reached by the incorrect DOI](https://elib.dlr.de/213518/)

## Final verdict

`DO_NOT_OPEN_EXP20_AS_CURRENTLY_FRAMED`.

The scientific next step is `EXP20A_PRIOR_ART_BASELINE_CLOSURE`, followed only
if positive by a theory-first protocol centered on private delayed
multi-receiver feedback. The broad hybrid/dynamic-TDMA/semantic-MAC story is
closed by prior art and by EXP19A's own negative semantic-promotion result.
