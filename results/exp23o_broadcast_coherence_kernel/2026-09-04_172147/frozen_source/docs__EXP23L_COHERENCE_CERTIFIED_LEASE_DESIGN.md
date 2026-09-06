# EXP23L — Coherence-certified adaptive witness leases

Status: mathematical design frozen before kernel implementation.

## 1. Why a fixed long lease is not the final method

EXP23K shows that a 9x renewal horizon has enough communication-cost
headroom in the static N5/IID-15% development cell. A fixed long lease is
safe only while the conflict relation and advertised tuple remain valid. If a
new interference edge can appear without warning, no causal distributed
protocol can guarantee collision-free scheduled service at the instant of its
appearance. The missing object is therefore not another retry heuristic but a
certificate for how long the conflict graph is guaranteed to remain covered.

The proposed repair is a **coherence-certified lease**. A local witness does
not certify only the graph observed now; it certifies a conservative
potential-conflict supergraph over a declared future horizon. The usable lease
is the smaller of the cost-efficient target horizon and the locally proved
coherence horizon.

## 2. Physical interference and broadcast sender-conflict graphs

Let (p_i(t)\in\mathbb R^d) be the position of radio (i). Define the physical
interference graph (I(t)) by

\[
 \|p_i(t)-p_j(t)\|\le R_I,
\]

where (R_I) is the declared interference radius. Let (A(r,i)=1) mean receiver
(r) is an intended DATA recipient of sender (i). The actual broadcast
sender-conflict graph (F(t)) contains ({i,j}) whenever (i) and (j) are
half-duplex neighbors or either sender can interfere at an intended receiver
of the other:

\[
 F_{ij}(t)= A(j,i)\lor A(i,j)
 \lor \bigvee_{r:A(r,i)=1} I_{rj}(t)
 \lor \bigvee_{r:A(r,j)=1} I_{ri}(t).
\]

This receiver lift is essential: two senders outside each other's
interference radius may still conflict at a common or hidden receiver.

At certificate time (s), node (i)'s causally available state has estimate

\[
 \hat x_i(s)=(\hat p_i(s),\hat v_i(s)),
\]

with position/velocity error bounds (e_i^p(s),e_i^v(s)). These bounds may be
computed from receiver-confirmed age using the semantic envelopes already
proved in `STUDY2_MATHEMATICAL_FOUNDATION.md`. Under acceleration bound
(\|a_i\|\le\bar a_i), its reachable tube over lookahead (\tau\ge0) is

\[
 \mathcal R_i(s,\tau)=
 B\!\left(\hat p_i(s)+\hat v_i(s)\tau,
 e_i^p(s)+e_i^v(s)\tau+\tfrac12\bar a_i\tau^2\right).
\]

For horizon (H), first define the potential physical-interference supergraph
(I^+(s,H)) by including edge ({i,j}) if, for any
(\tau\in[0,H]), the minimum separation between
(\mathcal R_i(s,\tau)) and 
(\mathcal R_j(s,\tau)) is no larger than (R_I). Equivalently, the edge is
included when

\[
 \min_{0\le\tau\le H}
 \|\hat p_i-\hat p_j+(\hat v_i-\hat v_j)\tau\|
 \le R_I+r_i(s,\tau)+r_j(s,\tau).
\]

The potential broadcast sender-conflict graph (F^+(s,H)) is obtained by
replacing (I(t)) with (I^+(s,H)) in the receiver-lift equation. Both
constructions are causal: they use only timestamped received state, declared
intended receivers and motion bounds. They are monotone in (H): increasing
the requested lease can add potential edges but cannot remove them.

## 3. Safety theorem

### Theorem — Supergraph-certified lease safety

Fix certificate time (s) and horizon (H). Assume:

1. every actual trajectory remains inside its declared reachable tube on
   ([s,s+H]);
2. (I^+(s,H)) contains every physical interference relation permitted by the
   reachable tubes, and (F^+(s,H)) is its receiver lift;
3. the witness-certificate invariant binds each active sender to a proper
   coloring of (F^+(s,H)) through certificate expiry; and
4. tuple self-locks extend beyond certificate expiry by the existing lease
   fence.

Then no two simultaneously active scheduled senders that conflict in
(F(t)) use the same slot for any (t\in[s,s+H]).

