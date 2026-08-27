# Related-work matrix

The mapping from each verified reference to (a) the statement it supports
in the manuscript, and (b) what our work does differently. Section 2 of
the manuscript is written **from this matrix**, so every "however" in the
prose has a row here behind it.

Rule enforced throughout: a reference appears against a claim only if it
actually supports that claim. Where a body of work contains exceptions to
a generalisation we might want to make, the exception is recorded and the
generalisation is weakened in the prose.

---

## 2.1 Event-triggered multi-agent communication

| Reference | Supports | Our difference |
|---|---|---|
| `astrom2002riemann` | Event-based sampling can beat periodic sampling at equal average rate | We compare against periodic at *matched conditions* rather than matched rate, and report both |
| `tabuada2007event` | The canonical state-error trigger, and the need for a minimum inter-event time | Our Branch 1 is exactly this trigger; we keep the refractory bound and add three more branches |
| `heemels2012introduction` | Standard taxonomy: event-triggered vs self-triggered | We are event-triggered, evaluated once per outer step |
| `dimarogonas2012distributed` | Distributed event-triggered control using **local** state error | Our trigger additionally reads an estimate of what the *receiver* holds — a quantity a purely local trigger cannot access |
| `seyboth2013eventbased` | Event-based broadcasting cuts inter-agent traffic in consensus; broadcast counting | Their threshold decays with *time*; ours scales with *estimated receiver age*. We also price the reverse channel, which they have none of |
| `girard2015dynamic` | Dynamic, not static, trigger thresholds are established | Their auxiliary variable is internal; our modulating signal is ACK-derived and refers to another agent's state of knowledge |
| `yi2017distributed` | Dynamic triggering works in the distributed multi-agent case | Same distinction as above |
| `nowzari2019eventtriggered` | Survey of the field; documents that freshness is not a standard ingredient | We add the freshness ingredient causally |
| `chen2020howoften`, `ge2021dynamic`, `zhang2025overview` | Current state and taxonomy of triggering techniques | Positions our branch structure inside an established design space |
| `yin2023eventbased`, `ji2023dynamic`, `chen2024distributed`, `yang2025fencing` | **Event-triggered communication has already been applied to multi-UAV formation control**, including with delay, disturbances, connectivity and collision constraints | **This is the exception that forbids the easy claim.** We must not say event-triggered UAV formation control is unexplored. Our difference is the freshness term and the reverse channel, not the application |

**Prose consequence.** Section 2.1 may say that conventional
event-triggered multi-agent designs trigger on locally measurable error
and do not model what the receiver holds. It may **not** say that
event-triggered communication has not been applied to UAV formations.

## 2.2 AoI and information freshness in networked control

| Reference | Supports | Our difference |
|---|---|---|
| `kaul2012realtime` | AoI as a freshness metric distinct from throughput | We use freshness to *modulate a threshold*, not as an objective |
| `sun2017update` | Optimising freshness is not "transmit as often as possible" | Consistent with our finding that the oracle transmits *less* |
| `yates2021aoisurvey`, `yang2025aoiperspective`, `kaswan2025gossip` | AoI is a mature, surveyed area including multi-node dissemination | We do not contribute to AoI theory; we consume it |
| `ayan2019aoivoi` | **Age alone is a poor proxy for control cost**; value-of-information is an established alternative | Directly supports our design choice that age never triggers alone. Their solution is a centralised scheduler; ours is a distributed sender rule |
| `rajaraman2021notjustage` | Combining age with a content/quality term is already done | Our innovation-times-age composition is *not* the first move beyond pure age; the difference is the setting and the causal ACK-derived age |
| `mamduhi2020freshness` | AoI and event-based triggering have been co-designed | **Nearest neighbour.** Theirs is a network scheduler across independent control loops; there is no per-sender ACK-confirmed freshness memory and no new-information/refresh split |

**Prose consequence.** Section 2.2 may say that AoI-aware designs
typically assume the age at the receiver is known to whoever makes the
transmission decision, and that this is what we remove. It may **not**
say that nobody has combined AoI with event-based triggering.

## 2.3 Feedback- and ACK-aware communication and scheduling

