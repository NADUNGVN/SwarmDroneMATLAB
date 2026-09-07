# AF0--AF1 exact ACK-free receiver-memory belief

**Scope:** S2 Formation-switching and S6 Dynamic-excitation development
scenarios only.  
**Status:** `AF0_AF1_PASS_WITH_DECLARED_SCOPE`; theory and implementation
contract frozen before AF2 calibration.  
**Active scheduling:** not authorized by this document.

## 1. Implemented channel semantics

Both S2 and S6 inherit the frozen Moderate network cell:

- outer sample interval \(h=0.02\) s;
- static IID DATA erasure probability \(p=0.20\) on each directed link and
  attempted sample;
- deterministic DATA delay \(d=0.08\) s, or \(d_s=4\) outer samples;
- no jitter, link fault, node blackout, or time-varying channel state;
- the receiver processes due packets before computing control and before its
  state is logged at that sample;
- the receiver accepts a packet only when its generation time is strictly
  newer than the generation time currently stored.

At \(t=0\), every controller-relevant receiver memory is initialized with the
corresponding exact state and generation identity 0.  Periodic DATA uses a
per-sender phase but every actual generation time lies on the outer sample
grid.

## 2. Assumptions

**AF-A1 -- common initial memory.** Sender and receiver share the identity and
payload of the receiver memory at time zero.

**AF-A2 -- ordered packet identities.** On each directed link, attempted DATA
packets have unique, strictly increasing sequence identities.  Their
generation and send times are nondecreasing in the same order.

**AF-A3 -- known static IID erasures.** Every attempted packet is erased
independently with probability \(p\in[0,1]\), known to the sender.

**AF-A4 -- known deterministic sampled delay.** Every non-erased packet sent
at sample \(n\) is processed by the receiver at sample \(n+d_s\), where
\(d_s\) is known and constant.

**AF-A5 -- newest-generation receiver.** Receiver memory contains the newest
generation among the initial packet and all successfully delivered packets.

**AF-A6 -- communication-only no-feedback filtration.** Define

\[
\mathcal I^{0,\mathrm{tx}}_j(k)=
\sigma\!\left(R_{ij}(0),\{a_{ij}(n),s_n,g_n,X_n\}_{n\le k},
k,p,d_s\right).
\]

It contains the sender's attempted packet identities, send/generation times,
payloads, current time, and channel law.  It contains no ACK, receiver
register, realized erasure flag, network trace, or future information.

The superscript `tx` is important.  This is a deliberately coarsened
communication filtration; it does not condition on indirect information
that a full closed-loop local-state history could carry about earlier packet
outcomes.  The PMF below is exact for \(\mathcal I^{0,\mathrm{tx}}_j\).  It is
not yet claimed to be the full posterior under a later state-aware active
scheduler.  AF2 must test calibration, and AF3 must resolve the larger
sender-information issue before AF5.

## 3. Exact recursion

At target sample \(k\), let \(\mathcal M_k=(r_1,\ldots,r_M)\) be all attempted
packets whose deterministic processing samples are no later than \(k\),
ordered from oldest to newest.  Let \(S_m\) be the receiver-held packet
identity after processing \(r_m\), and let \(\delta_r\) be unit mass at packet
identity \(r\).  Starting from \(b_0=\delta_{r_0}\), the channel prediction is

\[
b_m=p\,b_{m-1}+(1-p)\,\delta_{r_m},\qquad m=1,\ldots,M.
\]

There is no observation update because the no-feedback filtration receives
no channel observation.  Equivalently,

\[
\Pr(S_M=r_0)=p^M,
\qquad
\Pr(S_M=r_m)=(1-p)p^{M-m},\quad m=1,\ldots,M.
\]

Packets sent by time \(k\) but processed after the target sample are known
in-flight records and receive zero probability at that target.

### Lemma AF-1 -- exact communication-filtration PMF

Under AF-A1--AF-A6, the recursion and closed form above equal

