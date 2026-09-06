# Control-aware freshness: exact model and proof ledger

**Gate:** 2
**Status:** implementation-faithful model and proved ZOH staleness envelope;
Gate-3 result not yet claimed
**Primary analytical scope:** fixed undirected grounded graph, exact-state,
constant-formation, unsaturated double-integrator subsystem

## 1. Scope discipline

The repository contains two plant levels and several network levels. They must
not be merged into one informal model.

1. The first theorem track uses the exact semi-implicit double integrator in
   `swarm/integrateFollowers.m` with the exact distributed outer controller in
   `swarm/distributedFormationPolicy.m`.
2. The N=5 nominal validation uses the nonlinear 12-state 6-DOF plant,
   cascaded attitude controller, RK4 inner integration, thrust/torque limits,
   and drag. It is a validation plant, not presently covered by the linear
   theorem.
3. EXP10 uses independent point-to-point queued links with IID packet loss and
   sampled delivery. Later experiments add contention, collision, queues,
   Gilbert--Elliott loss, and distributed scheduling. Those mechanisms are
   retained for later validation but are not needed to establish the first
   age-to-uncertainty identity.

All notation below follows the actual array orientation: `A(i,j)=1` means
receiver/controller `i` uses information sent by `j`.

## 2. Agents, formation, and graph

Agent 1 is the leader and agents in
\(\mathcal F=\{2,\ldots,N\}\) are followers. At outer sample
\(t_k=kh\), follower state and input are

\[
x_i(k)=\begin{bmatrix}p_i^\top(k)&v_i^\top(k)\end{bmatrix}^\top,
\qquad u_i(k)\in\mathbb R^3.
\]

The default outer period is \(h=0.02\) s. Desired world-frame offsets are
\(r_i\in\mathbb R^3\), with \(r_1=0\). Define leader-frame errors

\[
e_i(k)=p_i(k)-p_1(k)-r_i,
\qquad
w_i(k)=v_i(k)-v_1(k).
\]

`computeSwarmMetrics.m` reports the follower position error
\(\|e_i(k)\|\). The reported formation RMSE is the RMS over all followers and
all samples at or after the declared evaluation start (8 s in EXP10). It is
not the same quantity as the instantaneous stacked Lyapunov state.

Let \(A_f\) be the follower--follower submatrix of `cfg.swarm.A`,
\(L_f=\operatorname{diag}(A_f\mathbf 1)-A_f\),
\(G=\operatorname{diag}(A_{i1})_{i\in\mathcal F}\), and
\(\Pi=\operatorname{diag}(\pi_i)_{i\in\mathcal F}\), where `cfg.swarm.pin`
stores \(\pi_i\). Ordinary adjacency to the leader and the separate pin stream
are distinct information/control channels in the code.

The optional row scaling is

\[
s_i=\begin{cases}2/d_i,&\text{degree normalization enabled and }d_i>0,\\
1,&\text{otherwise},\end{cases}
\qquad S=\operatorname{diag}(s_i).
\]

It is disabled in EXP10 and in the first theorem track.

## 3. Exact double-integrator plant

The implemented update is velocity-first semi-implicit Euler:

\[
v_i(k+1)=v_i(k)+h u_i(k),
\]

\[
p_i(k+1)=p_i(k)+h v_i(k+1)
=p_i(k)+h v_i(k)+h^2u_i(k).
\]

Hence, for one coordinate,

\[
x_i(k+1)=A_dx_i(k)+B_du_i(k),
\quad
A_d=\begin{bmatrix}1&h\\0&1\end{bmatrix},
\quad
B_d=\begin{bmatrix}h^2\\h\end{bmatrix}.
\]

The input coefficient is \(h^2\), not \(h^2/2\). The latter would describe
an exact zero-order-hold discretization of continuous double-integrator
dynamics, not the code.

The outer command is norm-limited to `cfg.swarm.maxAccel`. The configured
`cfg.swarm.maxSpeed` is never enforced and is not a valid invariant or proof
assumption.

## 4. Exact formation controller

Receiver \(i\)'s last accepted estimate of neighbor \(j\) is
\(\hat x_{ij}=[\hat p_{ij}^\top,\hat v_{ij}^\top]^\top\). Its separate pinned
leader stream contains
\((\hat p^L_{i1},\hat v^L_{i1},\hat a^L_{i1})\). Before acceleration
saturation, the implemented command is