| Reference | Supports | Our difference |
|---|---|---|
| `ceran2019average` | **ACK/NACK feedback already drives AoI-optimal transmission without oracle knowledge**, with HARQ | The closest precedent for our E1. Single source-destination link, no state innovation, no multi-agent control loop. Also: their retransmission is explicit HARQ; we introduce no retransmission timer at all |
| `tang2022whittle` | Index-based centralised AoI scheduling | Contrast class: centralised and periodic-evaluation, versus our distributed event trigger |
| `park2018wireless`, `gatsis2014optimal` | Radio resources are a first-class design variable in wireless control | Motivates pricing the reverse channel, which we do under five cost models |
| `walsh2002stability`, `hespanha2007survey` | Delay and dropout affect closed-loop stability | Our network model includes loss, delay, jitter and out-of-order delivery |
| `li2026impulsive` | Event-triggered mechanisms remain actively surveyed | Currency of the problem area |

**Prose consequence.** Section 2.3 may say that ACK-driven freshness
estimation is established in the AoI-scheduling literature and that we
import it into distributed multi-agent triggering. It may **not** claim
ACK-based causal freshness estimation as novel in itself.

## 2.4 UAV-swarm communication and control co-design

| Reference | Supports | Our difference |
|---|---|---|
| `gupta2016survey`, `zeng2016wireless`, `mozaffari2019tutorial`, `zeng2019accessing` | UAV links are bandwidth-, airtime- and reliability-constrained | Motivates the objective. Cited for constraints only, never for triggering |
| `campion2019uavswarm` | Swarm communication architectures degrade with neighbour count | Motivates our N = 5/20/50 scaling study |
| `amodu2023aoiuav` | AoI is actively used as a design objective in UAV networking | Establishes that our metric choice is field-appropriate |
| `tripathi2023wiswarm` | **AoI-based networking has been demonstrated on real multi-UAV hardware** | Nearest neighbour on the application side, and the honest benchmark for our lack of hardware. Theirs is a centralised scheduler; ours is a distributed trigger |
| `tatikonda2004control`, `nair2007feedback` | Communication constraints fundamentally limit control performance | Framing for the trade-off |
| `molin2013optimality`, `ramesh2013design` | Joint controller/trigger and state-based scheduler design is studied | We deliberately do **not** co-design: the controller is frozen, which is why several of our failures are attributed to it |
| `demirel2017tradeoff` | The communication-versus-control-cost trade-off is explicitly studied | Supports reporting cost under multiple models rather than one |
| `olfatisaber2006flocking`, `oh2015survey` | Consensus-style neighbour interaction is the standard formation mechanism | Our formation law is standard by choice, so that the communication policy is the only variable |
| `lee2010geometric`, `mellinger2011minimum` | Cascaded/geometric quadrotor control and the acceleration-to-attitude mapping | Basis of our 6-DOF follower model |
| `vasarhelyi2018optimized`, `zhou2022swarm` | Real aerial swarms fly, and are communication-limited in practice | The standard against which a simulation-only result must be positioned |

**Prose consequence.** Section 2.4 may say that UAV-swarm work motivates
traffic reduction and that AoI-based networking has reached hardware. It
must state that our work has **not**.

## 2.5 Gap addressed by this work

The gap must emerge from the rows above, not from assertion. Reading down
the columns:

1. Event-triggered multi-agent designs, including recent UAV-formation
   ones, trigger on locally measurable state error and do not model
   receiver staleness (2.1).
2. AoI-aware control designs do model staleness, but typically place the
   decision in a scheduler that is assumed to know the age, and address
   multi-loop or single-loop settings rather than a formation (2.2).
3. ACK-driven causal freshness estimation exists, in single-link
   AoI-optimal scheduling, without a state-innovation trigger (2.3).
4. UAV-swarm work supplies the constraints, and one line of it has reached
   hardware with a *centralised* AoI scheduler (2.4).

The combination that remains — a **distributed sender** in a formation
that estimates its own receiver's freshness **only from cumulative
acknowledgements**, uses that estimate to modulate a **state-innovation**
threshold, and separates **new information from refresh** so that a
repetition cooldown governs only repetition — is what this paper
addresses. The evidence for that gap, and the limits of the search behind
it, are in `NOVELTY_GAP_REVIEW.md`.
