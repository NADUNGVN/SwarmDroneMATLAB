# Reviewer red-team: TCNS candidate

Statuses mean:

- **PASS** — the paper directly answers the attack with visible evidence;
- **FIX WORDING** — evidence exists, but manuscript wording must be repaired;
- **LIMITATION** — the frozen evidence cannot answer the broader question, so
  the paper must bound the claim rather than manufacture a response.

This is the final post-repair classification: **PASS 7 / FIX WORDING 0 /
LIMITATION 8**.

## 1. Why not tune P12.5, P20, or another fixed periodic rate?

**Status: PASS.** A fixed rate cannot change its effort within a mission, but
EXP11 does not turn that fact into a superiority claim. P12.5 remains the
prominent counterexample: it achieves 97.7% of Causal-v3 accuracy at 89.6% of
its `C_0.25` cost and 39.1% of its broadcast-accounted cost. The Discussion
therefore claims mechanistic adaptivity, not universal mission-level
dominance. A mission-specific periodic tuning study beyond the frozen rates is
outside the evidence.

## 2. Why is ACK overhead worth paying?

**Status: LIMITATION.** ACKs provide causal receiver-freshness information and
support the observed within-mission mechanism, but the paper does not prove
that their cost is always worthwhile. K2 reverses the Stressed DATA advantage
at `w=0.25`, and EXP11 reverses again under broadcast accounting. Worth depends
on the mission objective and accounting model; the paper reports these
trade-offs instead of asserting a general benefit.

## 3. What is novel versus AoI and event-triggered prior work?

**Status: PASS.** Related Work explicitly compares Mamduhi, Ceran, WiSwarm,
Tahir, Kesper, Onozuka, and Lin. The cautious gap is the combination of
per-neighbor ACK-confirmed receiver-freshness estimation, dual last-sent versus
last-ACKed memory, state innovation, and in-flight refresh suppression in a
multi-agent/UAV controller. The wording is “We did not identify,” not “first”
or “no prior work.”

## 4. Is the policy decentralized if ACK feedback exists?

**Status: PASS.** “Distributed” is operational, not feedback-free: each sender
uses its own state and ACKs arriving on its channels, with no global
coordinator or regime label. The method now says this explicitly. A radio and
receiver are still required.

## 5. Where is the closed-loop stability proof?

**Status: LIMITATION.** There is none. The paper reports empirical simulation
safety gates and protocol invariants and explicitly disclaims a stability
guarantee. A joint controller/network proof would require new analysis beyond
the frozen study.

## 6. Does the no-Zeno statement imply stability?

**Status: PASS.** No. Transmissions are evaluated on an outer grid, so
inter-event time is at least the grid spacing by construction. Method and
Limitations both state that this is not a closed-loop stability proof.

## 7. Why can the ideal-feedback/oracle reference have worse RMSE?

**Status: PASS.** It is an information/efficiency reference, not an accuracy
optimizer or upper bound. Causal-v3 can spend more traffic and obtain lower
RMSE. The paper labels both ideal references accordingly in Setup, Results,
and Discussion.

## 8. What happens under Stressed ACK-inclusive cost accounting?

**Status: PASS.** The 50-seed K2 result shows fewer DATA packets versus P20 but
an unfavorable `DATA+0.25 ACK` contrast. The corresponding Stressed Pareto
claim is rejected, and Table VI retains the boundary. No general
ACK-inclusive saving is claimed.

## 9. Does sparse or high-degree topology break safety?

**Status: LIMITATION.** One tested topology condition fails because the fixed
consensus gain is not degree-normalized, and permanent disconnection produces
controller/geometry failures shared by methods. These are visible operating
boundaries, not evidence of topology-wide safety. Redesigning the controller
or proving graph-uniform guarantees is outside scope.

## 10. How meaningful is simulation-only 6-DOF validation?

**Status: LIMITATION.** It shows that method ordering and the adaptive rate
response survive one higher-fidelity simulated plant at `N=5`; it is not
flight evidence. The leader remains kinematic, and larger-swarm evidence uses
the double-integrator plant. Hardware, dynamic-leader, and large-`N` 6-DOF
tests remain open.

## 11. Why does estimator noise increase traffic?

**Status: LIMITATION.** Fixed innovation thresholds respond to noisy state
differences, producing false hard-innovation triggers. The experiment
characterizes that failure; it does not validate a physical sensor model or a
noise-robust filter. Threshold/filter redesign would be new scientific work.

## 12. Why is DATA rate dependent on the outer timestep?

**Status: LIMITATION.** Decisions occur only on the sampled outer grid, so the
number and timing of trigger opportunities depend on `Delta t`. Table VI and
Limitations expose this discretization dependence. Continuous-time invariance
or a timestep-normalized trigger is not established.

## 13. Does EXP11 generalize beyond one regime sequence?

**Status: LIMITATION.** No. Fifty matched seeds support the four signed
transitions in one five-segment mission, but they do not cover all orderings,
dwell times, graphs, or network processes. The paper calls H3/H4
characterizations and explicitly limits sequence generalization.

## 14. Does broadcast accounting invalidate communication-saving claims?

**Status: LIMITATION.** It invalidates any universal traffic-reduction claim,
which the paper rejects. The metric collapses same-tick outgoing unicasts as an
idealized accounting proxy while ACKs remain unicast; it is not an actual
broadcast/MAC simulation. The EXP11 P20 comparison reverses under this proxy,
and P12.5 is markedly cheaper.

## 15. Can a reviewer reproduce the comparisons from the compressed setup?

**Status: PASS.** The main paper identifies baseline semantics, nominal
parameters, common-random-number pre-draw, matched-pair Student-`t` intervals,
rate and graph conventions, EXP11 sequence structure, and fault eligibility.
The frozen artifact retains the complete manifest, seed assignments,
per-cell results, and provenance. The paper does not claim that prose alone is
a replacement for the artifact.

## Disposition

The red-team found no attack that requires a new claim or post-freeze
simulation. Eight attacks remain genuine limitations and are stated as such;
seven are answered directly in the manuscript. The wording repairs that were
needed during review are complete, leaving no final **FIX WORDING** item.