\[
\begin{split}
u_i={}&-K_ps_i\sum_jA_{ij}
\left[(p_i-\hat p_{ij})-(r_i-r_j)\right]\\
&-K_vs_i\sum_jA_{ij}(v_i-\hat v_{ij})\\
&-\pi_iK_{pL}\left[(p_i-\hat p^L_{i1})-r_i\right]
-\pi_iK_{vL}(v_i-\hat v^L_{i1})
+\pi_i\hat a^L_{i1}.
\end{split}
\]

For exact current information, define

\[
H_p=K_pS(L_f+G)+K_{pL}\Pi,
\qquad
H_v=K_vS(L_f+G)+K_{vL}\Pi.
\]

The ideal unsaturated command stacked over followers is

\[
u_F^\star(k)=-H_pe(k)-H_vw(k)+\Pi\mathbf1 a_1(k),
\]

applied independently to each Cartesian coordinate.

### Communication-induced command perturbation

Define receiver error using sender truth minus receiver memory:

\[
\tilde p_{ij}=p_j-\hat p_{ij},
\qquad
\tilde v_{ij}=v_j-\hat v_{ij}.
\]

For exact local self-state, the pre-saturation stale-minus-ideal command is

\[
\begin{split}
d^c_i={}&-K_ps_i\sum_j A_{ij}\tilde p_{ij}
-K_vs_i\sum_j A_{ij}\tilde v_{ij}\\
&-\pi_iK_{pL}\tilde p^L_{i1}
-\pi_iK_{vL}\tilde v^L_{i1}
+\pi_i(\hat a^L_{i1}-a_1).
\end{split}
\]

This identity supplies the control-relevance map for Gate 3. In estimator
experiments the controller also receives `PHat/VHat` for its own state, so
local estimation-error terms must be added; the first theorem does not silently
drop them.

## 5. Exact sampled formation-error update

Let \(m=N-1\), stack follower errors by one coordinate, and use the
dimensionally homogeneous state

\[
y_k=\begin{bmatrix}e_k\\h w_k\end{bmatrix}\in\mathbb R^{2m}.
\]

The leader is not integrated by the double-integrator update. At each sample it
is overwritten by the analytical `leaderReference`. Therefore two exact
leader-step residuals are required. Define

\[
\chi_k=\mathbf1\left(hv_1(k+1)-[p_1(k+1)-p_1(k)]\right),
\]

and the scaled velocity input

\[
\upsilon_k=h^2d^c_k+h^2\Pi\mathbf1 a_1(k)
-h\mathbf1[v_1(k+1)-v_1(k)].
\]

Then the exact unsaturated implemented update is

\[
y_{k+1}=A_hy_k+D_h
\begin{bmatrix}\chi_k\\\upsilon_k\end{bmatrix},
\]

\[
A_h=\begin{bmatrix}
I-h^2H_p&I-hH_v\\
-h^2H_p&I-hH_v
\end{bmatrix},
\qquad
D_h=\begin{bmatrix}I&I\\0&I\end{bmatrix}.
\]

### Proven Identity 1 — exact one-step model

The displayed update is algebraically identical to the double-integrator path
of `distributedFormationPolicy` plus `integrateFollowers` whenever the command
is unsaturated and local state is exact.

**Proof.** Substitute
\(u_F=-H_pe-H_vw+\Pi\mathbf1a_1+d^c\) into
\(v_F(k+1)=v_F(k)+hu_F(k)\), subtract the analytical leader velocity at
\(k+1\), and multiply the resulting relative-velocity equation by \(h\).
Next use
\(p_F(k+1)=p_F(k)+hv_F(k+1)\), subtract the analytical leader position at
\(k+1\), and add/subtract \(hv_1(k+1)\). Collecting terms gives exactly
\(A_h,D_h,\chi_k,\upsilon_k\). No continuous-time approximation is used.
\(\square\)

`utils/auditFormationSampledStep.m` checks this identity against the real
controller and integrator at a time-varying-acceleration takeoff point and a
circular-flight point.

### Correction to the older shorthand

The continuous-time expression \((\Pi-I)a_1\) is not an exact sampled leader
input unless
\(v_1(k+1)-v_1(k)=ha_1(k)\). `leaderReference` is analytical and has changing
acceleration, so the equality generally fails. The exact input is
\(h^2\Pi a_1(k)-h\Delta v_1(k)\), as above. Gate 1 retains the observed
nonzero discrepancy of the shorthand rather than calling it numerical noise.

