# TCNS control-aware freshness: initial technical audit

**Audit date:** 2026-09-06  
**Requested branch:** `paper-v3-tcns`  
**Audited commit:** `dbbb4197849694154cfec769d18fc4b38b05f0ad`  
**Requested snapshot:** `954fbf22ee37039619b3dd4b04d4dc4b22f85f86`

## 0. Snapshot identity and scientific scope

`954fbf22ee37039619b3dd4b04d4dc4b22f85f86` is a Git **tree object**, not a
commit object. It is exactly the tree of audited commit `dbbb419...`; therefore
the requested source snapshot and the current branch content are identical.
No reset or history rewrite is required.

The existing evidence does not establish that Causal-v3 universally
outperforms periodic communication. The new question is therefore not a tuning
problem. The primary TCNS direction is:

> Relate causal information staleness to receiver-side state uncertainty and
> closed-loop formation degradation, then transmit when the resulting control
> disturbance approaches a defensible performance budget.

The existing policies and negative results remain baselines and evidence. They
must not be overwritten or selected away.

## 1. Exact implementation-to-model mapping

### 1.1 Agents and sampled plant

Agent 1 is a kinematic leader. Agents `i=2,...,N` are followers. The outer
sample time is `h = cfg.swarm.dt = 0.02 s` in the primary configuration.

The default analytical plant path in `swarm/integrateFollowers.m` is the
semi-implicit Euler double integrator. For each follower,

\[
v_i(k+1)=v_i(k)+h u_i(k),
\qquad
p_i(k+1)=p_i(k)+h v_i(k+1).
\]

Thus, with `x_i=[p_i^T,v_i^T]^T`, its exact implemented update is

\[
x_i(k+1)=
\begin{bmatrix}I&hI\\0&I\end{bmatrix}x_i(k)+
\begin{bmatrix}h^2I\\hI\end{bmatrix}u_i(k).
\]

The coefficient is `h^2`, not the `h^2/2` of exact zero-order-hold
discretization, because velocity is updated before position.

The primary frozen N=5 point uses the optional nonlinear path. Its follower
state in `models/quadrotor/quad6dofDynamics.m` is
`[p^T,v^T,roll,pitch,yaw,omega^T]^T`. The distributed outer loop supplies a
desired acceleration to `controllers/quadCascadedController.m`; the rigid-body
dynamics are integrated by RK4 at ten inner steps per outer step. The nominal
parameters include `m=0.060 kg`, `g=9.81 m/s^2`, thrust and torque saturation,
linear/angular drag, and cascaded position/attitude feedback. No theorem below
silently equates this nonlinear cascade with the double integrator.

`cfg.swarm.maxAccel=2.0 m/s^2` limits the commanded acceleration norm in
`distributedFormationPolicy.m`. `cfg.swarm.maxSpeed` is not enforced anywhere
in the current plant and cannot be used as a physical bound.

### 1.2 Formation variables, graph, and controller

Let `r_i` denote the desired offset stored in `cfg.swarm.offsets`. The measured
leader-frame formation error is

\[
e_i(k)=p_i(k)-p_1(k)-r_i(k),\qquad i=2,\ldots,N.
\]

`computeSwarmMetrics.m` evaluates follower error against the **actual** leader
position and supports time-varying desired offsets through
`out.desiredOffsets`.

For the default N=5 system, `cfg.swarm.A` is an undirected ring, and followers
2 and 4 also have separate leader pins. An ordinary adjacency edge to agent 1
and a pin are distinct controller terms. With receiver `i`'s stored estimate
of sender `j`, the implemented outer-loop command before saturation is

\[
\begin{split}
u_i={}&-K_p s_i\sum_j A_{ij}
[(p_i-\hat p_{ij})-(r_i-r_j)]\\
&-K_v s_i\sum_j A_{ij}(v_i-\hat v_{ij})\\
&-\pi_iK_{pL}[(p_i-\hat p_{i1}^{L})-r_i]
-\pi_iK_{vL}(v_i-\hat v_{i1}^{L})
+\pi_i\hat a_{i1}^{L}.
\end{split}
\]

Here `s_i=1` in EXP10. The optional degree normalization uses
`s_i=2/d_i`, but it is explicitly disabled in the frozen validation.
The configured gains are `Kp=1.8`, `Kv=2.2`, `KpLeader=1.5`, and
`KvLeader=1.8`.

