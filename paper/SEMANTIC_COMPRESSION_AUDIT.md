# Semantic compression audit

## Scope and verdict

This audit compares the scientific-content baseline `ff4065c5` with the
TCNS candidate based on `0dc4b8f0`. It is a semantic comparison, not a line
count: each retained claim is checked for its mechanism, evidence, unit,
caveat, and intended scope.

**Verdict: PASS after wording-only repairs.** The 15 protected scientific
points and all accepted negative results remain in the main manuscript. The
compression did not reverse a scientific conclusion or remove a claim's sole
evidence. Seventeen logical or interpretive gaps were found and repaired in
this batch; no result, algorithm, parameter, or scientific source was changed.

## End-to-end reviewer read

| Section | Reviewer question | Initial finding | Repair / final finding |
|---|---|---|---|
| Introduction | Is the problem clear and does the contribution follow? | PASS. Sender knowledge under delayed/lost DATA and ACKs motivates causal freshness and dual memory. | No repair required. Mechanistic adaptivity remains distinct from Pareto dominance. |
| Related Work | Is the gap cautious and supported? | PASS. Five literature streams and seven near neighbors remain, using “We did not identify.” | No priority claim or unsupported absence claim was introduced. |
| Problem formulation | Are symbols and cost conventions defined before use? | `\sigma_j` and the broadcast proxy's status were too implicit. | Defined jitter standard deviation and stated that broadcast accounting is not a MAC/contention/delivery simulation. |
| Method | Can the algorithm be followed without development history? | ACK sequence fields and the operational meaning of “distributed” were underdefined. | Defined ACK tuple/sequence state, named trigger parameters before the branches, and made the causal-feedback requirement explicit. |
| Experimental setup | Are baselines, pairing, parameters, and conventions reproducible enough? | Several definitions were compressed out; the text also incorrectly called the intervals bootstrap intervals. | Restored fixed-periodic/state-event/reference definitions, locked nominal parameters, common-random-number pairing, matched-pair Student-`t` intervals, graph/rate conventions, and fault eligibility. |
| Results | Is each claim adjacent to evidence and are negative results visible? | Core evidence survived, but reverse-ACK saturation had lost its numerical bridge and several captions permitted unit/model ambiguity. | Added persisted macro values for the saturation explanation and strengthened all affected captions. Table VI remains in the main paper. |
| Discussion | Does it separate mechanism from mission-level performance? | PASS. The P12.5 counterexample, ACK pricing, and accounting dependence remain explicit. | No new performance claim added. |
| Limitations | Are the bounds explicit rather than implied? | Simulation, sensor, wind, broadcast, plant/leader, holdout, and geometry scope had become too compressed. | Restored these limitations compactly; no claim was weakened or hidden. |
| Conclusion | Does it match the accepted claim set? | “Communication-saving” could be read as a broad claim even in a negation. | Rephrased as no general reduction in total radio traffic; simulation/hardware/robustness/stability boundaries remain explicit. |

## Claim and evidence mapping

Status meanings: **preserved** = materially unchanged; **compressed** = fewer
details but same evidence and scope; **artifact-only** = secondary detail was
removed from the paper but remains in the frozen reproducibility artifact and
is not needed to establish a main-paper claim.