## 6. Packet, receiver, and causal-information state

For DATA sent by source \(j\) to receiver \(i\), packet \(n\) contains

\[
(n,g_j^n,p_j(g_j^n),v_j(g_j^n)),
\]

plus acceleration on the pinned-leader payload class. `genTime` and `seq` are
packet header fields. The receiver accepts a packet only when its generation
time is newer than its stored generation; reordered obsolete packets are
discarded.

Let

\[
g_{ij}(k)=\max\{g_j^n:\text{packet }n\text{ was accepted by }i
\text{ by }t_k\}.
\]

The controller uses zero-order hold:

\[
\hat x_{ij}(k)=x_j(g_{ij}(k))
\]

in the exact-state arm. No model-based prediction occurs.

Let \(c_{ij}(k)\) be the newest generation time causally confirmed to sender
\(j\) by an arrived ACK. The simulation logs

\[
\Delta_{ij}^{log}(k)=t_k-g_{ij}(k)+h/2,
\]

\[
\widehat\Delta_{ij}^{log}(k)=t_k-c_{ij}(k)+h/2.
\]

The physical elapsed staleness used in a sampled bound is
\(a_{ij}=t_k-g_{ij}\), i.e.
\(a_{ij}=\Delta_{ij}^{log}-h/2\), not the displayed log value itself.

### Proven Lemma 1 — causal age conservatism

With consistent initialization, newest-generation receiver acceptance, honest
ACK creation only after DATA acceptance, and monotone sender confirmation,

\[
c_{ij}(k)\le g_{ij}(k),
\qquad
\widehat\Delta_{ij}^{log}(k)\ge\Delta_{ij}^{log}(k).
\]

**Proof.** Equality holds at initialization. Receiver DATA acceptance may
increase \(g_{ij}\). An ACK may increase \(c_{ij}\) only after the named DATA
has already increased receiver knowledge, and rollback/future/unknown ACKs are
rejected. Hence the order is invariant. Subtracting both generation times from
the same \(t_k+h/2\) gives the age inequality. \(\square\)

This is an information-integrity result, not security against spoofed ACKs.

## 7. Within-sample event order

The causal simulator executes the following order at each outer tick:

1. overwrite leader truth from `leaderReference(t_k)`;
2. evaluate the optional estimator for current local/transmitted state;
3. deliver ACKs already due;
4. deliver DATA already due and enqueue causal ACKs;
5. evaluate the trigger using sender-available information;
6. deliver newly generated zero-delay DATA in the same tick;
7. compute formation control from local estimate and newest receiver memory;
8. log state, command, age, and counters;
9. if not at the terminal sample, integrate followers one outer step.

This ordering means zero-delay DATA generated at \(t_k\) can affect the
controller at \(t_k\), while its ACK cannot arrive earlier than \(t_k+h\).
Delay values are stored continuously in `arrivalTime` but acceptance occurs at
the first outer tick satisfying `arrivalTime <= t_k + tolerance`.

## 8. Communication laws represented in the current evidence

For EXP10, forward DATA loss is a pre-drawn IID uniform compared with the
scenario probability. Base delay is 0/0.08/0.12 s for
Clean/Moderate/Stressed; jitter is zero. The reverse channel has its own trace,
loss, delay, and jitter. Hence delay/loss enter the controller through the
accepted generation and receiver memory; once \(g_{ij}(k)\) is known, they need
not appear as duplicate additive terms in a staleness bound.

EXP11 makes the same three loss/delay regimes piecewise constant within one
mission. Later shared-medium code adds service and collision. Infinite-horizon
deterministic AoI boundedness does not follow from any nonzero random loss
probability or from `maxSilence`.

## 9. Candidate assumptions for Gates 2--3

These assumptions are frozen as candidates. Gate 2 or 3 may reject them, but
must not silently strengthen them after results are seen.

**A1 — sampled analytical subsystem.** Followers obey the exact
semi-implicit double-integrator update at fixed \(h>0\). The 6-DOF cascade is a
separate validation system.

**A2 — fixed constant formation interval.** Desired offsets and controller
gains are constant on a theorem interval. Formation switches will be treated as
declared exogenous jumps or piecewise intervals, not hidden inside a stationary
proof.