For the unsaturated double-integrator path, define the follower--follower
Laplacian `L_f`, ordinary leader grounding `G=diag(A_{i1})`, and pinning
`Pi=diag(pi_i)`. Then

\[
H_p=K_pS(L_f+G)+K_{pL}\Pi,\qquad
H_v=K_vS(L_f+G)+K_{vL}\Pi.
\]

For one spatial coordinate and `y_k=[e_k^T,h(v_F-v_1)_k^T]^T`, the exact
nominal semi-implicit update implemented by MATLAB is

\[
y_{k+1}=A_hy_k+D_hu_k,
\]

\[
A_h=\begin{bmatrix}
I-h^2H_p&I-hH_v\\
-h^2H_p&I-hH_v
\end{bmatrix},\qquad
D_h=\begin{bmatrix}I&I\\0&I\end{bmatrix}.
\]

The first input block is the analytic-leader position-step residual; the
second is `h^2` times the stacked acceleration disturbance. The existing
`utils/formationTheoryCertificate.m` constructs these matrices directly from
a configuration.

### 1.3 Receiver state, packets, delay, loss, and age

For a directed information link from sender `j` to receiver `i`, the queued
network stores the newest accepted payload in `net.Pij(i,j,:)` and
`net.Vij(i,j,:)`. These are initialized with the exact state at time zero.
The receiver applies zero-order hold; there is no model-based propagation.
Packets contain generation time, sequence number, position, velocity, and—on
the separate leader-pin stream—leader acceleration. A packet is accepted only
if it is newer than the receiver's current generation. Late obsolete packets
are discarded.

Forward packet loss is an IID Bernoulli comparison against
`cfg.net.packetLoss` when the frozen trace is used. Arrival time is generation
time plus `cfg.net.delay` and Gaussian jitter, clamped to a nonnegative delay.
The reverse ACK channel has its own loss, delay, jitter, and trace. It uses
cumulative generation/sequence validation and cannot causally confirm data
that the receiver has not accepted. Later shared-medium engines add queueing,
contention, collision, and burst-state channels, but those are not present in
the EXP10 point-to-point channel.

Let `g_ij(k)` be the generation index/time of the newest DATA accepted at
receiver `i`. The receiver's true sampled AoI is implemented as

\[
\Delta_{ij}(k)=t_k-g_{ij}(k)+h/2.
\]

Let `c_ij(k)` be the latest generation causally confirmed back to sender `j`.
The sender-side causal age is

\[
\widehat\Delta_{ij}(k)=t_k-c_{ij}(k)+h/2.
\]

Under the implemented ACK invariants,
`c_ij(k) <= g_ij(k)` and therefore
`hatDelta_ij(k) >= Delta_ij(k)`. Lost or delayed ACKs increase pessimism but
cannot create optimistic receiver knowledge.

The stale-state error relevant to the controller is

\[
\tilde x_{ij}(k)=x_j(k)-\hat x_{ij}(k),\quad
\hat x_{ij}(k)=[\hat p_{ij}^T,\hat v_{ij}^T]^T.
\]

This receiver error is not the same quantity as Causal-v3's innovation, which
is measured against the sender's last **transmitted** state.

### 1.4 Exact current trigger

The frozen Causal-v3 policy in `network/causalInnovationTriggerPolicy.m` uses
two memories: last sent state for innovation and latest ACK-confirmed
generation for freshness. Its fixed parameters in `utils/applyExp10Point.m`
are:

| Parameter | Value |
|---|---:|
| position threshold `epsP` | 0.05 m |
| velocity threshold `epsV` | 0.10 m/s |
| stale threshold `Abar` | 0.12 s |
| maximum silence | 0.50 s |
| global minimum inter-transmission time | 0.02 s |
| refresh cooldown | 0.10 s |
| adaptive scale `s0` | 0.50 |
| minimum scale `smin` | 0.20 |
| adaptation range `rho` | 1.00 |

It sends, in priority order, on: hard position/velocity innovation; stale age
plus innovation beyond an age-scaled threshold; a stale refresh only when the
refresh cooldown has elapsed and no packet is outstanding; or the maximum-
silence backstop. This is heuristic with respect to formation stability: its
thresholds are not derived from a control-error budget.

## 2. Current experimental inventory

### 2.1 Engines and policy families

- Plant/control engines: `simSwarm`, `simSwarmNetwork`,
  `simSwarmEventTriggered`, `simSwarmAoIAware`, `simSwarmAoIAblation`,
  `simSwarmAoICausal`, `simSwarm6DOF`, and `simSwarmSharedMedium`.
