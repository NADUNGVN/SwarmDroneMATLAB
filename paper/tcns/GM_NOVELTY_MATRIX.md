# GM related-work and novelty matrix

This matrix replaces a paper-by-paper list with four connected research
threads.  The verified positioning is deliberately narrower than “first
information-aware communication method.”

| Thread / representative work | What the thread establishes | Information/value limitation left open for this paper | Relation to this work |
|---|---|---|---|
| Event-triggered distributed control: Tabuada (2007); Dimarogonas et al. (2012); Wang and Lemmon (2011) | State/error events can reduce communication while preserving stability/performance under declared models. | Trigger statistics are assumed available; exact marginal action value need not be locally observable. | We do not propose another trigger; the failed bound trigger illustrates why a safe error certificate need not rank actions economically. |
| Lossy formation/event control: Garcia et al. (2016); Dolk and Heemels (2017); Viel et al. (2022) | Loss, delay, ACK/no-ACK uncertainty, and multi-hypothesis receiver estimates can be included in stability-oriented designs. | A calibrated receiver-memory belief does not necessarily reveal the rest of the closed-loop baseline appearing in exact action value. | Viel et al. is the closest architectural threat and prevents novelty claims based on no-ACK receiver hypotheses. |
| AoI and goal-oriented freshness: Yates et al. (2021); Rajaraman et al. (2021); Maatouk et al. (2020) | Freshness/incorrectness can refine packet timeliness beyond raw rate. | Freshness is not in general a sufficient statistic for finite-horizon closed-loop marginal benefit. | AoI is background, not the central novelty or proposed metric. |
| Control VoI: Soleymani et al. (2023); Chiariotti and Fabris (2025) | Marginal control benefit and resource-aware scheduling can be derived under specified centralized/signaling information structures. | Whether the value statistic itself is identifiable under a given distributed sender information map is usually taken as part of the model. | We study the precondition for exact value-based decisions, not a new VoI optimizer. |
| Finite-horizon ACK-based scheduling: Yang et al., YAC (2026), DOI 10.1109/YAC71005.2026.11615444 | ACK-derived error covariance can form a fully observed MDP state for finite-horizon scheduling under drops. | Does not test whether a fixed-response closed-loop action functional lies in a distributed sender's linear information space. | Reinforces that useful Bayesian/MDP decisions need not observe the realized clairvoyant value; our exact-identifiability scope is narrower. |
| Multi-agent goal-oriented communication overview: Charalambous et al., IEEE OJCOMS (2026), DOI 10.1109/OJCOMS.2026.3703748 | Organizes task-relevant communication for multi-agent coordination across communications, control, and learning. | A broad taxonomy, not an exact action-functional reconstructibility or missing-statistic theorem. | Confirms the importance of task value while preventing claims that goal-oriented multi-agent communication itself is new. |
| Discrete MARL return-gap communication: Chen, Lan, and Joe-Wong, AAAI (2024), DOI 10.1609/aaai.v38i16.29680 | Bounds expected return loss versus full observability and learns discrete message labels by clustering local observations using joint action-value vectors. | Does not give deterministic affine row-space identifiability, local interval minimax regret, or minimum instantaneous linear-statistic dimension. | Closest partial-information/action-value regret neighbor outside classical control; it is now distinguished explicitly in Related Work. |
| Decentralized information structures: Witsenhausen (1971); Ho and Chu (1972); Nayyar et al. (2013) | Decisions depend fundamentally on who knows what and when; common-information formulations can solve specified stochastic team models. | They do not instantiate the exact formation communication-action statistic or its acquisition-price test. | Supplies the correct conceptual language and prevents claims of a new general decentralized-information principle. |
| Functional observability: Fernando et al. (2010); Montanari et al. (2022) | A target linear functional is recoverable without full-state observability; row-space tests, target estimation, sensor placement, and functional-observer construction are established. | These works do not make a communication action's marginal closed-loop value the target or quantify the local decision regret caused by its hidden component. | Theorem 1 is an application/specialization. Its iff condition is not claimed as new. |
| Modal/structural functional observability and sensor placement: Zhang, Fernando, and Darouach, IEEE TAC (2025), DOI 10.1109/TAC.2024.3462558 | New modal and structural characterizations; minimum sensor placement from a prior set is NP-hard; greedy approximation and special-case constructive solutions are supplied. | Sensor selection asks how to make a target functional observable; it does not distinguish the algebraic dimension of simultaneous communication-action values from the packet/coalition cost of assembling them at one decision instant. | It already implies that the manuscript's generic coalition search is a functional-sensor-selection instance. We claim neither a new sensor-placement problem nor algorithm. |
| Sample-based functional observability: Krauss, Lopez, and Mueller, IEEE L-CSS (2025), DOI 10.1109/LCSYS.2025.3582512 | Necessary and sufficient functional-observability conditions with infrequent/irregular samples and conditions on sampling schemes. | Does not formulate local minimax communication-action regret or the present distributed formation information ownership/economics. | Our finite-history theorem is standard sampled functional observability specialized to the propagated action-value coefficient; sampling/history alone is not novelty. |
| Functional observer design: Darouach and Fernando, Automatica (2025), DOI 10.1016/j.automatica.2025.112115 | Algebraic functional-observability conditions and reduced-order functional observers with general feasible orders and pole placement. | Observer dynamics/order answer how to asymptotically estimate a functional, not how many instantaneous linear side statistics are algebraically missing at a communication decision. | Our $r_\star$ is not minimum functional-observer order and creates no observer. |
| Recent structural refinements: Zhang et al., Automatica (2025), DOI 10.1016/j.automatica.2025.112232; Commault, Systems & Control Letters (2026), DOI 10.1016/j.sysconle.2026.106503 | Efficient structural functional-observability/output-controllability tests and minimal placements for generically diagonalizable systems; fixed-observable-set characterization via structural duality. | These generic-structure results do not supply action-value-specific regret or communication acquisition price. | They further preclude generic structural-observability or coalition novelty claims. Our N=5 coalition result is only an instantiated ownership/economics result. |
| Target-control/observation duality: Montanari, Duan, and Motter, IEEE TAC (2025) | Weak/strong duality between output controllability and functional observability and a target-controller/functional-observer separation result. | Does not study a binary communication decision whose exact marginal benefit is hidden at the transmitter. | Reinforces that target-functional system theory is mature; our contribution is the communication-decision consequence. |
| Networked-control information limits: Tatikonda and Mitter (2004); Nair et al. (2007); Franceschetti et al. (2023) | Data rate, causality, and information availability constrain stabilization and estimation. | A link-action-specific functional may be one-dimensional yet globally owned and uneconomic to acquire. | Our contribution is a finite-horizon, action-specific co-design diagnostic, not a new data-rate theorem. |
| Feedback economics: Munari and Badia (2025) | Feedback can materially alter communication efficiency and AoI conclusions. | Does not connect feedback cost to exact distributed formation-action-value identifiability. | We apply a frozen break-even accounting condition to the required information. |