\[
b_{ij}^k(s)=
\Pr(R_{ij}(k)=s\mid\mathcal I^{0,\mathrm{tx}}_j(k)).
\]

**Proof.** For receiver identity \(r_m\) to be current, packet \(r_m\) must
succeed and every newer matured attempt must be erased; outcomes of older
attempts are irrelevant because of AF-A5.  AF-A3 gives probability
\((1-p)p^{M-m}\).  The initial identity remains exactly when all \(M\)
attempts are erased, with probability \(p^M\).  These disjoint events exhaust
the sample space.  Adding one matured attempt preserves the previous state
on erasure and replaces it with the new identity on success, yielding the
recursion. \(\square\)

## 4. Implementation and complexity

`tcnsAckFreeReceiverBelief` implements the closed form without reading any
simulator network object.  With \(M\) matured attempts and \(F\) in-flight
attempts, construction takes \(O(M+F)\) time and \(O(M+F)\) storage.  Exact
evaluation of a state-dependent quantity

\[
\sum_{m=0}^{M} b_m q(r_m)
\]

takes \(O(M C_q)\) time and \(O(M)\) belief storage, where \(C_q\) is the cost
of evaluating one candidate's Gate-3 value.  No probability-mass truncation
is permitted in AF0--AF4.

Across \(L\) active directed links and \(K\) samples, an explicit untruncated
history has worst-case \(O(LK)\) storage at the end of a run and
\(O(LK^2 C_q)\) cumulative work if every historical state is re-evaluated at
every sample.  This is acceptable for the S2/S6 diagnostic but is not yet a
scalability claim.

## 5. AF1 required tests

The implementation must pass:

1. mass sums to one and is nonnegative;
2. in-flight/impossible states have zero target-time mass;
3. the no-loss limit collapses to the newest matured packet;
4. the all-loss limit collapses to the common initial packet;
5. recursive probabilities match exhaustive Bernoulli enumeration;
6. histories inconsistent with newest-generation semantics are rejected;
7. changing hidden simulator drop fields cannot change the PMF;
8. on matched S2 and S6 simulator traces, the realized receiver generation
   always has positive probability in the declared support.

## 6. Explicit proof gaps and stop conditions

**PROOF GAP AF.1 -- full sender filtration.** The sender's physical-state and
received-neighbor histories can be statistically coupled to earlier delivery
outcomes through the closed loop.  Lemma AF-1 conditions only on the declared
communication filtration.  A state-aware active policy may enlarge the
filtration and make the simple geometric PMF a prior rather than the full
posterior.

**PROOF GAP AF.2 -- endogenous action times.** Under an active state-dependent
trigger, the occurrence and timing of later actions may themselves reveal
information about hidden closed-loop histories.  AF5 is forbidden unless AF3
establishes a defensible policy information structure or explicitly proves
that this selection does not invalidate the required expectation.

**PROOF GAP AF.3 -- time-varying channels.** Gilbert--Elliott loss, jitter,
congestion, topology faults, and blackouts require an augmented channel-state
and arrival-hazard filter.  They are excluded rather than approximated.

**PROOF GAP AF.4 -- numerical growth.** Exact support grows with the number of
matured transmissions.  Pruning would be an approximation and is forbidden
in the current diagnostic.

Stop before active scheduling if AF1 fails, if AF2 is uncalibrated under the
matched S2/S6 passive schedule, if AF3 requires undeclared receiver/global
truth, or if the value collapses to already-covered expected-error triggering.

## 7. AF1 verification record

Reproduction command:

```matlab
run('tests/test_tcns_ack_free_receiver_belief.m')
```

The test passed on MATLAB R2025a.  It checked 1,616 link/sample receiver
states across short passive S2/S6 traces; every realized generation identity
had positive PMF support.  The minimum realized-state mass was 0.16.  The
test also passed exhaustive enumeration, hidden-annotation invariance,
normalization, scope rejection, and the no-loss/all-loss limits.