- Historical baselines: periodic communication, state-event trigger,
  AoI-aware and AoI ablations, causal ACK v1--v3, oracle-information periodic,
  AoI-only broadcast, AoCI, delayed-ACK belief, and multiple later
  shared-medium/MAC schedulers.
- Experiment history: EXP01--04 plant and simple network; EXP05 AoI/event and
  Pareto diagnostics; EXP06 scalability; EXP07 causal ACK and accounting;
  EXP08 topology/faults; EXP09 6-DOF/mismatch/estimator; EXP10 frozen final
  validation; EXP11 within-run changing network; EXP12--20 shared-medium,
  access, AoI/VoI and prior-art closure; EXP21 distributed timing; EXP22 ELCS;
  EXP23 coherence, closure, routing, and routed-plant diagnostics.
- Metrics: formation RMSE/max error, velocity disagreement, minimum
  separation, settling time, divergence, 6-DOF attitude/saturation/control
  effort, DATA/ACK/frame/broadcast counts and rates, weighted cost, airtime,
  AoI statistics, collision/queue/access-delay diagnostics, energy proxy, and
  runtime.

### 2.2 Frozen numerical anchors

The canonical EXP10 dataset is
`results/exp10a_final_validation/2026-08-27_091546/tidy.csv`: 3400 rows,
50 paired seeds, MATLAB R2025a. For the nominal N=5 6-DOF point:

| Scenario | Method | Formation RMSE (m) | DATA (Hz) | ACK (Hz) | DATA+0.25ACK (Hz) | Broadcast accounting (Hz) |
|---|---|---:|---:|---:|---:|---:|
| Clean | P10 | 0.0361460 | 99.6667 | 0 | 99.6667 | 59.8000 |
| Clean | Causal-v3 | 0.0413792 | 84.4667 | 84.4667 | 105.5833 | 50.7000 |
| Moderate | P10 | 0.0975525 | 99.6667 | 0 | 99.6667 | 59.8000 |
| Moderate | Causal-v3 | 0.0892032 | 134.8353 | 107.6180 | 161.7398 | 118.6967 |
| Stressed | P10 | 0.1476536 | 99.6667 | 0 | 99.6667 | 59.8000 |
| Stressed | Causal-v3 | 0.1188091 | 182.9393 | 109.6067 | 210.3410 | 109.8613 |

Therefore P10 dominates Causal-v3 in Clean under the stated weighted cost.
In Moderate/Stressed, Causal-v3 buys lower error with substantially more
traffic; those rows do not demonstrate a matched-budget win.

The canonical EXP11 dataset is
`results/exp11_dynamic_network/2026-08-27_174026/tidy.csv`: 400 rows,
50 paired seeds, MATLAB R2025a. Its mission means include:

| Method | Formation RMSE (m) | DATA+0.25ACK (Hz) | Broadcast accounting (Hz) |
|---|---:|---:|---:|
| P10 | 0.0922806 | 100.0021 | 60.0008 |
| P12.5 | 0.0834180 | 125.0069 | 75.0032 |
| Causal | 0.0814675 | 139.5386 | 191.6521 |
| P20 | 0.0704037 | 199.9984 | 119.9992 |

EXP11 supports the scientific motivation that fixed periodic choices can be
hard to dominate, especially once cost accounting is changed. It does not yet
show a control-aware matched-budget advantage.

### 2.3 Reproducibility hazard to repair in Gate 0

`results/exp11_dynamic_network/LATEST.txt` points to the later 3-seed debug run
`2026-08-27_175335`, not the canonical 50-seed run. The EXP11 source is no
longer present under `experiments/`; only immutable copies inside the two
result directories are tracked. Gate 0 must reference the canonical directory
explicitly and make this distinction machine-checkable. It must not delete,
rename, or overwrite either run.

## 3. Reuse versus extension

### Reuse unchanged unless a failing test proves otherwise

- `swarm/distributedFormationPolicy.m` and both plant paths;
- queued network delivery, ACK invariants, deterministic trace generators, and
  common-random-number infrastructure;
- frozen EXP10/EXP11 result directories and all historical policies;
- `computeSwarmMetrics`, `compute6DOFMetrics`, and shared-medium metrics;
- experiment lifecycle/provenance helpers (`startExperiment`,
  `finishExperiment`, configuration snapshots, result manifests);
- the exact matrix construction in `formationTheoryCertificate`;
- causal-age conservatism and zero-order-hold envelope arguments in
  `docs/STUDY2_MATHEMATICAL_FOUNDATION.md`, after restating their scope.

