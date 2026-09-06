# Study 2 — Mathematical foundation

**Version:** 0.3, analytical draft  
**Scope:** Causal-Broadcast on a shared medium; double-integrator theory track  
**Status:** theorem candidates and proofs below are independent of holdout and
hardware data. A statement is not an empirical claim until its assumptions are
checked in EXP13--EXP15.

## 1. Purpose and separation from Study 1

Study 1 establishes a simulation result for a fixed per-directed-link causal
policy. Study 2 needs a mathematical spine that answers four different
questions:

1. What does an honest sender know about each receiver after delayed/lost ACKs?
2. How does receiver-confirmed age bound the state error used by formation
   control?
3. What age guarantee is defensible under stochastic contention and loss?
4. How does that information error enter a formation-error and safety bound?
5. When can a standalone ACK repay its own airtime and contention cost before
   the same information would arrive by piggyback?

The chain developed here is

\[
\text{ACK integrity}
\Longrightarrow \widehat\Delta_{ij}\ge\Delta_{ij}
\Longrightarrow \text{semantic-error envelope}
\Longrightarrow \text{formation ISS}
\Longrightarrow \text{probabilistic safety condition}.
\]

The feedback-design branch is

\[
\text{unique confirmation lead}
\Longrightarrow \text{changed future DATA decisions/service}
\Longrightarrow \text{control/resource benefit}
\mathop{\gtrless}\text{ACK airtime+externality}.
\]

The result is deliberately parameterized by service probability, delay and
state-derivative bounds. Hardware later estimates or falsifies those
parameters; it does not replace the proofs.

## 2. Packet and information-state notation

For sender \(j\), broadcast \(k\) has sequence \(k\), generation time
\(s_j^k\), and payload \(x_j(s_j^k)=[p_j^\top,v_j^\top]^\top\). Let
\(r_{ij}^k\) be the time receiver \(i\) accepts it, if it is accepted, and let
\(a_{ji}^k\) be the time an ACK entry confirming it arrives back at sender
\(j\), if such an entry arrives.

The receiver truth is

\[
G_{ij}(t)=\max\{s_j^k:r_{ij}^k\le t\},
\qquad
\Delta_{ij}(t)=t-G_{ij}(t).
\]

The sender's causally confirmed generation time and age are

\[
C_{ij}(t)=\max\{s_j^k:a_{ji}^k\le t\},
\qquad
\widehat\Delta_{ij}(t)=t-C_{ij}(t).
\]

At sampled time \(t_n\), the implementation may log
\(\widehat\Delta^h_{ij}(t_n)=t_n-C_{ij}(t_n)+h/2\). The half-step correction is
nonnegative and therefore does not weaken any conservative-age result.

Initialization uses common state at \(t=0\), so
\(C_{ij}(0)=G_{ij}(0)=0\) on every configured link. If a cold-start protocol is
used later, both values must instead begin at the same declared sentinel; the
proof cannot silently initialize the sender with information the receiver does
not hold.

## 3. Protocol assumptions

The following assumptions are minimal and individually auditable.

**A1 — Monotone source time.** For each sender, sequence and generation time
increase together: \(k_2>k_1\Rightarrow s_j^{k_2}\ge s_j^{k_1}\).

**A2 — Newest-generation reception.** Receiver \(i\) advances \(G_{ij}\) only
after accepting a DATA frame and never rolls it back.

**A3 — Honest cumulative feedback.** An ACK entry is generated only after the
named DATA has been accepted. An ACK cannot name an unsent/future sequence or a
different generation time. This is a protocol-integrity assumption, not a
security result against spoofing.

**A4 — Monotone sender update.** Sender \(j\) advances \(C_{ij}\) only after an
ACK entry arrives and rejects rollback. Loss, collision, queue drop and silence
never advance it.

**A5 — Bounded motion for semantic envelopes.** On the analysis interval,
\(\|v_j(t)\|\le\bar v_j\) and \(\|a_j(t)\|\le\bar a_j\). These are physical or
controller bounds, not network assumptions.

**A6 — Nominal linear formation region.** The double-integrator controller is
evaluated before acceleration saturation, or the trajectory is certified to
remain in the unsaturated region. Saturation and 6-DOF attitude dynamics are
outside the first theorem and require a later nonlinear/cascade extension.

**A7 — Block-service minorization.** For an age-tail statement, there exist a
finite block length \(T_b>0\) and \(q\in(0,1]\) such that, conditional on every
past event, a fresh DATA generated within a recovery block is accepted and
causally confirmed by the end of that block with probability at least \(q\).
This condition includes generation, queue admission, MAC service, DATA
reception, ACK generation and ACK service.

