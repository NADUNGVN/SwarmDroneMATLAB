# SQ final theorem audit

**Audit date:** 2026-09-08  
**Baseline audited:** accepted science at
**7c679610af2098acc2aa5e8f005e81a898435f29**, followed only by SQ scope and
wording corrections.

## 1. Fixed-response affine benefit

For fixed \(F,r,Q=Q^\top\succeq0\), and action response \(g_a\),

\[
\begin{aligned}
q_a(x)
&=(Fx+r)^\top Q(Fx+r)\\
&\quad -(Fx+r+g_a)^\top Q(Fx+r+g_a)\\
&=-2g_a^\top QFx-2g_a^\top Qr-g_a^\top Qg_a.
\end{aligned}
\]

Therefore \(\ell_a=-2F^\top Qg_a\) and
\(c_a=-2r^\top Qg_a-g_a^\top Qg_a\). The proof is exact only when \(g_a\)
is fixed on the information-compatible set or its state dependence has been
augmented/conditioned. The manuscript now states this as a conditional
fixed-response finite-horizon marginal output-cost benefit, not a Bellman VoI
or state-action value function.

**Verdict:** correct within the stated scope.

## 2. Static and finite-history identifiability

For \(o=Cx+d_o\), \(q=\ell^\top x+c\) is constant on every affine fiber
\(x+\ker C\) if and only if \(\ell^\top v=0\) for every \(v\in\ker C\).
Using \((\ker C)^\perp=\operatorname{row}(C)\) gives the stated iff condition.

For \(x_{t+1}=A_0x_t+a_0\), the decision-time coefficient with respect to
\(x_0\) is \((A_0^L)^\top\ell\), while the stacked observation coefficient is
\(\mathcal O_L=\operatorname{col}(C,CA_0,\ldots,CA_0^L)\). Applying the static
fiber result gives the finite-history statement. Affine constants do not
affect either row-space test.

These are correctly attributed as functional/sample-based observability
specializations. They are not claimed as new observer-design results.

**Verdict:** correct.

## 3. Minimax value radius

The theorem now assumes explicitly that the value image is a nonempty closed
finite interval \(\mathcal Q(o)=[q_-,q_+]\). For any point estimate \(y\),

\[
q_+-q_-\le |q_+-y|+|y-q_-|,
\]

so the maximum endpoint error is at least
\((q_+-q_-)/2=\Delta_q\). The midpoint
\((q_-+q_+)/2\) has error at most \(\Delta_q\) at every point of the interval
and attains it at both endpoints.

For the Euclidean fiber, the hidden component
\(a_\perp=(I-C^\dagger C)a\) is in \(\ker C\); Cauchy--Schwarz and the
attaining perturbations
\(\pm\rho a_\perp/\|a_\perp\|_2\) give
\(\Delta_q=\rho\|a_\perp\|_2\). The zero-projection case collapses to a
singleton.

**Verdict:** correct.

## 4. Randomized and deterministic one-decision regret

Under strict straddling \(q_-<0<q_+\), let \(a=q_+>0\) and
\(b=-q_->0\). A sender-local rule transmits with probability \(p\). Endpoint
regrets are

\[
R_+(p)=(1-p)a,\qquad R_-(p)=pb.
\]

The first decreases and the second increases on \([0,1]\), so the minimax
solution equalizes them:

\[
p^\star=\frac{a}{a+b}
=\frac{q_+}{q_++(-q_-)},
\qquad
R_{\rm rand}^\star=\frac{ab}{a+b}.
\]

For deterministic \(p\in\{0,1\}\), the two worst-case regrets are \(a\) and
\(b\), hence \(R_{\rm det}^\star=\min\{a,b\}\). This expression is asserted
only for strict straddling.

Edge cases:

- \(q_-=0<q_+\): transmit, \(p=1\), regret zero;
- \(q_-<0=q_+\): do not transmit, \(p=0\), regret zero;
- \(q_-=q_+=0\): every decision has zero regret;
- non-straddling interval: take the common-sign deterministic action, regret
  zero;
- symmetric \([-a,a]\): \(p^\star=1/2\),
  \(R_{\rm rand}^\star=a/2\), \(R_{\rm det}^\star=a\).

For a transmission price/threshold \(\tau\), the theorem applies to
\(v=q-\tau\) and interval \([q_--\tau,q_+-\tau]\). The two formation witnesses
use \(\tau=0\). This is a local, one-decision minimax result, not a stochastic
dynamic-regret lower bound.

**Verdict:** correct.

## 5. Multiple-action supplementary dimension

Let \(P_C=C^\dagger C\), which is the orthogonal projector onto
\(\operatorname{row}(C)\), and let
\(L_\perp=L(I-P_C)\). Suppose an instantaneous linear map \(H\) makes every
row of \(L\) identifiable from \(\operatorname{col}(C,H)x\).
After projecting onto \(\ker C\),

\[
\operatorname{row}(L_\perp)
\subseteq
\operatorname{row}\!\left(H(I-P_C)\right).
\]

Therefore the number \(r\) of scalar rows of \(H\) is at least
\(\operatorname{rank}(L_\perp)\). Conversely, choose the rows of \(H\) as any
row basis of \(L_\perp\). Every row of \(L\) is then the sum of a row in
\(\operatorname{row}(C)\) and a row in \(\operatorname{row}(H)\), so all
values are identifiable.

The lower bound and construction assume noiseless, instantaneous,
arbitrary-precision, real-valued linear scalar statistics. They do not cover
arbitrary encoders, quantization, bits, packet count, dynamic observers,
latency, or noisy transport. The manuscript and corollary now state every one
of these restrictions.

**Verdict:** correct.

## 6. Coalition statement

Replacing \(C\) with
\(C_{\mathcal S}=\operatorname{col}_{i\in\mathcal S}C_i\) gives the coalition
iff statement directly. The exhaustive N=5 minimum-coalition calculation is
an application of established sensor-selection geometry, not a new general
algorithm. Its reported all-five result is now conditioned on the selected
global output, identity weighting, \(H=25\), graph, and observation maps.

**Verdict:** correct within the instantiated model.

## Final theorem-QA decision

**NO UNRESOLVED THEOREM CORRECTNESS ISSUE.**

The audit produced scope clarifications and boundary-case additions, but no
change to the frozen scientific result.
