# Causal receiver-belief and one-shot VoI checkpoint

**Decision:** `ALGEBRA_READY_IN_NARROW_SCOPE`

**Role:** post-Gate-6 theory checkpoint before any second online policy is
implemented.

## 1. Scope and information set

This checkpoint retains the exact Gate-3 sampled formation model and adds a
narrow communication model in which an exact sender posterior is tractable.
The assumptions are deliberately stronger than the final desired network
scope and are enforced by code, not hidden.

**B1 -- static IID forward loss.** Each attempted DATA packet succeeds
independently with probability \(q=1-p\), fixed over the diagnostic interval.

**B2 -- deterministic sampled DATA delay.** A packet sent at sample \(k\) is
eligible for receiver delivery at \(k+d_f\), where \(d_f\) is the ceiling of
the configured continuous delay in outer samples.

**B3 -- reliable deterministic ACK.** Every newly accepted receiver sequence
generates a cumulative ACK that is delivered exactly \(d_a\) samples later;
ACK loss and jitter are zero.

**B4 -- ordered receiver semantics.** The receiver retains the greatest
successfully delivered sequence number. ACK processing is monotone and
cumulative, as proved in Gate 3.

**B5 -- protocol-complete outstanding history.** No outstanding record is
discarded on timeout. The sender stores sequence, generation time and payload
state for every unacknowledged transmission.

**B6 -- no availability side state.** Topology faults, radio blackouts,
time-varying regimes, Gilbert--Elliott state and delay jitter are outside this
first exact posterior.

The sender filtration contains its current payload state, the cumulative
ACK-confirmed payload and sequence, all later outstanding sent records, the
current sample time, and B1--B3. It excludes receiver registers, realized DATA
loss flags and future trace values.

## 2. Exact conditional receiver distribution

At decision sample \(k\), let \(n_a\) be the cumulative ACK-confirmed sequence
and let \(\mathcal O_k\) contain later outstanding records. For record \(n\)
sent at \(s_n\):

- if \(k-s_n\ge d_f+d_a\), reliable ACK absence proves that the DATA was not
  accepted; its conditional delivery probability is zero;
- otherwise ACK absence supplies no information yet;
- at a prediction sample \(\tau\), a still-uncertain record is an eligible
  Bernoulli candidate only if \(\tau-s_n\ge d_f\).

Let eligible uncertain sequences be ordered
\(n_1<\cdots<n_r\), with success probabilities \(q_l=q\). Because the
receiver keeps the newest success,

\[
\Pr[X_R(\tau)=X^{n_l}\mid\mathcal F_k]
=q_l\prod_{u=l+1}^r(1-q_u),
\]

and

\[
\Pr[X_R(\tau)=X^{n_a}\mid\mathcal F_k]
=\prod_{u=1}^r(1-q_u).
\]

### Lemma PV-1 -- exact narrow-scope posterior

Under B1--B6, the probabilities above are the exact conditional distribution
of the receiver-held payload at \(\tau\), given the sender information at
sample \(k\).

**Proof.** For any record whose round-trip deadline has passed, acceptance
would have generated a reliable ACK already visible at the sender; remaining
outstanding therefore implies DATA failure. For every younger record, an ACK
cannot yet have arrived, so ACK absence does not condition its independent
forward Bernoulli outcome. The receiver holds candidate \(n_l\) exactly when
\(n_l\) succeeds and every newer eligible candidate fails. It holds the
confirmed candidate exactly when every eligible candidate fails. These
disjoint events exhaust the sample space and yield the displayed products.
\(\square\)

`tcnsCausalReceiverBelief.m` implements the distribution. It rejects every
scope extension listed in B6 and reports `usesReceiverTruth=false` and
`usesDropOutcome=false`.

## 3. Existing in-flight value and a new action