A7 is not implied by `maxSilence` alone. `maxSilence` bounds update generation
opportunities; a congested finite queue or permanently starved MAC can still
make \(q=0\). EXP13 must identify the offered-load region in which a positive
lower bound is credible, and EXP15 must check it against measured traces.

**A8 — Counterfactual lead-value envelope.** For a standalone-ACK decision,
the ACK-assisted and no-standalone policies can be coupled up to the decision.
Let \(\ell\) be the nonnegative time for which a successfully delivered
standalone ACK gives the sender confirmation that it would not yet have under
the piggyback counterfactual. For a declared finite horizon and weighted
objective, constants \(0\le\underline b\le\overline b\) satisfy

\[
\underline b\,\mathbb E[\ell\mid\mathcal F_t]
\le \mathbb E[B_H\mid\mathcal F_t]
\le \overline b\,\mathbb E[\ell\mid\mathcal F_t],
\]

where \(B_H\) is the benefit caused by early confirmation before direct ACK
cost and ACK-induced contention are charged. The non-airtime externality has
declared conditional bounds
\(0\le\underline x\le\mathbb E[X_A\mid\mathcal F_t]\le\overline x\).
A8 is not implied by causal conservatism and cannot be fitted from a favorable
holdout mean. It needs analytical bounds, a shadow no-standalone scheduler or
trace/radio measurements over a declared operating set.

**A9 — Target-event support for conditional ACK value.** Let \(E_t=1\) denote
that the natural policy produces a permitted standalone-ACK candidate at time
\(t\) that also satisfies the declared analysis window, and let \(X_t\) be the
pre-decision covariates. If \(\mu_c\) is the target covariate distribution in
cell \(c\) and \(\nu_c\) is the covariate distribution induced by eligible
events, then conditional-effect generalization requires

\[
\mu_c\ll\nu_c,
\]

that is, every target set with positive \(\mu_c\)-probability must have positive
eligible-event support. This is event-process overlap, not ordinary randomized
treatment overlap. A state-cloned branch replay constructs both actions after
an eligible event, but it cannot identify value in states where the natural
candidate process does not supply an event. A finite experiment must declare a
minimum number of independent parent trajectories before outcomes are opened.

## 4. Causal conservatism

### Theorem 1 — ACK-confirmed age upper-bounds true receiver age

Under A1--A4 and consistent initialization, for every configured directed link
and all \(t\ge0\),

\[
C_{ij}(t)\le G_{ij}(t),
\qquad
\widehat\Delta_{ij}(t)\ge\Delta_{ij}(t).
\]

Moreover, the conservatism gap is exact:

\[
\widehat\Delta_{ij}(t)-\Delta_{ij}(t)
=G_{ij}(t)-C_{ij}(t)\ge0.
\]

**Proof.** Initially \(C_{ij}=G_{ij}\). The only event that advances
\(C_{ij}\) is an arrived ACK. By A3, the named DATA was already accepted by
receiver \(i\), hence its generation time is no larger than the receiver's
current newest accepted generation time. A4 prevents a later ACK from rolling
\(C_{ij}\) back or advancing it without that evidence. DATA reception without
ACK may advance \(G_{ij}\) only, while loss, collision and silence advance
neither generation time. Therefore the order is invariant. Subtracting both
generation times from the same \(t\) proves the age inequality and identity.
\(\square\)

**Interpretation.** Delayed or lost ACKs can cause pessimism and extra traffic,
but cannot make the sender optimistically underestimate receiver age under the
stated protocol. Piggybacking and ACK aggregation change the delay distribution,
not this invariant.

### Corollary 1 — Worst-neighbor aggregation is conservative but not diagnostic

Let \(\widehat\Delta_j^{\max}=\max_{i\in\mathcal N_j^{out}}
\widehat\Delta_{ij}\) and \(\Delta_j^{\max}=\max_i\Delta_{ij}\). Then

\[
\widehat\Delta_j^{\max}\ge\Delta_j^{\max}.
\]

For any nonnegative nondecreasing function \(f\) and common sender innovation
\(I_j\ge0\),

\[
\max_i I_j f(\widehat\Delta_{ij})
\ge
\max_i I_j f(\Delta_{ij}).
\]

The receiver attaining the estimated maximum need not be the receiver with the
largest true age. The rule upper-bounds worst-neighbor risk; it does not identify
the true worst receiver.

## 5. From age to semantic state error

Let \(g=G_{ij}(t)\) and \(\Delta=t-g\). The current MATLAB controller uses the
last accepted position and velocity directly, i.e. zero-order holds
\(\widetilde p_j(t)=p_j(g)\) and \(\widetilde v_j(t)=v_j(g)\).

### Theorem 2 — Receiver-state error envelopes

Under A5, zero-order hold satisfies

\[
\|v_j(t)-\widetilde v_j(t)\|
\le \bar a_j\Delta_{ij}(t)
\le \bar a_j\widehat\Delta_{ij}(t),
\]

