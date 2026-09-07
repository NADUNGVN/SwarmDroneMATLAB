# AF3 ACK-free expected Gate-3 value checkpoint

**AF3 status:** `STOP`  
**Stop reason:** `EXACT_GATE3_VALUE_NOT_IDENTIFIED_BY_I_J_0`  
**AF4 forced-action validation:** not executed  
**AF5 active frontier:** not authorized

## 1. What the ACK-free belief identifies

AF0--AF2 establish a calibrated distribution over packet identities that a
receiver may hold under the frozen S2/S6 static IID channel.  For each
hypothesis \(s\), sender \(j\) can reconstruct its own historical payload and
form the candidate command correction \(c_{ij,s}\).  The exact Gate-3 link
kernel then gives

\[
G_{ij,s}=\mathcal T_{H,D}^{(i)}c_{ij,s}.
\]

Consequently, the ACK-free belief identifies the isolated expectation

\[
\frac{p_s}{m}\sum_s b_s\lVert G_{ij,s}\rVert_F^2.
\]

This is not enough to identify whether a transmission improves total
formation performance.

## 2. Exact expected value and missing statistic

For receiver-memory hypothesis \(s\), the frozen O1/Gate-3 value is

\[
q_{ij}(k;s)=\frac{p_s}{m}\left(
\lVert Z_s\rVert_F^2-
\lVert Z_s+G_{ij,s}\rVert_F^2\right),
\]

where \(Z_s\) is the no-action formation-error response.  Taking the belief
expectation gives the exact identity

\[
\bar q_{ij}(k)=
-\frac{2p_s}{m}\sum_s b_s\langle Z_s,G_{ij,s}\rangle_F
-\frac{p_s}{m}\sum_s b_s\lVert G_{ij,s}\rVert_F^2.
\]

The second term is sender-computable from AF0.  The first term is not.  It
requires the conditional joint baseline/action projection

\[
\Xi_{ij}(k)=\sum_s b_s\langle Z_s,G_{ij,s}\rangle_F.
\]

In the implemented formation controller, \(Z_s\) depends on:

- the current state and formation error of every follower;
- the receiver's current physical state;
- receiver-held memories on the receiver's other incoming links;
- pinned-leader receiver memory;
- the resulting total communication-induced residual; and
- the current global error propagated through the Gate-3 closed-loop model.

An ordinary sender \(j\) does not possess these variables in
\(\mathcal I_j^{0,\mathrm{tx}}(k)\).  The ACK-free packet-memory PMF resolves
uncertainty about what \(i\) may hold **about \(j\)**, but does not reveal the
global no-action response against which that update acts.

## 3. Why plug-in approximations are forbidden here

The following substitutions do not compute the requested quantity:

\[
q(E[R])\ne E[q(R)]
\]

in general, and

\[
E\langle Z,G\rangle\ne
\langle E[Z],E[G]\rangle
\]

when the hidden baseline and action response are correlated.  Computing O1
with simulator truth and averaging over only the candidate link state would
remain a centralized oracle.  Replacing the cross term by
\(E\lVert G\rVert^2\), expected receiver error, AoI, or a fitted weight would
return to the isolated mechanisms that already failed Gate 4 and/or collide
with Viel et al. 2022.

## 4. Executable sign witness

`tcnsAckFreeValueIdentifiabilityWitness` uses the exact Gate-3 response kernel
for every positive-probability packet hypothesis.  For the same belief
\(b_s\) and the same action-response family \(G_s\), consider two hidden
baseline families:

\[
Z_s^-=-G_s,\qquad Z_s^+=+G_s.
\]

Let

\[
S=\frac{p_s}{m}\sum_s b_s\lVert G_s\rVert_F^2>0.
\]

Then the exact expected values are

\[
\bar q^- = S>0,
\qquad
\bar q^+ = -3S<0.
\]

Thus the receiver-memory PMF and candidate action responses determine neither
the sign nor magnitude of the exact total formation value unless the hidden
baseline projection is supplied or modeled.  The executable test constructs
the response family from the implemented matrices and verifies both
identities to numerical tolerance.

Reproduction:

```matlab
run('tests/test_tcns_ack_free_value_identifiability.m')
```

## 5. Proof gap

**PROOF GAP AF3.1 -- full dynamically reachable indistinguishable
histories.** The witness is exact in the Gate-3 output space, but it does not
construct two complete plant/network histories that are both dynamically
reachable and give a real sender identical full local observations while
placing \(\Xi_{ij}\) on opposite sides of the sign threshold.  Therefore this
checkpoint does not claim a universal impossibility theorem.

This gap does not authorize implementation: the current repository contains
no causal map from the declared sender information to \(Z_s\) or \(\Xi_{ij}\),
while the exact value routine explicitly requires centralized current plant
and receiver state.  Implementing an “exact” active scheduler would therefore
necessarily leak privileged information or introduce an unvalidated
surrogate.

## 6. Mandatory research decision

The Research Lead required a stop before active implementation if the
ACK-free expected value was not exact/defensible.  That condition is met:

`STOP_ACK_FREE_ACTIVE_POLICY`

Accordingly:

- AF4 is not run, because any forced-action score available now would be the
  already frozen centralized O1 score or a non-preregistered surrogate;
- `ack_free_belief_value_v1` is not implemented;
- AF5, held-out seeds, scalability, and manuscript claim expansion remain
  unopened;
- lambda, ACK economics, channel parameters, scenarios, and the periodic
  comparator are not tuned.

The completed scientific result is a boundary: receiver-memory uncertainty
can be modeled and calibrated without ACK, but this alone does not make the
validated total formation-impact signal distributively observable.  A future
track would require separately authorized information architecture for the
cross-term statistic (for example a receiver-generated request/adjoint
projection, with its traffic charged) or a theorem proving a valid local
surrogate.  Neither is part of the present authorization.