## Defensible differentiator

Prior work predominantly designs a controller or scheduler under a declared
information structure.  This work asks a prior question: whether the exact
finite-horizon control value used to decide a communication action is itself
identifiable from that structure.  It connects (i) the exact quadratic
action-value functional, (ii) a quantitative value-information radius and
strictly positive local minimax communication-decision regret, (iii) the
minimum simultaneous-action statistic dimension and sender-specific
compression, and (iv) coalition ownership and measured acquisition price.

## Novelty threats that remain

1. The exact-value and finite-history iff tests are directly implied by
   functional and sample-based functional observability.  The paper must
   foreground the minimax value/regret bounds, simultaneous-action dimension,
   acquisition economics, and physically reachable counterexample.
2. The 2025--2026 structural literature already covers functional sensor
   placement and efficient special cases.  We claim only action-value
   ownership in the N=5 case, not a new generic combinatorial problem.
3. VoI literature already establishes marginal control value and optimal
   threshold structures under other information models.  “First VoI” and
   “optimal scheduler” are forbidden.
4. Viel et al. already covers ACK-free receiver-state hypotheses in formation
   control.  Receiver-memory belief is motivating evidence, not a
   contribution of the final paper.
5. Minimum functional-observer order and $r_\star$ answer different questions.
   Any wording that calls $r_\star$ an observer order or a data-rate lower bound
   is incorrect.
6. A public, unarchived 2026 working manuscript in the
   ahb-sjsu/geometric-observation repository combines functional-observability
   terminology with consumer-relative value of observation. Its stated
   contribution is consumer-induced covariance geometry and query-only
   recovery, not distributed exact action-value identifiability, compatible-set
   minimax regret, or the rank of missing instantaneous action statistics. It
   is terminology-adjacent but not a direct theorem collision; because it is
   not an archival source, it is recorded in the SQ audit rather than cited as
   established literature.