\[
\|p_j(t)-\widetilde p_j(t)\|
\le \bar v_j\Delta_{ij}(t)
   +\tfrac12\bar a_j\Delta_{ij}^2(t)
\le \bar v_j\widehat\Delta_{ij}(t)
   +\tfrac12\bar a_j\widehat\Delta_{ij}^2(t).
\]

If the receiver instead uses the constant-velocity predictor

\[
\widetilde p_j^{cv}(t)=p_j(g)+v_j(g)(t-g),
\qquad
\widetilde v_j^{cv}(t)=v_j(g),
\]

then

\[
\|p_j(t)-\widetilde p_j^{cv}(t)\|
\le\tfrac12\bar a_j\widehat\Delta_{ij}^2(t),
\qquad
\|v_j(t)-\widetilde v_j^{cv}(t)\|
\le\bar a_j\widehat\Delta_{ij}(t).
\]

**Proof.** Integrating acceleration gives
\(v_j(t)-v_j(g)=\int_g^t a_j(\tau)d\tau\), yielding the velocity bound.
Taylor's integral form gives
\(p_j(t)=p_j(g)+v_j(g)\Delta+
\int_g^t(t-\tau)a_j(\tau)d\tau\). Applying the triangle inequality produces
the position bounds. Theorem 1 permits replacement of \(\Delta\) by the larger
\(\widehat\Delta\) because the right-hand sides are nondecreasing on
\(\mathbb R_{\ge0}\). \(\square\)

Define the analysis envelopes

\[
E^p_j(a)=\bar v_j a+\tfrac12\bar a_j a^2,
\qquad E^v_j(a)=\bar a_j a
\]

for zero-order hold. These envelopes are not asserted to equal the trigger's
innovation \(I_j\): \(I_j\) measures change since the latest broadcast put on
the wire, whereas \(E^p,E^v\) bound receiver reconstruction error from the
latest causally confirmed generation. Conflating them would erase the dual-
memory distinction.

## 6. What can and cannot be claimed about AoI

### Proposition 1 — Max-silence does not give a deterministic AoI bound

Suppose every recovery attempt has an independent failure probability
\(r\in(0,1)\), even if the policy generates an attempt at least once every
\(\tau_{\max}\). For every finite \(D\), there is positive probability that a
long enough run of failures makes \(\Delta_{ij}>D\). Over an infinite horizon,
arbitrarily long failure runs occur almost surely, so no finite deterministic
uniform AoI bound follows from max-silence.

This rules out wording such as “AoI is bounded by \(\tau_{\max}\)” under random
loss. The correct target is a finite-horizon or stationary tail bound.

### Theorem 3 — Geometric confirmed-age tail under block service

Under A7, let \(t\) lie in the current recovery block. For every integer
\(m\ge1\),

\[
\Pr\{\widehat\Delta_{ij}(t)>(m+1)T_b\}
\le (1-q)^m.
\]

No independence between blocks is required.

**Proof.** If any one of the preceding \(m\) complete blocks delivers and
confirms a DATA generated in that block, its generation time is at most
\((m+1)T_b\) behind \(t\). Hence the displayed age event implies failure in all
\(m\) blocks. Let \(F_\ell\) denote failure in block \(\ell\) and
\(\mathcal F_\ell\) its history. A7 gives
\(\Pr(F_\ell\mid\mathcal F_\ell)\le1-q\). Repeated conditioning yields
\(\Pr(\cap_{\ell=1}^m F_\ell)\le(1-q)^m\). \(\square\)

For true receiver age, replace end-to-end DATA-plus-ACK success by DATA success
and obtain a generally larger probability \(q_D\). For confirmed age, the
relevant value is \(q_C\le q_D\). This cleanly exposes the freshness price of
ACK delay/loss and feedback implosion.

The theorem becomes uninformative as \(q\to0\). That is a mathematically useful
boundary: it is the congestion/starvation region Study 2 must find, not smooth
over.

### Proposition 2 — A non-tuned p-persistent access point

Consider one guaranteed idle contention opportunity for a tagged frame. If at
most \(c\) other conflicting nodes independently attempt with the same
conditional probability \(p\), the tagged collision-free access term is

\[
\theta_c(p)=p(1-p)^c.
\]

For \(c\ge1\), differentiation gives

\[
\theta_c'(p)=(1-p)^{c-1}[1-(c+1)p],
\]

so the unique maximizer on \([0,1]\) is

\[
p^\star=\frac{1}{c+1}.
\]

For the primary \(N=5\) fully conflicting bound, \(c=4\) gives \(p^\star=0.2\).
This is an analytical default, not a value selected from performance data. It
also explains why synchronized \(p=1\) ACK deadlines have zero collision-free
lower bound whenever \(c>0\).

