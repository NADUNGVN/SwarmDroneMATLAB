# TCNS theory-review checkpoint after Gate 3

**Decision:** `GO WITH CONDITIONS` for Gate 4.

**Reviewed source state:** `d52edd7`

**Role of this checkpoint:** audit the proved statements and freeze the
scientific constraints on the first control-aware policy before its code or
development results exist. This document is not a novelty claim and is not a
held-out acceptance decision.

## 1. What is actually established

The following chain is valid for the implemented fixed-topology,
double-integrator (`DI`) subsystem after the saturation transient:

1. The exact sampled formation dynamics are the matrix recurrence recorded in
   `THEORY_NOTES.md`; the one-step implementation residual is at numerical
   precision.
2. The receiver-held payload belongs to the sender-computable set containing
   the cumulative-ACK payload and all later outstanding payloads. This gives a
   causal pathwise bound on position, velocity and, for the analytical leader,
   acceleration mismatch.
3. Controller gains and graph weights map those link-local mismatches to an
   upper bound \(\beta_i(k)\) on communication-induced command disturbance.
4. Subtracting a perfect-current-information continuation from the stale
   continuation gives the exact linear degradation recurrence
   \(\delta y_{k+1}=A_h\delta y_k+B_cd_k^c\).
5. Unrolling this recurrence gives an exact structured finite-horizon bound.
   A contracting block power supplies a rigorous infinite tail and therefore
   a finite ISS/UUB certificate.

The accepted Gate-3 experiment validates every implementation identity used
in this chain, causal-set containment, and finite-bound coverage. It does not
prove performance outside the theorem scope.

## 2. Independent proof audit

### Lemma 4: causal information-set containment

The proof is sound under the implemented cumulative-ACK protocol. Once an ACK
for sequence \(n\) is accepted, the receiver holds sequence \(n\) or a later
accepted sequence. The former is the ACK-confirmed candidate; the latter must
remain in the sender's outstanding set until a cumulative ACK covering it is
accepted. Records whose hidden simulator flag says that the packet was
dropped only enlarge the set and are not consulted by the construction.

The result would not automatically survive finite packet-history truncation,
non-cumulative ACK semantics, receiver reboot, or an implementation that
deletes an outstanding record on timeout. Gate 4 must preserve all of these
protocol invariants.

### Theorem 1: exact degradation recurrence

The subtraction argument is exact only while both compared commands are
unsaturated and both continuations share the same state at initialization.
The analytical-leader residual cancels because both continuations use the
same leader. These conditions are checked in Gate 3 and must stay visible in
every theorem statement.

### Theorem 2: finite horizon and UUB

The finite-horizon formula follows directly by convolution. It preserves
signed cancellation inside each matrix power before applying the triangle
inequality to follower-vector input blocks.

For the infinite tail, writing an impulse index as \(lq+s\) gives

\[
\|e_\ell^\top A_h^{lq+s}B_c\|_2
\le \|e_\ell^\top A_h^s\|_2\|A_h^q\|_2^l\|B_c\|_2.
\]

Summing \(l\ge1\) produces the implemented factor
\(\alpha/(1-\alpha)\). Hence the tail is rigorous rather than a numerical
truncation. The result is sufficient and conservative; it is neither a
necessary condition nor an optimal induced-gain computation.

### Formation/RMSE corollary

The pointwise formation bound follows from the triangle inequality. The RMSE
translation is also valid because the pointwise upper quantities are
nonnegative. It bounds degradation relative to the matched perfect-current
continuation; it does not say that communication is the only source of
absolute formation error.

## 3. Causality and implementability audit

For each ordinary directed payload \(j\rightarrow i\), transmitter \(j\) can
compute the link-local controller contribution

\[
r_{ij}=K_ps_i\zeta^p_{ij}+K_vs_i\zeta^v_{ij}.
\]

For a pinned analytical-leader payload, the leader can compute

\[
r_{iL}=K_{pL}\zeta^p_{iL}+K_{vL}\zeta^v_{iL}+\zeta^a_{iL}.
\]

Both use only the current transmitted state, ACK-confirmed memory and sent
outstanding records. They do not use receiver truth, an instantaneous true
AoI, future channel state, or the internal DATA-drop outcome.

No individual neighbor sender knows all contributions entering receiver
\(i\). Runtime summation of \(\beta_i\) at a sender would therefore be an
oracle. Gate 4 will close `PROOF GAP G3.2` using offline budget allocation,
not hidden coordination.

## 4. Frozen distributed budget construction for Gate 4

Let the requested uniform ultimate position-degradation budget be
\(\epsilon_d>0\). For a uniform follower command-disturbance envelope
\(b=\bar b\mathbf 1\), define

\[
c_\ell=\sum_i[G_q]_{\ell i}+\tau_\ell\sqrt m,
\qquad
\bar b=\frac{\epsilon_d}{\max_{\ell\in\text{position}}c_\ell}.
\]

Then the Gate-3 certificate directly implies a position-degradation UUB no
larger than \(\epsilon_d\), conditional on \(\beta_i(k)\le\bar b\) for all
followers and times in theorem scope.

For follower receiver \(i\), let \(q_i\) be the number of controller-relevant
incoming ordinary links plus its pinned-leader link, if present. Allocate

\[
b_{ij}=\bar b/q_i,
\qquad b_{iL}=\bar b/q_i.
\]