### Extend or add without changing historical semantics

- `paper/tcns/RESEARCH_STATUS.md`: Gate-0 frozen audit and numerical anchors;
- `paper/tcns/THEORY_NOTES.md`: Gate-1 model, assumptions, claims, and gaps;
- `paper/tcns/ACCEPTANCE_CRITERIA.md`: later preregistration before held-out
  evaluation;
- `experiments/tcns_gate0_baseline_audit.m`: explicit canonical validation and
  machine-readable comparison;
- `utils/tcnsStalenessEnvelope.m`: exact sampled zero-order-hold bounds;
- optional instrumentation in `simSwarmAoICausal`/`simSwarm6DOF`, guarded by
  a default-off configuration flag, to log accepted neighbor estimates and
  communication-induced controller disturbance without moving decisions;
- `experiments/tcns_gate2_bound_diagnostic.m`: actual-error versus bound data;
- `utils/tcnsFormationRobustnessCertificate.m`: a tighter finite-horizon or
  optimized Lyapunov certificate, retaining the current conservative result as
  a diagnostic;
- `network/controlAwareFreshnessTriggerPolicy.m`: only after Gates 2--3 pass;
- focused tests for bound monotonicity, controller-disturbance mapping,
  causality, deterministic seeds, and policy branch semantics.

No giant refactor and no replacement of the current simulator are justified
before the mathematical link is validated.

## 4. File-level plan for Gates 0--4

### Gate 0 — freeze and audit

1. Add `paper/tcns/RESEARCH_STATUS.md` and a machine-readable audit spec.
2. Add `experiments/tcns_gate0_baseline_audit.m` that runs tests, records the
   tree/commit/MATLAB/config/seed identities, re-executes a deterministic
   selected comparison, and checks it against canonical EXP10 rows.
3. Run the full frozen EXP10 reproduction through the existing entry point if
   the selected check passes. Validate canonical EXP11 by explicit path and
   hash/row/seed checks; do not trust `LATEST.txt`.
4. Persist comparisons under a new `results/tcns_gate0_baseline_audit/<run>`
   directory and commit Gate 0 separately. Stop if the canonical baseline
   cannot be reproduced.

### Gate 1 — exact model

1. Add `paper/tcns/THEORY_NOTES.md` with the exact discrete update, graph,
   packet state, age variables, and assumptions below.
2. Extend the matrix certificate only where needed to expose saturation-region
   and leader-residual obligations.
3. Add/extend unit tests that compare the matrix update against one MATLAB
   plant/controller step in an unsaturated, no-network-error fixture.
4. Commit Gate 1 separately.

### Gate 2 — age/staleness to uncertainty

1. Implement the exact sampled ZOH velocity and position envelopes, including
   payload-estimation error when enabled.
2. Add default-off receiver-estimate instrumentation and a deterministic
   bound-diagnostic experiment.
3. Plot/log actual stale-state error, true AoI, causal sender age, and both
   theoretical bounds. Report coverage and conservatism; do not retune bounds
   on validation seeds.
4. If the global bound is useless, test a model-based predictor only as a
   separately declared mechanism and retain the negative ZOH result.
5. Commit Gate 2 separately.

### Gate 3 — uncertainty to formation degradation

1. Derive the exact communication disturbance injected by stale
   `Pij/Vij/leader` values.
2. Prove a sampled ISS/UUB statement for the unsaturated double-integrator
   subsystem when `A_h` is Schur.
3. Replace the numerically useless generic `Q=I` bound only with a valid tighter
   certificate (optimized quadratic metric or finite-horizon induced/reachable
   bound); retain “not certified” if no useful certificate is obtained.
4. Numerically compare actual formation state/error with the predicted bound
   and explicitly check acceleration saturation. Commit Gate 3 separately.

### Theory review checkpoint

Proceed only if the chain
`causal age -> state uncertainty -> control disturbance -> formation bound`
is valid and numerically informative in a declared operating region.

### Gate 4 — derived control-aware trigger

1. Turn the Gate-3 allowable disturbance inequality into a local link/sender
   transmission test; do not fit an arbitrary weighted score.
2. Keep periodic, random/budget-matched, state-event, AoI-only, AoI+state,
   Causal-v3, and appropriate VoI/control-aware prior-art arms.
3. Add isolated implementation, deterministic tests, and parameter docs.
4. Run only the smallest development sanity experiment described in Section 8
   before opening any large grid. Commit Gate 4 separately.