Let \(q_D^{adm}\), \(q_A^{adm}\) be conditional queue-admission lower bounds,
\(\ell_D,\ell_A\) residual loss upper bounds, and \(R_D,R_A\) guaranteed DATA
and ACK opportunities within one block. Define

\[
q_{D,1}=q_D^{adm}p_D(1-p_D)^{c_D}(1-\ell_D),
\qquad
q_{A,1}=q_A^{adm}p_A(1-p_A)^{c_A}(1-\ell_A).
\]

Repeated conditioning gives

\[
q_D^{blk}\ge1-(1-q_{D,1})^{R_D},
\qquad
q_{A|D}^{blk}\ge1-(1-q_{A,1})^{R_A},
\]

and a valid end-to-end minorization is

\[
q_C^{blk}\ge q_D^{blk}q_{A|D}^{blk}.
\]

The product uses sequential conditional lower bounds, not an independence claim.
If queue admission, a fresh obligation or an ACK opportunity cannot be
guaranteed in the declared operating set, its corresponding lower bound is zero
and no theorem-level positive \(q_C\) is issued.

### Theorem 4 — Finite-horizon uniform confirmed-age bound

Let the mission horizon contain \(K=\lceil T/T_b\rceil\) blocks and let \(L\) be
the number of control-relevant directed information channels. A run of \(m\)
failed blocks can start in at most
\(W_m=\max\{0,K-m+1\}\) positions. Under A7,

\[
\Pr\left\{
\max_{(i,j)}\sup_{0\le t\le T}\widehat\Delta_{ij}(t)>(m+1)T_b
\right\}
\le
\min\{1,LW_m(1-q)^m\}.
\]

**Proof.** Any violation implies that some link contains a window of \(m\)
consecutive failed recovery blocks. Theorem 3 bounds each window by
\((1-q)^m\); a union bound over its possible positions and the \(L\) links
gives the result. No independence across links, windows or blocks is used.
\(\square\)

For target failure probability \(\alpha\), a sufficient service condition is

\[
q\ge q_{req}
=1-\left(\frac{\alpha}{LW_m}\right)^{1/m},
\]

clipped to \([0,1]\). This requirement is meaningful only if the deterministic
formation/separation condition below holds at age cap \((m+1)T_b\).

## 7. Marginal value of standalone ACK

This section compares an ACK-assisted policy \(S\) with a piggyback-only policy
\(P\). The policies must use the same DATA trigger, access rule, packet format
and exogenous cell; only standalone feedback service differs. The comparison
does not assume that ACK delivery is beneficial.

### Lemma 1 — A standalone ACK cannot directly refresh a receiver

A standalone ACK carries confirmation from a receiver to a sender. Its
delivery advances \(C_{ij}\) and can reduce \(\widehat\Delta_{ij}\), but it does
not advance receiver truth \(G_{ij}\), reduce true receiver age
\(\Delta_{ij}\), or deliver a new plant state. Therefore every control or true-
AoI benefit of a standalone ACK must be mediated by a change in later DATA
generation, admission, service or collision. If no later DATA decision/service
is changed, the ACK has no positive receiver-freshness benefit and still pays
its airtime and contention externality.

**Proof.** By A2, only accepted DATA advances \(G_{ij}\). By A4, accepted ACK
advances only \(C_{ij}\). The controller reconstructs neighbors from accepted
DATA, not sender-side confirmations. Thus an ACK can influence the controller
only through a later action selected from the changed sender belief.
\(\square\)

### Proposition 3 — Exact horizon accounting identity

Over a horizon of duration \(H\), let \(D_H^\pi\) and \(A_H^\pi\) be total DATA
and standalone-ACK airtime under policy \(\pi\in\{S,P\}\). DATA airtime includes
the bytes of ACK entries piggybacked on DATA. Define

\[
S_D=D_H^P-D_H^S,
\qquad C_A=A_H^S-A_H^P,
\qquad M_{air}=S_D-C_A.
\]

Then the offered-utilization difference is exactly

\[
U_H^P-U_H^S=\frac{M_{air}}{H}.
\]

Thus standalone ACK reduces offered airtime if and only if the DATA airtime it
saves exceeds its extra standalone-ACK airtime. Piggyback overhead must not be
added again because it is already part of \(D_H^\pi\).

**Proof.** Substitute \(U_H^\pi=(D_H^\pi+A_H^\pi)/H\) and collect terms.
No independence, stationarity or asymptotic argument is used. \(\square\)

Let \(L_H^\pi\) be any lower-is-better control loss and \(N_C^\pi\) a collision
count. With nonnegative, dimensionally compatible weights, define