**A3 — graph and grounding.** The first result uses a fixed undirected follower
graph, binary adjacency/pins, and every follower component is grounded by an
ordinary leader edge or pin. Directed/switching extensions need a separate
certificate.

**A4 — nominal sampled stability.** The exact configured \(A_h\) is Schur.
Continuous-time Hurwitz stability alone is insufficient.

**A5 — causal ZOH receiver.** The receiver accepts newest-generation DATA only
and holds the accepted position/velocity; sender confirmation obeys Proven
Lemma 1.

**A6 — exact local/payload state in the first theorem.** Local self-state and
transmitted payload are exact. Estimator/noise experiments are later extensions
with explicit error terms.

**A7 — bounded applied acceleration for uncertainty.** On the declared
interval, \(\|u_j(k)\|\le\bar a_j\). For the double integrator the implemented
command saturation supplies a physical acceleration bound even outside the
linear proof region.

**A8 — finite-horizon velocity envelope.**
\(\|v_j(k)\|\le\bar v_j\) is derived from initial velocity and A7 over a
declared finite horizon, or fixed from a physical operating envelope before
held-out evaluation. It is not inferred from the dead `maxSpeed` field.

**A9 — unsaturated linear formation region.** The Gate-3 LTI ISS result applies
only where ideal and stale-information commands do not hit acceleration
saturation. Every validating trajectory reports the saturation margin. Failure
requires a nonlinear/sector/UUB analysis.

**A10 — bounded leader step residuals.** The analytical leader has bounded
\(\chi_k\) and exact scaled velocity residual
\(h^2\Pi a_1(k)-h\Delta v_1(k)\) over the declared mission.

**A11 — finite-horizon network statement.** Random loss/delay claims are
finite-horizon probability statements or conditioned on a declared age cap.
No deterministic infinite-horizon AoI bound is assumed.

**A12 — development/holdout separation.** Motion envelopes, Lyapunov metric,
distributed budget decomposition, and trigger parameters are fixed using
development scenarios/seeds before final held-out data are opened.

## 10. Gate-2 staleness-to-uncertainty result

For a payload generated \(q\) outer steps ago, semi-implicit integration gives
the exact telescoping relations

\[
v_j(k)-v_j(k-q)=h\sum_{r=0}^{q-1}u_j(k-q+r),
\]

\[
p_j(k)-p_j(k-q)=qh\,v_j(k-q)
+h^2\sum_{r=0}^{q-1}(q-r)u_j(k-q+r).
\]

### Proven Lemma 2 — exact-state ZOH staleness envelope

Under A1, A5--A7, suppose follower $j$'s accepted payload was generated
at $k-q$. Then

\[
\|v_j(k)-\hat v_{ij}(k)\|\le qh\bar a_j,
\]

\[
\|p_j(k)-\hat p_{ij}(k)\|
\le qh\|\hat v_{ij}(k)\|
+\frac{h^2\bar a_j}{2}q(q+1).
\]

**Proof.** Apply the triangle inequality to the two exact telescoping
relations above. The receiver's ZOH value is exactly the state at $k-q$
under A5--A6, and every acceleration norm is bounded by A7. The weighted sum
of acceleration coefficients is
\(\sum_{r=0}^{q-1}(q-r)=q(q+1)/2\). \(\square\)

This local envelope is not an oracle quantity: the receiver already holds the
accepted payload velocity whose norm appears in it. It therefore maps physical
information age to a state-error budget using only accepted information and a
hard plant input bound.

If payload position and velocity errors at generation are bounded by
\(\bar\eta_p,\bar\eta_v\), respectively, the same proof gives

\[
E_v(q)=\bar\eta_v+qh\bar a_j,
\]

\[
E_p(q)=\bar\eta_p+qh(\|\hat v_{ij}\|+\bar\eta_v)
+\frac{h^2\bar a_j}{2}q(q+1).
\]

If only AoI and the finite-horizon A8 envelope are retained, replacing
\(\|\hat v_{ij}\|\) by \(\bar v_j\) gives a valid age-only bound. For the
current implementation this is expected to be much looser because
`cfg.swarm.maxSpeed` is not enforced. A constant-velocity predictor could
change the error recursion, but that predictor is not implemented and is not
part of Lemma 2.

`utils/tcnsZohStalenessBound.m` implements these formulas and refuses a
physical age that is not an integer multiple of $h$. The simulator's logged
age is converted by