If every local contribution is below its allocation, their sum is below
\(\bar b\). Equal contribution allocation is fixed because the physical
controller gains already appear inside \(r\); it introduces no fitted
AoI/state weights. Later work may formulate a less conservative allocation,
but it cannot replace this frozen first implementation after observing a
favorable baseline comparison.

The scalar \(\epsilon_d\) is a declared communication-performance sweep
parameter. Gate 4 will not select one value because it beats Periodic10.

## 5. Critical limitation: a transmission is not an instantaneous guarantee

Putting a new payload on the channel adds a candidate to the sender's possible
receiver-state set. It does not remove the older ACK-confirmed or outstanding
candidates. Only a returned cumulative ACK can contract that set. Therefore:

- transmitting at \(r_{ij}>b_{ij}\) does not instantly prove
  \(r_{ij}\le b_{ij}\);
- under IID loss with nonzero probability, no finite deterministic upper bound
  on ACK age or \(\beta_i\) exists over an infinite horizon;
- the Gate-3 theorem is a conditional robustness statement, not proof that a
  lossy-channel policy enforces its premise at every sample;
- final evaluation may establish finite-horizon statistics or a
  high-probability result only if such a result is separately derived.

The new policy must consequently distinguish:

1. **budget violation:** the causal local contribution exceeds its allocation;
2. **useful payload already in flight:** the newest sent payload would satisfy
   the local budget if it became the confirmed payload;
3. **new information:** even the latest sent payload has become insufficient;
4. **conditional retry:** the budget is violated, no ACK has contracted the
   set, and the fixed retry interval has elapsed.

This is a control-derived event rule with ACK-aware liveness logic. It is not a
claim of deterministic bound enforcement under stochastic loss.

## 6. Gate-4 admissible implementation

Gate 4 is authorized only under all of the following conditions:

1. The legacy Causal-v3 path remains byte-for-byte behaviorally reproducible
   when the new mode is disabled.
2. The decision implementation is isolated and reads only transmitter-local
   causal state.
3. The event quantity is \(r_{ij}/b_{ij}\), derived above; no fitted expression
   such as `alpha*AoI + beta*error + gamma*formationError` is admitted.
4. Links that do not enter a receiver's controller are not silently removed
   only for the proposed method. They must either retain legacy behavior in
   the first sanity comparison or be removed consistently from every method
   in a later, explicitly defined controller-relevant communication graph.
5. A useful outstanding payload suppresses redundant new-information sends.
   A fixed conditional retry protects finite-run liveness; its value must be
   declared and later swept or ablated, not tuned against P10.
6. The simulator must record trigger reason, violation exposure, outstanding
   suppression and realized bound satisfaction.
7. Unit tests must prove drop-flag invariance, receiver-set containment,
   budget algebra, deterministic seeds and legacy-path regression.
8. Development uses only declared development seeds/scenarios. Held-out
   evaluation remains unopened.

## 7. Novelty/collapse threats

The rule may be closely related to ACK-based state-error event triggering or
robust/VoI scheduling. When the ACK-confirmed candidate dominates the possible
set, it reduces to a controller-weighted ACK-state error threshold with
in-flight suppression. This is a real novelty threat, not a wording problem.

Gate 4 is justified as a falsification experiment: determine whether the
theorem-derived information-set budget produces behavior distinct from and
useful beyond state-error, AoI-only, and AoI-plus-state baselines. Novelty is
withheld until the related-work matrix and required ablations support it.

## 8. Remaining proof gaps after the checkpoint

**Resolved design gap G3.2 (conditional):** equal offline link allocation is a
distributed sufficient construction. The conditional qualifier matters:
policy action does not guarantee that a lossy network maintains each local
allocation at every instant.

**PROOF GAP G4.1 — stochastic enforcement probability.** No probability bound
currently maps loss/delay statistics and retry logic to the probability or
duration of budget violation.

**PROOF GAP G4.2 — saturation.** The difference recurrence is not proved
through saturation. Gate-4 sanity runs must record saturation and cannot apply
the theorem on saturated intervals.

**PROOF GAP G4.3 — broader dynamics/topology.** The certificate does not cover
6-DOF dynamics, directed/switching/disconnected topology, estimator noise, or
model mismatch.

**PROOF GAP G4.4 — novelty.** No novelty claim is permitted before comparison
against the closest event-triggered, AoI and VoI/control-aware literature.

## 9. Smallest post-implementation falsification experiment

Use the exact DI subsystem and one existing fixed development seed. Run a
short stationary Stressed scenario for a small preregistered sweep of
\(\epsilon_d\), without changing any channel or controller parameter. Compare:

- legacy Causal-v3;
- the new control-aware policy;
- one periodic arm spanning a comparable realized traffic range.

This run is a mechanics test, not evidence of superiority. It passes only if:

- causal/protocol invariants and theoretical identities remain exact;
- no hidden receiver state or drop outcome affects a decision;
- tightening \(\epsilon_d\) weakly increases communication in the deterministic
  realization, apart from explicitly diagnosed queue/ACK effects;
- trigger logs show budget-driven bursts and in-flight suppression;
- at least two sweep points produce distinct communication operating points;
- the run remains in the theorem's unsaturated scope after the declared
  evaluation start.

Failure of these checks stops expansion to Pareto or nonstationary studies.