\[
V_H=w_L(L_H^P-L_H^S)
    +w_U M_{air}
    +w_C(N_C^P-N_C^S).
\]

For this declared objective, standalone ACK has positive expected marginal
value exactly when
\(\mathbb E[V_H\mid\mathcal F_t]>0\). A different weight vector can reverse a
mixed control/resource verdict; therefore no objective-free scalar statement
of ACK value exists. Pareto conclusions require sign agreement without
weights.

### Proposition 4 — Unique-lead transmit/discard certificate

Let \(\tau_A\) be the first time the standalone ACK successfully advances the
sender belief and let \(\tau_P\) be the time the same confirmation would first
arrive in the coupled piggyback counterfactual. Define the horizon-capped unique
lead

\[
\ell=\bigl[\min\{\tau_P,H\}-\min\{\tau_A,H\}\bigr]^+,
\]

with \(\ell=0\) if standalone delivery is not earlier. Let \(c_A\) be direct
standalone-ACK airtime and let \(w_U\) convert it to the chosen objective.
Under A8, the conditional net value obeys

\[
\underline V=
\underline b\,\mathbb E[\ell\mid\mathcal F_t]
-(w_Uc_A+\overline x)
\le \mathbb E[V_H\mid\mathcal F_t]
\le
\overline b\,\mathbb E[\ell\mid\mathcal F_t]
-(w_Uc_A+\underline x)
=\overline V.
\]

Consequently:

- if \(\overline V\le0\), discard/defer the standalone ACK is certified;
- if \(\underline V>0\), standalone transmission is certified;
- otherwise the theorem returns **inconclusive**.

**Proof.** Apply the A8 lower and upper bounds to the early-information benefit
and subtract the opposite externality bound plus the same direct airtime cost.
The decision implications follow from the signs of the resulting interval.
\(\square\)

This certificate explains the structural role of “piggyback first.” A short or
unlikely unique lead makes the upper benefit small; a long lead can be valuable
only if it changes future DATA behavior enough to repay ACK cost. Mean ACK
delivery rate, mean AoI or mean busy fraction alone does not identify
\(\mathbb E[\ell\mid\mathcal F_t]\) or the benefit-rate bounds.

### Proposition 5 — Identification domain of branch-at-decision replay

Let \(Y_H(1)\) and \(Y_H(0)\) be a declared local outcome under focal ACK admit
and suppress, respectively. If a replay clones the complete pre-decision state
and future exogenous inputs and changes only focal admission, then for every
sampled eligible decision it identifies the pathwise contrast

\[
\delta_H=Y_H(0)-Y_H(1).
\]

Across independent parent trajectories it can estimate

\[
\tau_c=\mathbb E[\delta_H\mid E_t=1,c]
\]

over the supported eligible-event distribution. It does not identify an
effect for \(E_t=0\), nor a conditional or target-population effect outside the
support in A9.

**Proof.** State and future-input identity remove all pre-treatment and
exogenous branch differences, while the focal intervention supplies both
potential paths at an eligible decision. Averaging distinct parent-trajectory
contrasts therefore targets the event-conditional distribution. No contrast is
constructed where \(E_t=0\), so effects on unsupported states require an
additional structural extrapolation assumption. \(\square\)

**Finite-design consequence.** EXP14G and EXP14H observed at least one eligible
post-transient N20 event in only 11 of 300 disjoint parent seeds, a rate of
3.67% with two-sided 95% Wilson interval [2.06%, 6.45%]. EXP14H supplied seven
independent events, below the frozen minimum of 12, and stopped before replay.
This is a practical A9 failure for the registered N20 design, not evidence that
the population event probability is zero and not evidence about the sign of
\(\tau_c\). The N20 causal ACK-value effect is therefore not estimated. By
contrast, the supported EXP14G cells identify descriptive event-conditional
effects and show that positive confirmation lead is not sufficient for
positive true-AoI or formation value.

## 8. Formation model faithful to the implementation

For followers \(i=2,\dots,N\), define leader-frame position and velocity errors

\[
e_i=p_i-p_L-\delta_i,
\qquad r_i=v_i-v_L.
\]

Let \(A_f\) be the follower--follower adjacency, \(L_f\) its Laplacian,
\(G=\operatorname{diag}(A_{i1})\) the grounding contributed by ordinary
leader-neighbor edges in `cfg.swarm.A`, and
\(\Pi=\operatorname{diag}(\pi_i)\) the separate leader-pinning matrix. With the
primary unnormalized controller,

\[
H_p=K_p(L_f+G)+K_{pL}\Pi,
\qquad
H_v=K_v(L_f+G)+K_{vL}\Pi.
\]

For one coordinate, the unsaturated error dynamics are