**Proof.** Take any actual conflict edge ({i,j}\in F(t)) in the interval. If
the edge follows from direct half-duplex adjacency, the receiver lift includes
it directly. Otherwise sender (j) physically interferes at an intended
receiver of (i), or conversely. By assumption 1 the interferer and receiver
lie in their reachable tubes. Assumption 2 therefore includes their physical
relation in (I^+), whose receiver lift includes ({i,j}) in (F^+). Proper
coloring in assumption 3 assigns distinct slots. Assumption 4 prevents either
tuple from changing before expiry. Hence an actual conflicting pair cannot
transmit in the same scheduled slot. (\square)

The theorem needs no stochastic independence. Loss remains fail-silent: a
missing CLAIM, witness response or horizon entry cannot create a certificate.

## 4. Adaptive horizon rule

Let the cost-derived target from EXP23K be

\[
 H_{cost}=124\ \text{frames}.
\]

For each incident certificate, the witness computes the largest admissible
coherence horizon (H_{ij}^{coh}) for which its available reachable tubes and
potential-neighbor set are complete. The sender uses

\[
 H_i=\min\left\{H_{cost},\min_{e\ni i}H_e^{coh}\right\}.
\]

The corresponding renewal deadline retains the existing refresh and fence
slack:

\[
 P_i=H_i-H_{refresh}-H_{fence}.
\]

If (H_i\le H_{refresh}+H_{fence}), scheduled validity is not issued and the
node remains in the existing fallback/acquisition state. Thus uncertainty
shortens or suppresses a lease; it never silently lengthens one.

The final operating-envelope claim must report the distribution of (H_i),
not merely its configured maximum. Under fast motion, stale information or a
dense predicted supergraph, the policy may safely lose the cost advantage.
That boundary is a result, not an implementation failure.

## 5. Self-revocation and model-bound violations

Each sender monitors the state/motion envelope it advertised in its current
CLAIM. If it would leave that envelope before certificate expiry, it must:

1. stop scheduled DATA use locally before leaving the certified tube;
2. increment its tuple version;
3. emit a best-effort REVOKE carrying node, old version and expiry; and
4. re-enter acquisition under a newly computed supergraph.

Safety does not depend on REVOKE delivery because the envelope-violating
sender silences itself. REVOKE only accelerates garbage collection and
neighbor reacquisition. A lost REVOKE cannot extend positive validity, and a
received stale/future/mismatched REVOKE cannot modify the current tuple.

This contract requires a local self-monitoring assumption. If a sender can
leave its advertised tube without detecting and suppressing itself, zero-
collision safety is not claimed; the event must be logged as an envelope-
violation failure.

## 6. Renewal-cost bound

Let (B_0) be bootstrap control bytes, (B_R) a bound on one renewal
transaction including retry, (T) the mission duration and (H) the realized
renewal period. A conservative offered-control bound is

\[
 U_{ctrl}(H)\le
 \frac{8}{R_{phy}T}
 \left(B_0+\left\lceil\frac{T}{H T_f}\right\rceil B_R\right),
\]

where (T_f) is the physical frame duration. For fixed (B_R), the bound is
nonincreasing in (H). Coherence certification therefore exposes the exact
tradeoff: motion/AoI uncertainty reduces (H), which increases communication
cost but preserves the supergraph safety theorem.

## 7. Kernel falsification obligations

Before closed-loop performance work, the implementation must pass:

1. reachable-tube containment for deterministic motion fixtures;
2. actual-graph subset of the certified supergraph at every protected frame;
3. monotonic supergraph growth with requested horizon and AoI;
4. horizon contraction under faster motion, larger acceleration bounds and
   older state;
5. zero false-valid scheduled edges during covered edge additions/removals;
6. fail-silent behavior under missing horizon CLAIM/RESPONSE fields;
7. local self-revocation before an injected envelope violation;
8. stale/future/version-mismatched REVOKE rejection;
9. exact added-byte, recipient and airtime accounting;
10. bounded fallback/reacquisition after a valid revocation.

The first experiment is a kernel falsification study with scripted dynamic
graphs and motion tubes. Only a pass permits fresh closed-loop comparison of
coherence-adaptive ELCS-W, short-horizon ELCS-W and periodic TDMA.
