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
| Decentralized information structures: Witsenhausen (1971); Ho and Chu (1972); Nayyar et al. (2013) | Decisions depend fundamentally on who knows what and when; common-information formulations can solve specified stochastic team models. | They do not instantiate the exact formation communication-action statistic or its acquisition-price test. | Supplies the correct conceptual language and prevents claims of a new general decentralized-information principle. |
| Functional observability: Fernando et al. (2010); Montanari et al. (2022) | A target linear functional is recoverable iff it lies in the appropriate observation/observability row space; target-sensor design is established. | Communication-action values, their sign decision, and the difference between statistic dimension and network acquisition cost are not developed for the present formation architecture. | Our row-space theorem is an application/specialization. Novelty cannot rest on the iff condition alone. |
| Networked-control information limits: Tatikonda and Mitter (2004); Nair et al. (2007); Franceschetti et al. (2023) | Data rate, causality, and information availability constrain stabilization and estimation. | A link-action-specific functional may be one-dimensional yet globally owned and uneconomic to acquire. | Our contribution is a finite-horizon, action-specific co-design diagnostic, not a new data-rate theorem. |
| Feedback economics: Munari and Badia (2025) | Feedback can materially alter communication efficiency and AoI conclusions. | Does not connect feedback cost to exact distributed formation-action-value identifiability. | We apply a frozen break-even accounting condition to the required information. |

## Defensible differentiator

Prior work predominantly designs a controller or scheduler under a declared
information structure.  This work asks a prior question: whether the exact
finite-horizon control value used to decide a communication action is itself
identifiable from that structure.  It connects (i) the exact quadratic
action-value functional, (ii) value-sign ambiguity, (iii) minimum additional
linear-statistic dimension and coalition ownership, and (iv) the measured
communication price of acquiring the missing information.

## Novelty threats that remain

1. A reviewer may view the central mathematics as a straightforward
   functional-observability application.  The paper must foreground the
   sign-decision and acquisition-economics consequences and the physically
   reachable counterexample.
2. Functional sensor-placement literature overlaps the coalition problem.
   We claim only the action-value instantiation and N=5 result, not a new
   generic combinatorial algorithm.
3. VoI literature already establishes marginal control value and optimal
   threshold structures under other information models.  “First VoI” and
   “optimal scheduler” are forbidden.
4. Viel et al. already covers ACK-free receiver-state hypotheses in formation
   control.  Receiver-memory belief is motivating evidence, not a
   contribution of the final paper.