\[
\dot z=A_cz+B_c(d_{net}+d_L),
\quad
z=\begin{bmatrix}e\\r\end{bmatrix},
\quad
A_c=\begin{bmatrix}0&I\\-H_p&-H_v\end{bmatrix},
\quad
B_c=\begin{bmatrix}0\\I\end{bmatrix}.
\]

The three-dimensional system is obtained with a Kronecker product by
\(I_3\). The communication disturbance contains the stale-neighbor terms. A
direct bound for follower \(i\) is

\[
\begin{split}
\|d_{net,i}\|\le{}&K_p\sum_j A_{ij}E^p_j(\widehat\Delta_{ij})
+K_v\sum_j A_{ij}E^v_j(\widehat\Delta_{ij})\\
&+\pi_iK_{pL}E^p_L(\widehat\Delta_{iL})
+\pi_iK_{vL}E^v_L(\widehat\Delta_{iL})
+\pi_i\|\widetilde a_{L,i}-a_L\|.
\end{split}
\]

The implementation adds leader-acceleration feed-forward only when
\(\pi_i=1\). Consequently

\[
d_{L,i}=(\pi_i-1)a_L.
\]

Therefore exact zero-error tracking of an accelerating leader is not a nominal
property for unpinned followers. The theory must either keep \(d_L\) as an
input, restrict the leader to constant velocity, or change the Study 2
controller and document that change. Frozen Study 1 behavior must not be
silently reinterpreted.

### Theorem 5 — Exponential stability and ISS of the unsaturated subsystem

Assume the primary follower graph is undirected and every connected component
is grounded through \(G\) or \(\Pi\). With all four gains positive,
\(H_p\succ0\) and \(H_v\succ0\), hence \(A_c\) is Hurwitz. Therefore constants
\(M\ge1\) and \(\lambda>0\) exist such that

\[
\|z(t)\|\le
M e^{-\lambda t}\|z(0)\|
+\frac{M}{\lambda}
\sup_{0\le\tau\le t}\|d_{net}(\tau)+d_L(\tau)\|.
\]

**Proof.** Grounded undirected Laplacians are positive definite under the stated
component condition, so both weighted matrices are symmetric positive
definite. If \(s\) is an eigenvalue of \(A_c\), some nonzero complex vector
\(x\) satisfies
\((s^2I+sH_v+H_p)x=0\). Premultiplying by \(x^*\) and normalizing gives
\(s^2+\alpha s+\beta=0\), where
\(\alpha=x^*H_vx/\|x\|^2>0\) and
\(\beta=x^*H_px/\|x\|^2>0\). Both roots have negative real part, so \(A_c\) is
Hurwitz. The variation-of-constants formula and a bound
\(\|e^{A_ct}\|\le Me^{-\lambda t}\) give the ISS inequality. \(\square\)

An explicit certificate avoids treating the spectral abscissa as an induced-
norm decay rate. Let \(P\succ0\) solve

\[
A_c^\top P+PA_c=-I,
\qquad
\kappa_P=\frac{\lambda_{\max}(P)}{\lambda_{\min}(P)}.
\]

With \(w=d_{net}+d_L\), the quadratic Lyapunov argument gives

\[
\|z(t)\|\le
\sqrt{\kappa_P}\,
e^{-t/(4\lambda_{\max}(P))}\|z(0)\|
+2\|PB_c\|_2\sqrt{\kappa_P}\,
\|w\|_{\infty,[0,t]}.
\]

This follows from
\(\dot V\le-\tfrac12\|z\|^2+2\|PB_c\|_2^2\|w\|^2\). It is conservative but
fully computable from the frozen controller/topology, without hardware data.

The optional row-wise degree normalization in the repository can make
\(H_p,H_v\) nonsymmetric. The theorem above applies directly to the primary
ring configuration where normalization is off. Directed/nonsymmetric variants
require a separate Lyapunov/LMI certificate and are OOD theory, not an automatic
extension.

### Theorem 6 — Exact sampled-data certificate for the MATLAB update

The implementation uses semi-implicit Euler with sample time \(h\): velocity is
updated first and the new velocity updates position. Define the dimensionally
homogeneous sampled state

\[
y_k=\begin{bmatrix}e_k\\h r_k\end{bmatrix}.
\]

Let \(\omega_k\) be the stacked acceleration disturbance and define the
analytic-leader position-step residual

\[
\chi_k=h v_L(t_{k+1})-[p_L(t_{k+1})-p_L(t_k)].
\]

For every follower, bounded leader acceleration gives
\(\|\chi_k\|\le\tfrac12\bar a_Lh^2\). With
\(u_k=[\chi_k^\top,(h^2\omega_k)^\top]^\top\), the exact one-coordinate update
is

\[
y_{k+1}=A_hy_k+D_hu_k,
\]

