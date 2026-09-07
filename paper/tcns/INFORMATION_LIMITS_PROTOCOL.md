# Information-structure limits protocol

**Status:** frozen before numerical rank/reachability results  
**Track:** `INFORMATION_STRUCTURE_LIMITS`  
**Policy engineering:** closed

## 1. Scope and question

The analysis is restricted to the existing Gate-3 exact-state, unsaturated,
sampled double-integrator model with the fixed symmetric grounded N=5 graph.
The finite-horizon value uses the frozen O1 horizon \(H=25\) and sampled DATA
delay \(D=4\).  No trigger or scheduler is designed.

Question:

> Is the exact finite-horizon control value of one communication action a
> function of the information genuinely available to its sender, and if not,
> what is the smallest additional linear statistic that makes it so?

## 2. Primitive augmented state

Analyze one Cartesian coordinate first.  Let \(m=N-1\), let
\(\mathcal E\) enumerate ordinary controller links \((i,j)\), and let
\(\mathcal P\) enumerate pinned-leader memories.  Use position-scaled
variables

\[
\xi^a=\operatorname{col}\left(
e^a,;h w^a,;p_L^a,;h v_L^a,;h^2a_L^a,
\{\hat p_{ij}^a,h\hat v_{ij}^a\}_{(i,j)\in\mathcal E},
\{\hat p_{iL}^a,h\hat v_{iL}^a,h^2\hat a_{iL}^a\}_{i\in\mathcal P}
\right).
\]

The three-dimensional state is

\[
\xi=\operatorname{col}(\xi^x,\xi^y,\xi^z).
\]

This contains exactly the physical relative state, leader variables, and
receiver memories required to reconstruct the current communication residual
and O1 baseline.  Packet queues, loss uniforms, future reference samples,
ACKs, counters, and simulator bookkeeping are excluded.

## 3. Frozen affine maps

The implementation-derived matrices must satisfy

\[
\operatorname{vec}_t(Z_k)=F_H\xi_k+r_H,
\]

where \(\operatorname{vec}_t\) stacks all followers at time \(k+1\), then all
followers at \(k+2\), and so on, separately by Cartesian coordinate.

For a fixed payload/link/hypothesis with exact action response \(g\), define

\[
\Xi=\langle Z,G\rangle=g^T(F_H\xi+r_H)
=\ell^T\xi+c.
\]

The receiver-memory coordinates fixed by the considered hypothesis are
substituted exactly and removed from the free state.  For belief weighting,
candidate-specific affine maps are averaged as

\[
\bar\ell=\sum_s b_s\ell_s,
\qquad
\bar c=\sum_s b_sc_s,
\]

without evaluating the nonlinear action value at an expected receiver state.

## 4. Strongest realistic sender information

At the decision instant, sender \(j\)'s deterministic observation contains:

- its exact physical position and velocity;
- every receiver memory feeding its own local controller;
- its pinned-leader memory when pinned;
- its stateless unsaturated controller command, included even though it is a
  linear combination of the preceding variables;
- for the leader, its exact reference position, velocity, and acceleration;
- known graph, gains, offsets, time, channel law, and its sent-packet history
  as affine constants or fixed action/hypothesis data.

It does not contain receiver \(i\)'s physical state or memories stored at
other agents unless those values are present in the listed local inputs.
The map is written \(o_j=C_j\xi+d_j\).

For finite-history analysis, receiver memories are held and no new packet is
delivered over a declared interval.  This is an admissible positive-
probability erasure history.  The exact held-memory affine dynamics yield

\[
\mathcal O_{j,L}=\operatorname{col}
(C_j,C_jA,\ldots,C_jA^L).
\]

Use the complete finite observability horizon \(L=n_r-1\), where \(n_r\) is
the dimension after substituting the fixed candidate receiver memory.  This
does not artificially discard useful local history.

## 5. Numerical application rules

- graph/configuration: frozen N=5 Gate-3 configuration;
- all 8 ordinary links and both pinned-leader payloads are evaluated;
- structural action response: unit correction along one Cartesian axis;
- both instantaneous and complete held-memory history maps are reported;
- rank tolerance:
  \(10^{-10}\max(1,\sigma_{\max}(C))\);
- row-space residual:
  \(\|(I-C^\dagger C)\ell\|_2\), plus normalization by
  \(\max(\|\ell\|_2,\epsilon)\);
- receiver-only, sender+receiver, and all-agent stacked information maps are
  checked to locate who can compute the missing statistic.

A zero action response is excluded because its value is trivially zero.

## 6. Dynamic reachability construction frozen in advance

Construct two full MATLAB histories for each of two leader-originated payload
classes:

1. ordinary neighbor link \(1\to5\);
2. pinned-leader payload \(1\to4\).

The leader has no incoming formation edges in the implemented graph.  It
follows the same small constant-velocity trajectory in both histories.  At
time zero receiver memories are initialized consistently from each history's
true state.  Thereafter no DATA is delivered during the finite witness
interval; equivalently all scheduled attempts in that interval are erased.
This channel event has nonzero probability under the declared IID law.

Follower initial conditions may differ along an unobservable direction, but
the complete leader observation history, leader sent-packet history,
candidate receiver memory, ACK-free belief, and candidate action response
must remain identical.  Initial perturbations and leader velocity are scaled
before execution, not tuned against empirical trajectories.

Dynamic closure passes only if:

- both histories are generated by the existing formation controller and
  `integrateFollowers` double-integrator path;
- every pre-saturation follower command remains strictly below
  `cfg.swarm.maxAccel`;
- leader observation histories agree to \(10^{-10}\);
- candidate action responses agree to \(10^{-10}\);
- exact O1 values have opposite nonzero signs;
- the augmented affine model matches the full MATLAB histories to
  \(10^{-10}\).

Failure is retained as `PROOF GAP`; the construction may not be rescued by
changing link, graph, horizon, or information map after viewing results.

## 7. Classification frozen before results

`LIMITS_THEORY_STRONG` requires:

- a rigorous affine identifiability iff theorem;
- non-identifiability on the actual graph for every nonzero evaluated link
  action under the strongest sender map;
- successful dynamically reachable opposite-sign histories for both frozen
  payload classes;
- a proved minimal supplementary-statistic characterization, including the
  multi-action rank extension;
- a feedback-economic break-even corollary tied to FB0.

`LIMITS_THEORY_PARTIAL` applies if the iff theorem is rigorous but dynamic
sign closure or the minimal-information characterization remains incomplete.

`LIMITS_THEORY_WEAK` applies if the result reduces to only observing that a
sender lacks global state, without a nontrivial row-space, sign, dynamic, or
minimal-information result.

No policy, held-out evaluation, scalability run, or manuscript claim
expansion is authorized by this protocol.

