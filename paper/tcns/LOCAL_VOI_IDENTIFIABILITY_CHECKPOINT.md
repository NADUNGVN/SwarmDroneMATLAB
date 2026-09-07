# Sender-local VoI identifiability checkpoint

**Decision:** `LOCAL_VALUE_SIGN_NOT_IDENTIFIED`

**Scope:** exact Gate-3 fixed, symmetric, grounded, exact-state,
unsaturated double-integrator degradation model. This checkpoint analyzes the
information required to determine one action's quadratic marginal value. It
does not introduce or tune a communication policy.

## 1. Why this checkpoint is necessary

The receiver-truth diagnostic established a time-varying isolated update
signal, but the causal online policy did not allocate actions around the
frozen S2/S6 event windows and did not beat the complete matched periodic
frontiers. Its score used only the energy of the response caused by a
candidate packet. The missing term is not a small implementation detail: it
can reverse whether the action helps or hurts the total formation objective.

## 2. Exact finite-horizon decomposition

Stack the follower formation-error response over the next \(H\) samples into

\[
Z=\operatorname{col}(\delta e(k+1),\ldots,\delta e(k+H)).
\]

For a successful update on a link entering follower \(i\), let the persistent
command change after \(D\) samples be \(c_i\in\mathbb R^3\). From the exact
Gate-3 recurrence, its action-induced output response is

\[
G=\mathcal T_{H,D}^{(i)}c_i,
\]

where \(\mathcal T_{H,D}^{(i)}\) is formed from the appropriate columns of
\(A_h^rB_c\). This is exactly the response computed by
`tcnsFiniteHorizonLinkValueKernel`.

Let \(Z\) denote the no-action response containing the current formation error,
leader residual, other-link disturbances, and any fixed future decisions.
If the action changes that response to \(Z+G\), its total quadratic benefit is

\[
\begin{aligned}
\mathcal B(Z,G)
&=\|Z\|_F^2-\|Z+G\|_F^2\\
&=-2\langle Z,G\rangle_F-\|G\|_F^2.
\end{aligned}
\]

This identity is exact. Division by the number of follower/sample entries to
obtain an MSE changes only scale, not sign.

## 3. Proven Proposition IV-1 -- local sign-identifiability condition

Let \(\mathcal I_j(k)\) be the information available to sender \(j\), and let
\(\mathcal Z(\mathcal I_j)\) be the set of no-action responses compatible with
that information. Suppose \(G\ne0\) is fixed by the considered action and
sender information. Define

\[
q_{\min}=\inf_{Z\in\mathcal Z}\langle Z,G\rangle_F,
\qquad
q_{\max}=\sup_{Z\in\mathcal Z}\langle Z,G\rangle_F.
\]

Then:

1. the action is certified beneficial for every compatible response iff
   \(q_{\max}< -\|G\|_F^2/2\);
2. the action is certified non-beneficial for every compatible response iff
   \(q_{\min}\ge -\|G\|_F^2/2\);
3. if the interval \([q_{\min},q_{\max}]\) crosses
   \(-\|G\|_F^2/2\), its benefit sign is not identifiable from
   \(\mathcal I_j(k)\).

**Proof.** The exact decomposition gives
\(\mathcal B>0\iff\langle Z,G\rangle_F<-\|G\|_F^2/2\). Taking the supremum or
infimum over the compatible set proves the first two statements. If the
projection set contains points on both sides of the threshold, those points
have identical sender information but opposite action-value signs, proving
the third. \(\square\)

### Exact algebraic witness

Choose any nonzero response \(G\). Two compatible hidden baseline candidates,
if admissible, are

\[
Z_-=-G,\qquad Z_+=+G.
\]

They give

\[
\mathcal B(Z_-,G)=\|G\|_F^2>0,
\qquad
\mathcal B(Z_+,G)=-3\|G\|_F^2<0.
\]

`tcnsLocalVoiIdentifiabilityWitness` constructs \(G\) from the exact
implemented Gate-3 matrices and verifies both identities numerically. This is
not a generic vector chosen outside the model's output space.

## 4. What the current sender knows and does not know

For an ordinary \(j\to i\) transmission, the current causal score knows:

- sender \(j\)'s current payload;
- ACK-confirmed receiver payload and outstanding link history;
- the narrow-scope link posterior;
- link success probability and deterministic sampled delay;
- controller gains and the isolated action-response kernel.

It does not know the full no-action response \(Z\). In the implemented ring,
a follower controller receives more than one ordinary input and may also use
the independent pinned-leader stream. \(Z\) therefore contains receiver
state/error, other-link communication disturbances, and future closed-loop
effects that are not functions of sender \(j\)'s local payload/ACK history.
The score \(\mathbb E\|G\|^2\) cannot reconstruct
\(\mathbb E\langle Z,G\rangle\).

This explains the scientific boundary between the two completed diagnostics:
time-varying isolated response energy can exist while total marginal value is
not recoverable by thresholding that energy.

## 5. Minimal missing information

For a deterministic candidate response \(G\), the scalar

\[
s=\langle Z,G\rangle_F
\]

is sufficient to recover the exact sign and magnitude of the quadratic
benefit; the full future vector \(Z\) need not be sent to the decision maker.
Under packet-success and receiver-belief branching, the corresponding
conditional expected cross term is required. This identifies a precise
information target for any richer architecture: an action-conditioned
control residual or adjoint/costate projection, not another generic AoI or
state-error weight.

It does not yet prove that this scalar can be computed distributively with
acceptable communication overhead.

## 6. Explicit proof gaps

**PROOF GAP IV.1 -- dynamically consistent indistinguishable histories.**
The executable witness proves the exact output-space algebra. A full
impossibility theorem for the implemented swarm still requires constructing
two complete admissible plant/network histories with identical
\(\mathcal I_j(k)\) and projections on opposite sides of the threshold. The
current multi-input model makes this plausible but the reachability argument
has not been completed.

**PROOF GAP IV.2 -- stochastic branching.** Existing in-flight packets make
\(Z\) and \(G\) random and potentially correlated. The exact sufficient
statistic is then an action-conditioned expectation, not a product of their
separate expectations.

**PROOF GAP IV.3 -- endogenous future actions.** The decomposition is exact
for fixed future decisions. Receding decisions change both branches and need
a dynamic-programming, rollout, or controlled approximation argument.

**PROOF GAP IV.4 -- distributed computability and overhead.** No causal
low-overhead mechanism has yet been shown to generate the required cross-term
statistic. Adding it may consume enough reverse/control traffic to erase any
communication advantage.

**PROOF GAP IV.5 -- extended dynamics and saturation.** The checkpoint
inherits the Gate-3 theorem scope and does not prove the identity across
saturation, 6-DOF inner-loop dynamics, or switching topology.

## 7. Research decision

The failed sender-local predictive mechanism remains stopped. No third scalar
threshold using only AoI, sender state error, or isolated response energy is
scientifically authorized.

The next smallest defensible experiment is an **offline centralized
cross-term oracle audit** on already defined development scenarios. It must
measure the true branch-wise quadratic marginal benefit and answer two
questions before any new online design:

1. Does the cross term materially change action ranking/sign relative to the
   isolated score?
2. Does an oracle using the total marginal benefit exhibit Pareto headroom
   over periodic communication before charging the extra information needed
   to approximate it?

If the answer is no, the mechanism family should stop. If yes, only then is a
receiver-residual/adjoint information architecture worth designing and its
reverse-channel overhead must be included in every comparison.