\[
A_h=
\begin{bmatrix}
I-h^2H_p&I-hH_v\\
-h^2H_p&I-hH_v
\end{bmatrix},
\qquad
D_h=\begin{bmatrix}I&I\\0&I\end{bmatrix}.
\]

If \(\rho(A_h)<1\), let \(P_h\succ0\) solve
\(A_h^\top P_hA_h-P_h=-I\). Define

\[
\alpha_h=\frac{1}{2\lambda_{\max}(P_h)},
\quad
\beta_h=2\|A_h^\top P_hD_h\|_2^2+
\|D_h^\top P_hD_h\|_2,
\]

\[
\sigma_h=\sqrt{1-\alpha_h},
\qquad
\Gamma_h=\sqrt{
\frac{\beta_h}{\alpha_h\lambda_{\min}(P_h)}}.
\]

Then

\[
\|y_k\|\le
\sqrt{\kappa(P_h)}\,\sigma_h^k\|y_0\|
+\Gamma_h\|u\|_{\infty,[0,k-1]}.
\]

**Proof.** For \(V_k=y_k^\top P_hy_k\), expand
\(V_{k+1}-V_k\), use the discrete Lyapunov equation, and apply Young's
inequality:

\[
V_{k+1}-V_k
\le-\tfrac12\|y_k\|^2+\beta_h\|u_k\|^2
\le-\alpha_hV_k+\beta_h\|u_k\|^2.
\]

Iterating and converting between \(V\) and \(\|y\|^2\) gives the bound.
\(\square\)

This is the certificate faithful to the primary MATLAB double-integrator path.
The continuous result remains useful background, but executable safety checks
use the sampled certificate.

### Corollary 2 — Sufficient separation condition

Let

\[
d_\star=\min_{i\ne j}\|\delta_i-\delta_j\|,
\qquad d_{safe}<d_\star,
\qquad r_{safe}=\frac{d_\star-d_{safe}}{\sqrt2}.
\]

If the right-hand side of Theorem 5 is strictly smaller than \(r_{safe}\), then
all pairwise separations exceed \(d_{safe}\) at that time. This follows from
\(\|e_i-e_j\|\le\sqrt2\|e\|\le\sqrt2\|z\|\).

### Corollary 3 — Finite-horizon probabilistic separation certificate

Let \(a_m=(m+1)T_b\), and use Theorem 2 at \(a_m\) to construct a stacked
acceleration-disturbance bound \(\bar\omega_m\). With \(n_f=N-1\), define

\[
\bar u_m=
\sqrt{n_f(\tfrac12\bar a_Lh^2)^2+h^4\bar\omega_m^2},
\]

\[
R_m^h(k_{eval})=
\sqrt{\kappa(P_h)}\sigma_h^{k_{eval}}\|y_0\|
+\Gamma_h\bar u_m.
\]

If A1--A7 hold, saturation is inactive, and

\[
R_m^h(k_{eval})<r_{safe},
\]

then over \([t_{eval},T]\),

\[
\Pr\{\min_{t\in[t_{eval},T]}d_{min}(t)\le d_{safe}\}
\le \min\{1,LW_m(1-q)^m\}.
\]

The age event is bounded over the full interval \([0,T]\), so its disturbance
bound also covers the transient before \(t_{eval}\). If
\(R_m^h(k_{eval})\ge r_{safe}\), the correct output is “not certified”; increasing
\(q\) cannot repair a deterministic formation/geometry failure.

## 9. Code-level certificates and proof obligations

`utils/formationTheoryCertificate.m` constructs \(H_p,H_v,A_c,A_h,D_h\) from an
actual configuration and reports symmetry, grounded eigenvalues, continuous
Hurwitz and sampled Schur margins, the leader-acceleration mismatch map and both
quadratic Lyapunov certificates. It is a consistency check, not a proof by
numerical eigenvalues.

For the current `defaultConfig()` only, the diagnostic is

| Quantity | Value |
|---|---:|
| \(\lambda_{\min}(H_p)\) | 1.342521 |
| \(\lambda_{\min}(H_v)\) | 1.628313 |
| spectral abscissa of \(A_c\) | -0.814174 |
| \(\lambda_{\min}(P),\lambda_{\max}(P)\) | 0.058763, 1.473650 |
| Lyapunov residual | \(8.30\times10^{-15}\) |
| explicit transient gain \(\sqrt{\kappa_P}\) | 5.007767 |
| explicit state decay rate | 0.169647 s\(^{-1}\) |
| explicit input gain | 6.535327 |
| leader-acceleration mismatch map, followers 2--5 | \([0,-1,0,-1]^\top\) |

The implementation-faithful sampled diagnostic at \(h=0.02\) s is