Consider a new current-state packet sent at \(k\). If successful, it arrives
at \(k+d_f\) and, because it has the greatest sequence, replaces whichever
candidate would otherwise be held then. Let \(X^c\) denote a candidate from
Lemma PV-1 and define the resulting controller-command correction on ordinary
link \(j\to i\) as

\[
c_{ij}(X^c)=K_ps_i[p_j(k)-p(X^c)]
            +K_vs_i[v_j(k)-v(X^c)].
\]

For a pinned-leader stream, add
\(a_L(k)-a(X^c)\). The position, velocity and acceleration coefficients are
exact implemented controller gains; no fitted AoI/state weights are added.

Let \(\kappa_i(H,d_f)\) be the persistent-update kernel frozen and validated
in the oracle signal diagnostic. Define

\[
\nu_{ij}(k)=q\,\kappa_i(H,d_f)
\mathbb E[\|c_{ij}(X_R(k+d_f))\|_2^2\mid\mathcal F_k]/(N-1).
\]

### Lemma PV-2 -- expected isolated action value

Suppose the new packet is the only new action on this link over the horizon,
all other link inputs are identical between continuations, and both
continuations remain in the unsaturated Gate-3 model. Under B1--B6,
\(\nu_{ij}\) equals the expected accumulated follower-position MSE separation
between the no-action and successful-action branches, including the action's
loss probability.

**Proof.** Condition on the mutually exclusive receiver candidates from
Lemma PV-1. If the new DATA fails, branch separation is zero. If it succeeds,
the held-payload difference and hence the link's command correction remain
constant until a later link update, which is excluded by premise. The exact
Gate-3 persistent-update identity gives
\(\kappa_i\|c_{ij}(X^c)\|^2/(N-1)\) in each candidate branch. Weighting by
the candidate probabilities and the independent new-DATA success probability
gives the displayed expression. \(\square\)

This formulation credits packets already in flight. For example, if one
uncertain outstanding packet contains exactly the current state and has
success probability 0.8, expected correction energy is only 0.2 of the
ACK-only value; a fixed retry rule cannot represent this reduction.

## 4. What the result does and does not establish

The value is causal and predictive in the narrow scope. It uses payload age
through eligibility/ACK deadlines, state content through directional command
correction, and closed-loop relevance through \(\kappa_i\). It does not add an
AoI term by hand.

It reduces to a controller-weighted ACK-state-error trigger when no packet is
outstanding. Therefore novelty cannot be claimed from that boundary. Its
distinct element is the probability-weighted set of outstanding payloads and
the exact finite-horizon receiver sensitivity; related-work comparison is
still required.

Most importantly, Lemma PV-2 is an isolated-action identity, not a theorem
that thresholding \(\nu_{ij}\) improves total formation cost. Other link
disturbances introduce quadratic cross terms, and future endogenous actions
change both branches.

## 5. Active proof gaps and stop rules

**PROOF GAP PV.5 -- lossy/delayed ACK posterior.** With ACK loss, a missing
ACK no longer identifies DATA failure. An augmented hidden-state filter is
required; B3 may not be silently retained in those experiments.

**PROOF GAP PV.6 -- jitter and time-varying channel belief.** Random delays
and Gilbert--Elliott loss require arrival hazards/channel-state belief rather
than deterministic eligibility.

**PROOF GAP PV.7 -- repeated-policy value.** Interacting future decisions and
multi-link cross terms prevent equating the one-shot score with the exact
global cost-to-go difference.

**PROOF GAP PV.8 -- saturation.** The finite-horizon kernel is not valid
through command saturation.

Stop before policy integration if the exact algebraic tests fail, if any
decision reads receiver/drop/future-trace state, or if the score does not
decrease when a useful current-state packet is likely to arrive.

If the tests pass, the smallest authorized policy is
\(\nu_{ij}(k)>\lambda\), with \(\lambda\) treated only as a frontier sweep
parameter. Its first experiment is restricted to one development seed in S2
and S6, with Periodic arms spanning the realized costs. No final acceptance
criterion or held-out evaluation is opened.