## 5. Initial candidate assumptions

These are candidates to be audited, not yet theorem facts.

**A1 — Sampled dynamics.** The analytical subsystem is exactly the implemented
semi-implicit double integrator at fixed `h>0`. The nonlinear 6-DOF cascade is
a separate validation plant.

**A2 — Graph/grounding.** During a theorem interval, the follower graph and
pinning are fixed. For the first result, the follower coupling is undirected
and every component is grounded through an ordinary leader edge or a pin.

**A3 — Nominal sampled stability.** The exact configured matrix `A_h` is Schur.
This is checked from the configuration, not assumed from continuous-time
gains.

**A4 — Causal receiver memory.** Receivers accept newest-generation DATA only
and hold the latest accepted payload; sender confirmation is monotone and can
only follow actual receiver acceptance.

**A5 — Bounded applied acceleration.** Follower acceleration in the analytical
plant obeys `||u_i(k)|| <= abar_i`. This is physically defensible because the
outer command is norm-saturated. A separate leader acceleration bound is
obtained from the declared leader reference. This assumption does not use the
dead `maxSpeed` configuration field.

**A6 — Finite-horizon velocity bound.** Over a declared finite interval,
`||v_i(k)|| <= vbar_i`, derived from the initial velocity and A5 or fixed from
a physical operating envelope before held-out evaluation. It is not inferred
from `cfg.swarm.maxSpeed`.

**A7 — Payload error bound.** In exact-state experiments payload error is zero.
Estimator/noise arms require separately declared position/velocity payload
error bounds; Gaussian noise cannot support a deterministic all-time bound
without a finite-horizon probability statement.

**A8 — Unsaturated linear proof region.** The first ISS theorem applies while
the ideal and stale-information commands remain inside the acceleration
saturation limit. Every experiment must report saturation. If this condition
fails materially, the result is UUB/nonlinear or sector-bounded analysis, not
the linear theorem.

**A9 — Exogenous leader residual.** Leader acceleration and the exact
semi-implicit/analytic reference mismatch are bounded inputs. Because only
pinned followers receive leader-acceleration feed-forward, unpinned followers
retain a nonzero leader-acceleration disturbance.

**A10 — Network uncertainty.** Delay and loss may be stochastic and can make
AoI unbounded on an infinite horizon. Deterministic performance claims are
conditioned on a finite age cap; stochastic claims require an explicit
finite-horizon tail/service assumption. `maxSilence` alone is not an AoI bound.

**A11 — Development/holdout separation.** Motion bounds, certificate choices,
and trigger budget mappings are frozen using development scenarios/seeds and
are not revised after held-out outcomes are opened.

## 6. Candidate statements based on the implementation

### Candidate Lemma 1 — causal age conservatism

Under A4 and consistent initialization,

\[
\widehat\Delta_{ij}(k)\ge\Delta_{ij}(k)
\]

for every configured directed link and sample. This result is already supported
by the protocol invariants and can be reused.

### Candidate Lemma 2 — exact sampled ZOH staleness envelope

Let the accepted sample be `q` outer steps old. For the semi-implicit follower
plant under `||u_j||<=abar_j`, exact payloads satisfy

\[
\|v_j(k)-\hat v_{ij}(k)\|\le qh\bar a_j,
\]

\[
\|p_j(k)-\hat p_{ij}(k)\|
\le qh\|v_j(k-q)\|
+\frac{h^2\bar a_j}{2}q(q+1).
\]

Using A6 gives a monotone age-only envelope. Payload errors add explicit
`eta_v` and `eta_p+qh eta_v` terms depending on estimator semantics. The
`q(q+1)` term follows the actual velocity-first integrator.

### Candidate Lemma 3 — communication-to-control disturbance map

Before saturation, the difference between the stale-information command and
the ideal-information command obeys, per follower,

\[
\|d_{c,i}\|\le K_p s_i\sum_jA_{ij}\|\tilde p_{ij}\|
+K_v s_i\sum_jA_{ij}\|\tilde v_{ij}\|
+\pi_iK_{pL}\|\tilde p^L_{i1}\|
+\pi_iK_{vL}\|\tilde v^L_{i1}\|
+\pi_i\|\tilde a^L_{i1}\|.
\]

This is the first control-relevance score justified directly by the current
controller. It is a norm bound, not yet a trigger or a claim of optimality.

### Candidate Theorem 1 — sampled formation ISS/UUB