| Claim / evidence item | Pre-cut location (`ff4065c5`) | Post-cut location | Status | Meaning changed? | Caveat survived? | Reviewer risk after repair |
|---|---|---|---|---|---|---|
| Unknown/changing network motivates within-mission adaptation | Introduction | Introduction; Abstract | Preserved | No | Yes | Low |
| Primary contribution is adaptivity, not universal periodic dominance | Introduction; Discussion | Introduction; Discussion; Conclusion | Preserved | No | Yes | Low |
| Cautious nearest-neighbor novelty gap | Related Work | Related Work | Compressed | No | Yes: “We did not identify” | Low |
| Sender has no direct receiver state under loss/delay | Problem Formulation | Introduction; Problem Formulation | Preserved | No | Yes | Low |
| True receiver AoI versus causal estimate | Problem Formulation | Problem Formulation | Preserved | No | Yes | Low |
| Independent DATA/ACK loss, delay, and jitter | Problem Formulation | Problem Formulation | Compressed | No | Yes; `\sigma_j` restored | Low |
| Per-channel causal state and cumulative ACK semantics | Method | Method | Preserved | No | Yes; tuple fields restored | Low |
| `lastSent` versus `lastAcked` dual memory | Method; design narrative | Method; Results; Discussion | Preserved | No | Yes | Low |
| New-information versus refresh semantic split | Method; design narrative | Method; Results; Discussion | Preserved | No | Yes | Low |
| In-flight suppression applies only to refresh | Method | Method | Preserved | No | Yes | Low |
| Sampled grid excludes Zeno by construction | Method | Method; Limitations | Preserved | No | Yes: not a stability proof | Low |
| Distributed operation is not feedback-free | Method | Method | Compressed | No | Yes; ACK dependency now explicit | Low |
| P`k`, State-event, ideal-feedback, and oracle-periodic definitions | Experimental Setup | Experimental Setup | Compressed | No | Yes; reference is not a bound | Low |
| Frozen nominal trigger and mission parameters | Experimental Setup; parameter table | Experimental Setup | Compressed | No | Yes; complete manifest remains artifact | Low |
| Common random numbers and matched seed pairing | Experimental Setup | Experimental Setup | Compressed | No | Yes; pre-draw basis restored | Low |
| Paired 95% interval is Student-`t`, not bootstrap | Experimental Setup; statistical protocol | Experimental Setup | Preserved after correction | **Initial wording error fixed** | Yes | Low |
| EXP07 per-channel versus EXP08+ swarm-total rates | Experimental Setup; table captions | Experimental Setup; Results captions | Preserved | No | Yes | Low |
| EXP07 versus EXP08+ graph convention | Experimental Setup | Experimental Setup | Compressed | No | Yes; cross-table traffic comparison prohibited | Low |
| Broadcast metric is an accounting proxy | Cost definitions; Discussion; Limitations | Problem Formulation; Setup; Results; Limitations | Preserved after clarification | No | Yes; not actual medium simulation | Low |
| v1→v2→v3 mechanism and 20-seed evidence | Design Results | Table I; Results; Discussion | Compressed | No | Yes; mean±SD restored in caption | Low |
| EXP10 one-policy monotone rate response | Nominal Results | Table II; Results | Preserved | No | Yes | Low |
| K1: 50-seed Stressed paired RMSE versus P10 | Nominal Results | Abstract; Table III; Results | Preserved | No | Yes; signed contrast wording repaired | Low |
| K2 DATA advantage reverses with ACK-inclusive cost | Nominal Results; Pareto section | Abstract; Tables II–III; Results; Discussion | Preserved | No | Yes | Low |
| Moderate Pareto criterion supported | Cost Results | Results; Fig. 2 | Compressed | No | Yes | Low |
| Stressed Pareto criterion rejected | Cost Results | Results; Table VI; Limitations | Preserved | No | Yes | Low |
| EXP11 has five segments and four adjacent transitions | EXP11 setup | Experimental Setup; Table IV; Fig. 1 | Preserved after correction | **Initial segment wording fixed** | Yes | Low |
| EXP11 H1 within-run rate changes | EXP11 Results | Table IV; Fig. 1; Results | Preserved | No | Yes; no regime label | Low |
| EXP11 H2a paired RMSE versus P10 | EXP11 Results | Table IV; Results | Preserved | No | Yes | Low |
| EXP11 H2b only at preregistered `w=0.25` | EXP11 Results | Abstract; Table IV; Results; Limitations | Preserved | No | Yes | Low |
| P12.5 tuned-periodic counterexample | EXP11 frontier | Abstract; Table V; Results; Discussion | Preserved | No | Yes; remains prominent | Low |
| Broadcast reversal versus P20 | EXP11 frontier | Abstract; Table V; Results; Discussion | Preserved | No | Yes; proxy qualification restored | Low |
| Oracle-periodic comparison is an information/efficiency reference | EXP11 frontier | Setup; Results; Discussion | Preserved | No | Yes; not a bound | Low |
| Reverse ACK impairment saturates in Stressed | Robustness Results | Results; Table VI | Compressed | No | Yes; numeric bridge restored | Low |
| Topology/degree-scaling boundary | Robustness Results | Results; Table VI; Limitations | Compressed | No | Yes | Low |
| Fault safety uses eligible denominators | Fault Results; Setup | Experimental Setup; Table VI | Compressed | No | Yes; denominator rule restored | Low |
| Mass mismatch, estimator noise, and timestep boundaries | Robustness Results | Results; Table VI; Limitations | Compressed | No | Yes | Low |
| Synthetic estimator is not a physical sensor model | Validation/Limitations | Limitations | Preserved after clarification | No | Yes | Low |
| External force is not aerodynamic wind | Validation/Limitations | Limitations | Preserved after clarification | No | Yes | Low |
| 6-DOF simulation survival at `N=5` | Validation Results | Fig. 3; Results; Limitations | Compressed | No | Yes; kinematic leader and simulation-only scope restored | Low |
| Large-swarm result uses double-integrator plant | Scalability/Limitations | Limitations; Table VI | Compressed | No | Yes | Low |
| Zero divergences/protocol violations in frozen campaign | Validation synthesis | Results | Preserved | No | Yes; empirical, not formal | Low |
| Full per-cell matrices and secondary plots | Robustness subsections | Frozen artifact; summarized in Table VI | Artifact-only | No main claim lost | Main limitations retained | Low |