\[
q=\operatorname{round}\left(
\frac{\Delta_{ij}^{log}-h/2}{h}\right),
\]

only after the grid-alignment residual has been checked.

### Proven Lemma 3 — implemented analytical-leader envelope

The current `leaderReference.m` is a cubic vertical takeoff for $t<3$ s and a
radius-1 circular trajectory with angular rate 0.2 rad/s for $t\ge3$ s.
Position is continuous at the switch, while velocity and acceleration have
jump magnitudes

\[
J_v=0.2,\qquad J_a=\sqrt{0.8^2+0.04^2}.
\]

Direct differentiation on the two smooth segments gives

\[
\|v_L\|\le0.6,\qquad \|a_L\|\le0.8,\qquad
\|\dot a_L\|\le8/15.
\]

For a stale interval from generation time $g$ to current time $t$, let
$I_3(g,t)$ equal one when $g<3\le t$ and zero otherwise. The ordinary leader
position/velocity payload and pinned position/velocity/acceleration payload
then satisfy

\[
E^L_p(g,t)=0.6(t-g),
\]

\[
E^L_v(g,t)=0.8(t-g)+J_vI_3(g,t),
\]

\[
E^L_a(g,t)=\frac{8}{15}(t-g)+J_aI_3(g,t).
\]

**Proof.** Integrate the respective derivative norm on each smooth segment
and apply the triangle inequality. Position has no jump. Velocity and
acceleration each add their single switch jump exactly when the stale interval
crosses 3 s. The constants above are maxima obtained directly from the two
closed-form branches. \(\square\)

`utils/tcnsLeaderStalenessBound.m` implements Lemma 3. Keeping the jump terms
is necessary: applying the follower double-integrator envelope across the
leader switch would be mathematically false.

**PROOF GAP G2.1 — numerical coverage/tightness.** The algebra is complete,
but a committed run must still measure coverage and conservatism over actual
receiver trajectories and fixed development seeds. This gap closes only when
the executable result is recorded, not merely because the formula has been
implemented.

**PROOF GAP G2.2 — sender-side distributed budget.** Lemma 1 makes confirmed
age conservative, but the sender does not automatically know the velocity in
the receiver's latest accepted payload. A sender-implementable bound must use
confirmed payload history or a pre-frozen global envelope. This decomposition
belongs to Gate 3--4 and must not read receiver truth.

## 11. Gate-3 candidate result and exact gap

If \(A_h\) is Schur, then for any \(Q\succ0\) there is a unique
\(P\succ0\) satisfying

\[
A_h^\top P A_h-P=-Q.
\]

Expanding \(V_k=y_k^\top Py_k\) under the exact input in Section 5 can yield an
ISS/UUB inequality with respect to communication and leader-step inputs. This
is a theorem target, not yet a completed TCNS theorem.

**PROOF GAP G3.1.** The existing generic \(Q=I\)/Young bound has transient gain
about 93.44 and input gain about \(5.18\times10^6\) for the default cell. It is
logically valid but numerically useless. A tighter metric or finite-horizon
reachable/induced bound is required.

**PROOF GAP G3.2.** A global disturbance budget must be decomposed into
sender/link quantities available without receiver truth or future channel
outcomes. Otherwise it cannot define a distributed causal trigger.

**PROOF GAP G3.3.** The first LTI result does not cover acceleration
saturation, the 6-DOF cascade, directed/switching graphs, Gaussian estimation
noise, or topology disconnection.

**PROOF GAP G3.4.** Formation RMSE is a time/follower average of position error;
a pointwise stacked-state UUB must be translated carefully rather than called
an RMSE bound without proof.

## 12. Gate-1 executable evidence

`experiments/tcns_gate1_model_audit.m` exports the exact matrices, configuration,
and two real one-step comparisons. Gate 1 passes only if:

- the real controller equals \(-H_pe-H_vw+\Pi a_1\) below saturation;
- the real integrator equals the corrected sampled matrix update to numerical
  precision;
- the fixtures remain strictly unsaturated;
- the experiment actually distinguishes the corrected analytical-leader input
  from the older Euler shorthand;
- the directed-graph fixture does not inherit the symmetric theorem.

This gate establishes a trustworthy model. Gate 2 builds on it; neither gate
establishes the Gate-3 robustness theorem.