Under A1--A3 and A8--A9, let `P>0` satisfy
`A_h^T P A_h-P=-Q` for some `Q>0`. Then the unsaturated implemented
double-integrator formation error is input-to-state stable with respect to the
stacked communication disturbance and leader/reference residual. A candidate
inequality is

\[
V(k+1)-V(k)\le-c_1\|y_k\|^2+c_2\|u_k\|^2,
\]

which yields a computable finite-horizon/ultimate formation-error bound. The
constants must be generated from the actual configuration and must be useful
enough to survive Gate-3 validation.

### Candidate Corollary 1 — control-aware freshness budget

Combining Lemmas 1--3 with Theorem 1 gives a sufficient local or distributed
condition of the form

\[
\bar d_c(\widehat\Delta,\text{motion bounds},\text{graph weights})
\le d_{allow}(\|e_f\|,\epsilon),
\]

under which contraction or an ultimate formation-error target is retained.
Gate 4 may trigger when this condition is about to be violated. No optimality
or minimum-communication claim follows from sufficiency alone.

## 7. Explicit proof gaps

**PROOF GAP P1 — nonlinear plant.** The existing ISS certificate is for the
unsaturated double-integrator outer loop. It does not prove stability of the
implemented 6-DOF attitude cascade, actuator saturation, drag, or model
mismatch.

**PROOF GAP P2 — saturation.** The control-disturbance difference is linear
only before acceleration saturation. Saturation can reduce or reshape that
difference and invalidates direct use of the linear closed-loop matrix. An
invariant unsaturated region or a valid nonlinear/sector argument is missing.

**PROOF GAP P3 — useful constants.** The current `Q=I` sampled certificate has
spectral radius `0.983582` but transient gain about `93.44` and input gain about
`5.18e6`; it is logically valid and numerically useless for the intended
performance claim. A tighter certificate or finite-horizon reachability bound
is unresolved.

**PROOF GAP P4 — bounded velocity.** The configuration's `maxSpeed` is dead
code. A velocity bound must be derived over a finite horizon or declared as a
physical operating envelope before evaluation.

**PROOF GAP P5 — accelerating leader.** Unpinned followers do not receive the
leader acceleration feed-forward. Exact zero-error tracking of an accelerating
leader is therefore not the nominal property of the current controller; the
residual must remain an input or the controller must be deliberately changed
in the new study.

**PROOF GAP P6 — directed/time-varying topology.** The current symmetric
grounded-Laplacian proof does not cover directed, nonsymmetric, switching, or
temporarily disconnected graphs. Those require a common/multiple Lyapunov or
joint-connectivity argument.

**PROOF GAP P7 — stochastic age.** IID/burst loss and contention do not give a
deterministic uniform AoI bound. A finite-horizon probability/service result is
required, and empirical mean PDR is not automatically a valid conditional
service lower bound.

**PROOF GAP P8 — local implementability.** The global formation-state budget in
the candidate corollary may require quantities unavailable to an individual
sender. A conservative distributed decomposition must be derived without
future channel outcomes or receiver truth.

**PROOF GAP P9 — novelty.** The current repository contains literature work and
prior-art implementations, but the new trigger cannot be called novel until a
fresh structured matrix shows that the final derived condition is not an
existing event-triggered/VoI policy in different notation.

## 8. Smallest promising-direction experiment

Do **not** start with a parameter sweep. Use one N=5 double-integrator
development scenario with a single preregistered formation switch or bounded
leader maneuver and five paired development seeds. Instrument the current
receiver states without changing decisions and compute, at every link/sample:

1. true AoI and causal sender age;
2. actual `||tilde p_ij||`, `||tilde v_ij||`;
3. the Gate-2 theoretical envelopes;
4. the exact pre-saturation controller perturbation caused by stale data;
5. a one-step or short-horizon state-cloned contrast between keeping the stale
   payload and replacing it by the current sender state.

The direction is promising only if all of the following occur without tuning
on those outcomes:

- the uncertainty envelope has full declared coverage and nontrivial tightness;
- control value is strongly time-varying around the maneuver/switch;
- the controller-disturbance bound ranks high-value intervals materially
  better than AoI alone;
- an offline, fixed-budget oracle using that derived quantity shows enough
  headroom over uniform/random allocation to justify implementing a causal
  trigger.

If the control-aware ranking provides no incremental information beyond AoI or
state error, stop Gate 4 and record the negative result. This five-seed
diagnostic is development evidence only; it cannot support a paper claim.