## High-risk adjective and claim-word audit

| Term | Accepted use after audit | Prohibited inference explicitly excluded |
|---|---|---|
| better / lower | Only a named paired comparison or a table value with its condition and unit. | No universal ranking. |
| robust | Literature terminology or a rejected/universal-robustness boundary. | No “robust under all network conditions.” |
| adaptive / adaptivity | Rate changes by one fixed causal policy within or across the frozen tested regimes. | Does not imply mission-level Pareto superiority. |
| causal | Sender uses local state, sampled time, and arrived ACKs; it never reads latent delivery/drop outcomes. | No hidden regime label or oracle feedback. |
| decentralized / distributed | Operationally per-sender/per-channel with causal ACK feedback and no global coordinator. | Not feedback-free. |
| Pareto | Only the preregistered point-family accounting results and their stated regimes. | Stressed and universal Pareto claims remain rejected. |
| efficient / efficiency | Names an ideal-feedback/oracle-information reference. | Not an accuracy or performance upper bound. |
| scalable | Not used as a general claim; larger-swarm evidence is a bounded characterization. | No asymptotic or 6-DOF scalability claim. |
| validated / validation | Simulation validation only, with plant and mission scope named. | No hardware validation. |

## Seventeen repaired gaps

1. Added an explicit problem sentence to the abstract.
2. Replaced sign-ambiguous “improvement/falls by” phrasing with explicit
   signed Causal-v3-minus-baseline differences for K1 and K2.
3. Defined jitter standard deviation `\sigma_j` before use.
4. Defined cumulative-ACK sequence and generation fields.
5. Clarified that distributed operation still requires causal ACK feedback.
6. Restored fixed-periodic, State-event, ideal-feedback, and oracle-periodic
   baseline definitions.
7. Restored the locked nominal mission and trigger parameters needed to
   interpret the core experiment.
8. Restored the common-random-number pre-draw and matched-seed rationale.
9. Corrected “bootstrap” to the frozen matched-pair Student-`t` interval.
10. Restored the EXP07 versus EXP08+ graph and traffic conventions.
11. Repeatedly identified broadcast accounting as a proxy rather than an
    actual broadcast/MAC simulation.
12. Corrected EXP11 to five segments and four adjacent transitions.
13. Restored fault-safety eligibility denominators.
14. Restored the 20-seed mean±SD definition in the design-evolution caption.
15. Reattached the reverse-ACK saturation interpretation to visible frozen
    metric macros.
16. Restored the physical-scope limits of the synthetic estimator and
    external-force proxy.
17. Restored holdout, graph, timestep, leader/plant, scale, geometry,
    trajectory, and mission-sequence scope.

No shortening was performed in this audit batch. Every edit either restores a
logical bridge from the pre-cut manuscript or prevents an overbroad reading of
the compressed candidate.
