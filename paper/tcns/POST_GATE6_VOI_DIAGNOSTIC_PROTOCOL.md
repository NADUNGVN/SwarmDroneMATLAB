# Post-Gate-6 predictive-VoI signal diagnostic protocol

**Classification:** theory-first mechanism reset on development data.

**Status at freeze:** protocol and code prepared; no diagnostic result has
been observed.

## Why this diagnostic is necessary

Gate 6 stopped the first control-aware policy after periodic frontiers
dominated it at every matched point in S1--S6. Its causal possible-set radius
is a valid uncertainty certificate, but its worst-case maximum remained large
until ACK contraction and produced nearly time-uniform traffic. Changing its
threshold or retry timer would not answer that mechanism failure.

The only permitted next policy direction is a genuinely marginal,
finite-horizon value calculation. Before implementing a causal receiver
belief, this diagnostic asks a cheaper necessary question:

> If receiver state were visible, would the isolated closed-loop value of one
> current-state payload actually concentrate during the two state-driven
> nonstationary events?

If the answer is no, building a probabilistic receiver belief cannot create
the missing signal.

## Exact isolated-action kernel

Use the proved Gate-3 recurrence

\[
\delta y_{k+1}=A_h\delta y_k+B_cd_k^c,
\qquad C_p=[I\;0].
\]

Suppose a packet delivered after \(D\) samples replaces one receiver's held
payload and thereby changes follower \(i\)'s command by the constant vector
\(c_i\) until the next update. With no other difference between the two
unsaturated continuations, define

\[
s_{i,r}(H,D)=C_p\sum_{q=0}^{r-D-1}A_h^qB_ce_i,
\]

where the sum is zero for \(r\le D\). Then

\[
\sum_{r=1}^{H}\|\delta e(k+r)\|_F^2
=\kappa_i(H,D)\|c_i\|_2^2,
\quad
\kappa_i=\sum_{r=1}^{H}\|s_{i,r}\|_2^2.
\]

This is an exact identity for the isolated update under the Gate-3 scope. It
is not total closed-loop VoI when other link disturbances differ, because
quadratic cross terms may be positive or negative.

For each ordinary link, the current-payload command correction is

\[
c_{ij}=K_ps_i(p_j-\hat p_{ij})+K_vs_i(v_j-\hat v_{ij}).
\]

The pinned-leader correction additionally contains
\(a_L-\hat a_{iL}\). The diagnostic score is

\[
\nu_{ij}=(1-p_{loss})\,\kappa_i(H,D)\|c_{ij}\|_2^2/(N-1).
\]

The static deterministic Moderate delay fixes \(D\). No channel-state oracle
or future trace is used in the multiplier.

## Frozen design

- Plant/controller: exact N=5 double-integrator subsystem and frozen
  controller from Gates 1--3.
- Communication arm: Periodic-10-step (0.20 s), not chosen by outcome.
- Channel: frozen Moderate model.
- Scenarios: S1 stationary negative control, S2 formation switching, and S6
  dynamic excitation. S3--S5 are excluded because this first diagnostic is
  about state-driven value; burst-state inference, time-varying channel
  knowledge, and unavailable links require separate beliefs.
- Development seeds: 27020001--27020005, already used in Gate 6.
- Evaluation interval: 8--30 s.
- Value horizon: H=25 samples=0.50 s.
- S2 event windows: 10--14 s and 20--24 s.
- S6 event windows: 12--16 s and 20--24 s.

Receiver memories are logged passively. A paired logging-on/off test must show
bitwise-identical plant, network, trace, and communication outputs.

## Metrics

For each seed and scenario, sum \(\nu_{ij}(k)\) over controller-relevant
links. Report:

1. temporal coefficient of variation over the evaluation interval;
2. fraction of total score inside the declared event windows;
3. event allocation ratio: score fraction divided by event-duration fraction;
4. top-decile score allocation ratio defined analogously.

## Frozen decision rule

The predictive direction is `SIGNAL_PRESENT` only if both S2 and S6 have:

1. five-seed mean event allocation ratio at least 1.25; and
2. five-seed mean coefficient of variation at least 25% greater than the
   paired S1 value.

Otherwise the result is `INSUFFICIENT_SIGNAL`, and a Bayesian/ACK receiver
belief scheduler is not implemented from this score.

Passing does **not** validate a policy. It only authorizes the next derivation:
replace receiver truth by a causal probability distribution over
ACK-confirmed and outstanding payload candidates, include the marginal value
of already in-flight packets, and freeze a small policy sanity test.

## Explicit proof gaps

**PROOF GAP PV.1 -- causal belief.** The oracle correction reads the actual
receiver register. An online sender must infer a posterior from ACK history,
the forward delay/loss law, and outstanding packets without reading drop
outcomes or receiver truth.

**PROOF GAP PV.2 -- competing in-flight packets.** The one-shot score ignores
packets already capable of updating the receiver. Their conditional arrival
value must be subtracted before this becomes a marginal action score.

**PROOF GAP PV.3 -- multi-link cross terms.** Isolated output energy is not
the exact change in total quadratic formation cost when other disturbances
are present.

**PROOF GAP PV.4 -- saturation and model scope.** The identity excludes
saturation, switching topology, 6-DOF dynamics, estimator error, and model
mismatch.