| Quantity | Value |
|---|---:|
| \(\rho(A_h)\) | 0.983582 |
| modal rate \(-\log\rho(A_h)/h\) | 0.827726 s\(^{-1}\) |
| discrete Lyapunov residual | \(4.80\times10^{-11}\) |
| \(\sqrt{\kappa(P_h)}\) for the unoptimized \(Q=I\) certificate | 93.435761 |
| induced decay rate \(-\log\sigma_h/h\) | 0.000466 s\(^{-1}\) |
| induced input gain \(\Gamma_h\) | \(5.18\times10^6\) |

The large last three constants do **not** mean the simulated formation is nearly
unstable: \(\rho(A_h)<1\). They show that the generic \(Q=I\), Young-inequality
global ISS bound is far too conservative for a useful numerical safety claim.
It remains logically valid, so a failed certificate is reported as “not
certified,” not “unsafe.” Optimizing the Lyapunov metric or computing a tighter
finite-horizon reachable set is a required next theory step before presenting a
numerical safety probability.

These numbers certify matrix construction for the current default; they are not
Study 2 performance results and must be regenerated from the preregistered
Study 2 configuration.

`utils/blockServiceLowerBound.m` evaluates the sequential DATA/ACK
minorization, and `utils/finiteHorizonSafetyCertificate.m` composes it with the
motion envelopes, explicit Lyapunov constants and finite-horizon union bound.
The latter deliberately labels its output conditional and returns failure bound
one when the deterministic separation inequality is not satisfied.

An empirical mean PDR or mean block-success rate is **not** an estimator of the
uniform conditional \(q\) in A7. Development traces may falsify a proposed
minorization and diagnose which admission/contention assumption failed; they
must not be used to raise \(q\) until the desired certificate appears. The
primary theorem value of \(q\) comes from declared worst-case contender,
admission, opportunity and residual-loss bounds. Hardware later tests whether
that operating set is credible.

`utils/standaloneAckValueCertificate.m` implements Proposition 3 and the A8
interval decision. Its accounting mode requires explicit seconds and objective
weights. Its predictive mode never substitutes empirical mean savings for
unique-lead bounds: without all five lead/externality quantities it reports
`NOT_EVALUATED`; overlapping bounds report `INCONCLUSIVE`.

EXP14F adds a generation-matched policy-level measurement: two complete
ACK-assisted and piggyback-only policies run from (t=0) on the same absolute
trace, and each accepted standalone confirmation is matched to the first
shadow confirmation on the same link with at least the same generation time.
This estimates the temporal separation of the two policy histories. It does
not by itself satisfy A8's per-decision counterfactual because prior ACK actions
may have made the histories differ before the focal event.

EXP14G closes that identity gap with a branch-at-decision replay. Identical
pre-decision network and plant/controller hashes, identical future exogenous
inputs and a focal admit/suppress intervention identify Proposition 5's local
contrast in N5, N10 and ALOHA. The results show that positive confirmation lead
can coexist with adverse true-AoI or formation effects. EXP14H then fails the
frozen N20 support minimum before replay; across G and H only 11/300 N20 parent
seeds contain an eligible event. Thus the prospective A8 certificate still
lacks a validated benefit-rate envelope, and N20 additionally fails practical
A9 support. Neither gap may be filled from favorable aggregate means.

The remaining proof/validation obligations are:

1. Estimate a conservative block pair \((T_b,q)\) over declared offered-load
   cells using the analytical minorization; report cells where any required
   factor is zero and therefore no positive credible \(q\) exists.
2. Record empirical \(\bar v_j,\bar a_j\) and compare observed reconstruction
   error with the envelopes without tuning the bounds on holdout.
3. Freeze and archive the explicit Lyapunov certificate \(P\) for the final
   primary configuration; do not reuse the diagnostic values above after a
   topology/controller change.
4. Check the unsaturated-region assumption and count saturation; if it fails,
   develop a nonlinear practical-stability result rather than citing Theorem 5
   or the sampled Theorem 6.
5. Decide whether Study 2 keeps partial leader-acceleration feed-forward or
   supplies it to all followers. Either choice must be fixed before holdout.
6. Extend only after the primary proof is complete: directed graphs, estimator
   noise, 6-DOF cascade and adversarial ACK integrity are separate results.
7. Freeze one interpretable feedback mapping using the completed development
   evidence, then validate it on disjoint seeds. Do not fit a fine-grained
   lead-value predictor from the 20-event cells, extrapolate into unsupported
   N20 states, or use EXP14E policy-level means as A8 bounds.

The hardware-independent boundary for the remaining trace obligation is now
specified in `docs/EXP15_TRACE_REPLAY_CONTRACT.md`. It accepts absolute-time
policy-independent loss-probability/state tensors and external occupancy, not
packet outcomes observed only when one evaluated policy transmitted. This
distinction is required before trace data can be used to challenge A7 or A8.
