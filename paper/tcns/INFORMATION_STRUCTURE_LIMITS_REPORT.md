# Information-structure limits for exact formation-control value

**Internal Research Lead return package (IL0--IL10)**  
**Decision:** `LIMITS_THEORY_STRONG`  
**Policy engineering:** closed; no scheduler was implemented  
**Numerical-validation source commit:** `b3064c7`  
**Authoritative run:**
`results/tcns_information_limits_validation/2026-09-07_231721`

## 1. Result in one paragraph

Within the frozen Gate-3 unsaturated sampled double-integrator scope, the
finite-horizon O1 baseline and each fixed link-action cross-term are exact
affine functions of a 99-dimensional augmented state.  A scalar affine
statistic is identifiable from sender information if and only if its
coefficient lies in the sender observation row space.  The condition fails
for all eight ordinary controller links and both pinned-leader payloads in
the actual N=5 graph, even after a complete finite held-memory observation
horizon.  For the two preregistered leader-originated payload classes, full
MATLAB trajectories close the former AF3 reachability gap: sender history,
sent history, ACK-free belief, and every candidate action response are
identical, while both the actual-receiver value and the packet-marginal
belief-weighted value have opposite signs.  One additional scalar is
mathematically sufficient for a fixed action, but no individual UAV or
sender--receiver pair can form that scalar in this configuration; the raw
information is distributed across all five UAVs.  Existing FB0 data then
give the exact packet-frequency break-even condition for acquiring it.

This is an information-structure and co-design limit.  It is not a universal
impossibility theorem for nonlinear UAVs, a new scheduler, or a claim that
all feedback architectures are uneconomic.

## 2. IL0: revised scientific question

The question is now:

> Under what information structures is the exact finite-horizon control
> value of a communication action identifiable, and when is the additional
> information economically realizable?

The motivating evidence is retained without reversal:

1. the deterministic communication-uncertainty bounds are valid;
2. `bound_trigger_v1` is Pareto dominated;
3. the exact Gate-3 cross-term predicts useful transmissions on the frozen
   branch diagnostic;
4. O1 shows centralized current-information Pareto headroom, with S4 retained
   as a negative boundary;
5. explicit ACK cost removes project-level support;
6. the ACK-free packet-memory PMF is accurately calibrated;
7. that PMF does not reveal the global baseline projection in the cross-term.

## 3. IL1: exact augmented affine model

### 3.1 Scope and state

The scope is exactly the one already certified in Gate 3:

- N=5, followers \(\mathcal F=\{2,3,4,5\}\), \(m=4\);
- fixed symmetric grounded graph;
- exact-state sampled double-integrator plant;
- semi-implicit Euler integration with \(h=0.02\) s;
- unsaturated controller;
- O1 frozen-current horizon \(H=25\) and DATA delay \(D=4\) samples.

There are eight ordinary receiver memories and two pinned-leader memories.
For Cartesian coordinate \(a\), define

\[
\xi^a=\operatorname{col}\!\left(
e^a,h w^a,p_L^a,hv_L^a,h^2a_L^a,
\{\hat p_{ij}^a,h\hat v_{ij}^a\}_{(i,j)\in\mathcal E},
\{\hat p_{iL}^a,h\hat v_{iL}^a,h^2\hat a_{iL}^a\}_{i\in\mathcal P}
\right).
\]

Here

\[
e_i=p_i-p_L-r_i,\qquad w_i=v_i-v_L.
\]

The one-axis dimension is

\[
2m+3+2|\mathcal E|+3|\mathcal P|
=8+3+16+6=33,
\]

and \(\xi=\operatorname{col}(\xi^x,\xi^y,\xi^z)\in\mathbb R^{99}\).
These variables, and no queues, channel uniforms, future reference values, or
simulator bookkeeping, are sufficient to reconstruct the frozen O1 response.

### 3.2 Baseline map derived from the implemented matrices

Let

\[
y_k=\operatorname{col}(e_k,hw_k),\qquad
A_h=\begin{bmatrix}
I-h^2H_p&I-hH_v\\
-h^2H_p&I-hH_v
\end{bmatrix},\qquad
\mathcal B=\begin{bmatrix}I\\I\end{bmatrix}.
\]

The implementation-derived maps satisfy

\[
y_k=T_y\xi_k,
\qquad
h^2\left[d^c_k+(\pi-\mathbf 1)a_{L,k}\right]
=T_\nu\xi_k+t_\nu.
\]

For the frozen-current O1 continuation, recursively define

\[
M_0=T_y,\quad b_0=0,
\]

\[
M_r=A_hM_{r-1}+\mathcal BT_\nu,
\qquad
b_r=A_hb_{r-1}+\mathcal Bt_\nu.
\]

With \(C_e=[I\;0]\), stacking \(C_eM_r\) and \(C_eb_r\) for
\(r=1,\ldots,H\), and then stacking the three coordinates, gives

\[
\operatorname{vec}(Z_k)=F_H\xi_k+r_H.
\]

`tcnsInformationLimitsModel.m` builds these matrices directly from
`formationTheoryCertificate.m` and the actual graph/controller gains.  No
matrix is fitted to trajectories.

### 3.3 Fixed-action and belief-weighted maps

For a fixed receiver-memory hypothesis \(s\), link \(j\to i\), and exact
Gate-3 response vector \(g_{ij,s}=\operatorname{vec}(G_{ij,s})\),

\[
\Xi_{ij,s}=\langle Z_k,G_{ij,s}\rangle_F
=g_{ij,s}^{\top}(F_H\xi_k+r_H)
=\ell_{ij,s}^{\top}\xi_k+c_{ij,s},
\]

where

\[
\ell_{ij,s}=F_H^{\top}g_{ij,s},\qquad
c_{ij,s}=r_H^{\top}g_{ij,s}.
\]

The memory coordinates fixed by hypothesis \(s\) are substituted and removed
from the free state.  For packet-memory probabilities \(b_s\), candidate
quadratics are averaged exactly:

\[
\bar\ell=\sum_s b_s\ell_s,\qquad
\bar c=\sum_s b_sc_s,
\]

\[
\bar q(x)=
-\frac{2p_s}{m}(\bar\ell^{\top}x+\bar c)
-\frac{p_s}{m}\sum_s b_s\|g_s\|_2^2.
\]

Thus the implementation does not make the invalid replacement
\(q(\mathbb E[R])=\mathbb E[q(R)]\).

The numerical validation reproduces O1 on all ten payload classes.  The
largest residual across \(F_H\xi+r_H\), action response, cross-term, and
quadratic value is \(4.34\times10^{-16}\).

## 4. IL2: strongest realistic sender information

The deterministic current observation of sender \(j\) is

\[
o_j=C_j\xi+d_j.
\]

`tcnsInformationLimitsSenderMap.m` includes:

- exact own position and velocity;
- all ordinary receiver memories feeding sender \(j\)'s controller;
- its pinned-leader memory, if pinned;
- its exact unsaturated command, even though this row is redundant;
- leader position, velocity, and acceleration when \(j=1\);
- known graph, gains, formation offsets, clock, channel law, and sent-packet
  records as known affine data.

It excludes only state stored at other receivers and remote physical state
that has not been communicated.  This is the strongest information actually
available in the implementation, not an artificially weakened map.

For the positive-probability no-delivery history used in the theorem
application, receiver memories are held and the exact augmented dynamics are

\[
x_{t+1}=A_0x_t+a_0.
\]

After fixed-hypothesis coordinates are substituted, the complete length-L
information map is

\[
\mathcal O_{j,L}
=\operatorname{col}(C_j,C_jA_0,\ldots,C_jA_0^L).
\]

The analysis takes \(L=n_r-1\), the complete finite observability horizon of
the reduced state: L=92 for ordinary data and L=89 for pinned-leader data.
Known action and sent-packet histories add no hidden-state rows beyond the
recorded local physical-state history.

## 5. IL3: identifiability theorem

### Theorem 1 (affine statistic identifiability)

Let \(x\in\mathbb R^n\), \(o=Cx+d\), and
\(v(x)=\ell^{\top}x+c\).  On an unrestricted state space, or locally on a
set containing a relative open neighborhood along \(\ker C\), \(v\) is a
function of \(o\) if and only if

\[
\ell\in\operatorname{row}(C).
\]

Equivalently, non-identifiability holds if and only if there is a
\(\delta x\in\ker C\) such that

\[
\ell^{\top}\delta x\ne0.
\]

#### Proof

If \(\ell\in\operatorname{row}(C)\), then
\(\ell=C^{\top}\alpha\) for some \(\alpha\), so

\[
v(x)=\alpha^{\top}(o-d)+c,
\]

which is determined by \(o\).  Conversely, if \(v\) is determined by
\(o\), then \(C(x+\delta x)=Cx\) must imply
\(v(x+\delta x)=v(x)\).  Hence \(\ell^{\top}\delta x=0\) for every
\(\delta x\in\ker C\).  Therefore
\(\ell\in(\ker C)^\perp=\operatorname{row}(C)\).  QED.

### Corollary 1 (finite local history)

For \(x_{t+1}=A_0x_t+a_0\), the coefficient of a decision-time statistic
\(\ell^{\top}x_L+c\), expressed at the history start, is
\((A_0^L)^{\top}\ell\).  It is identifiable from the complete local history
if and only if

\[
(A_0^L)^{\top}\ell\in\operatorname{row}(\mathcal O_{j,L}).
\]

The affine offsets change only the known constant and not identifiability.
This follows immediately by substituting the affine state recursion into
Theorem 1.

### Actual N=5 application

The table reports 3-D reduced dimensions and the normalized residual

\[
\frac{\|(I-C^\dagger C)\ell\|_2}{\max(\|\ell\|_2,\epsilon)}.
\]

The numerical rank tolerance is the preregistered
\(10^{-10}\max(1,\sigma_{\max})\).

| Payload \(j\to i\) | reduced n | current rank/nullity | current residual | history rank/nullity | history residual |
|---|---:|---:|---:|---:|---:|
| ordinary 1→2 | 93 | 9 / 84 | 0.51765 | 9 / 84 | 0.05604 |
| ordinary 1→5 | 93 | 9 / 84 | 0.23933 | 9 / 84 | 0.01023 |
| ordinary 2→3 | 93 | 27 / 66 | 0.98137 | 27 / 66 | 0.99989 |
| ordinary 3→2 | 93 | 18 / 75 | 0.99744 | 18 / 75 | 0.99992 |
| ordinary 3→4 | 93 | 18 / 75 | 0.99747 | 18 / 75 | 0.99992 |
| ordinary 4→3 | 93 | 27 / 66 | 0.97928 | 27 / 66 | 0.99989 |
| ordinary 4→5 | 93 | 27 / 66 | 0.96932 | 27 / 66 | 0.99988 |
| ordinary 5→4 | 93 | 18 / 75 | 0.99751 | 18 / 75 | 0.99992 |
| pin 1→2 | 90 | 9 / 81 | 0.09136 | 9 / 81 | 0.00412 |
| pin 1→4 | 90 | 9 / 81 | 0.06849 | 9 / 81 | 0.00363 |

All residuals are strictly nonzero by many orders above tolerance.  The rank
calculation is an application of Theorem 1, not the proof of the theorem.

## 6. IL4: dynamically reachable indistinguishable histories

The former AF3 output-space `PROOF GAP` is closed for the two preregistered
payload classes.

### Construction

The implemented leader has no incoming formation edge, so its local state and
command are independent of follower initial conditions.  Let \(J\) copy each
follower initial position/velocity perturbation into every ordinary receiver
memory that holds that follower, exactly matching
`initQueuedNetworkState.m`.  For a fixed target leader memory, let
\(a\) be the coefficient of the exact value at the decision time.  The hidden
initial-value gradient is

\[
g_h=J^{\top}(A_0^L)^{\top}a.
\]

For both frozen payload classes, \(g_h\ne0\) and
\(\mathcal O_{1,L}Jg_h=0\).  Let \(d=g_h/\|g_h\|\), choose the analytically
computed scalar \(\beta\) that places the nominal affine value at zero, and
use

\[
x_0^-=x_0+J(\beta-10^{-4})d,
\qquad
x_0^+=x_0+J(\beta+10^{-4})d.
\]

The leader follows the same small constant-velocity path in both histories.
One leader packet is attempted at \(t=h\) and erased.  This has probability
0.2 under the frozen IID channel.  The actual receiver memory is therefore
the common initial leader packet, while the sender's exact ACK-free belief
has the same two-state support in both histories.

### Validation

| Quantity | ordinary 1→5 | pin 1→4 |
|---|---:|---:|
| history length / duration | 92 / 1.84 s | 89 / 1.78 s |
| \(\|g_h\|_2\) | 0.0529704 | 0.0495740 |
| sender-history difference | 0 | 0 |
| candidate-response difference | 0 | 0 |
| belief-weighted \(\bar q^-\) | −5.29704e−6 | −4.95740e−6 |
| belief-weighted \(\bar q^+\) | +5.29704e−6 | +4.95740e−6 |
| actual-receiver \(q^-\) | −5.33798e−6 | −4.99772e−6 |
| actual-receiver \(q^+\) | +5.34903e−6 | +5.00701e−6 |
| every belief candidate reverses sign | yes | yes |
| maximum follower command | 0.06470 m/s² | 0.02829 m/s² |
| minimum saturation margin | 1.93530 m/s² | 1.97171 m/s² |
| full-MATLAB/affine residual | 2.51e−16 | 2.85e−16 |

Both histories use the real `distributedFormationPolicy.m` and
`integrateFollowers.m`; neither trajectory is synthesized only in output
space.  They remain strictly inside the unsaturated theorem region.  Sender
physical observation, controller observation, sent payload, packet-memory
belief, actual target receiver memory, and every candidate \(G_s\) are the
same.  Only sender-hidden follower/global formation state changes.

Therefore no deterministic policy using the declared sender information can
reproduce the exact value-sign decision at these information states.

## 7. IL5: value-sign identifiability

### Theorem 2 (local compatible-value interval)

Let \(q(x)=a^{\top}x+b\), let \(o=Cx+d\), and define the compatible local
fiber around \(x_0\) by

\[
\mathcal X_\rho(x_0,o)=
\{x_0+\delta:C\delta=0,\ \|\delta\|_2\le\rho\}.
\]

Let

\[
a_\perp=(I-C^\dagger C)a.
\]

Then the exact compatible value set is

\[
\mathcal Q(o)=
[q(x_0)-\rho\|a_\perp\|_2,
 q(x_0)+\rho\|a_\perp\|_2].
\]

#### Proof

For every compatible perturbation,
\(a^{\top}\delta=a_\perp^{\top}\delta\).  Cauchy--Schwarz gives the two
bounds.  When \(a_\perp\ne0\), both bounds are attained by
\(\delta=\pm\rho a_\perp/\|a_\perp\|\), which belongs to \(\ker C\).
QED.

Consequently, if

\[
q(x_0)-\rho\|a_\perp\|<0<
q(x_0)+\rho\|a_\perp\|,
\]

the sign is not sender-identifiable.  Theorem 2 is algebraic; the full
MATLAB constructions in Section 6 additionally prove physical reachability
of opposite signs for the two frozen payload classes.

## 8. IL6: minimum supplementary information

### Theorem 3 (one fixed scalar)

Let \(R=\operatorname{row}(C)\), and decompose

\[
\ell=\ell^\parallel+\ell^\perp,
\qquad
\ell^\parallel=C^\dagger C\ell,
\qquad
\ell^\perp=(I-C^\dagger C)\ell.
\]

For one fixed link/action, the additional scalar

\[
\theta=(\ell^\perp)^{\top}x
\]

is sufficient to reconstruct \(\ell^{\top}x+c\) exactly.  If
\(\ell^\perp\ne0\), one scalar dimension is also necessary among linear
supplementary measurements.

#### Proof

The parallel contribution is sender-computable because
\(\ell^\parallel\in R\); adding \(\theta\) supplies exactly the remaining
orthogonal contribution.  Zero added dimensions cannot identify the value by
Theorem 1.  Hence one is minimal.  QED.

### Theorem 4 (multiple simultaneous action values)

Let the rows of \(L\) contain coefficients for multiple action statistics and
let

\[
L_\perp=L(I-C^\dagger C).
\]

The minimum number of additional linear scalar measurements required to
identify every row of \(Lx\) is

\[
r_\star=\operatorname{rank}(L_\perp).
\]

#### Proof

Any supplementary measurement matrix \(H\) must have its projection onto
\(R^\perp\) span the row space of \(L_\perp\), so
\(\operatorname{rank}(H)\ge r_\star\).  Taking the rows of \(H\) as any row
basis of \(L_\perp\) attains equality.  QED.

### Who can form the fixed-action scalar?

For each of the ten actual payload classes, the following numerical facts
hold for both the current and complete-history formulations:

- appending \(\theta\) to sender information closes identifiability exactly;
- the sender cannot form \(\theta\);
- the target receiver cannot form \(\theta\) alone;
- the sender--receiver pair cannot form \(\theta\);
- no single UAV can form \(\theta\);
- the stacked observations of all five UAVs can form \(\theta\);
- exhaustive coalition enumeration requires the sender plus all four other
  UAVs for every evaluated action.

Thus one scalar is the **minimum final statistic**, but its raw operands are
global in this graph.  It can be synthesized as

\[
\theta=\sum_{a=1}^5\gamma_a^{\top}o_a
\text{known constant},
\]

because \(\ell^\perp\) lies in the row space of the all-agent stacked map.
This is global aggregation, not receiver-computable feedback and not a free
one-scalar packet.

## 9. IL7: feedback-economics corollary

### Corollary 2 (break-even supplementary information)

At target error \(E\), let \(C_P(E)\) be the frozen interpolated periodic
cost, \(D(E)\) the control-aware DATA cost, and let supplementary mechanisms
\(r=1,\ldots,R\) generate normalized rates \(A_r\) at prices \(\eta_r\).
The policy can be strictly Pareto cheaper only if

\[
D(E)+\sum_{r=1}^R\eta_rA_r<C_P(E).
\]

For one mechanism of rate \(A>0\), its critical price is

\[
\eta^\star(E)=\frac{C_P(E)-D(E)}{A}.
\]

At frozen price \(\eta_0=0.25\), the affordable fraction of a full feedback
stream is

\[
f^\star(E)=\frac{C_P(E)-D(E)}{0.25A}
=\frac{\eta^\star(E)}{0.25}.
\]

If \(C_P(E)-D(E)\le0\), no nonnegative-price supplemental stream can restore
Pareto advantage at that point.  This is an accounting identity, so its
proof is rearrangement of the strict cost inequality.

The frozen FB0 medians are:

| Scenario | median \(\eta^\star\) | median raw \(f^\star\) | full feedback affordable |
|---|---:|---:|---:|
| S2 | 0.7260 | 2.904 | 100.0% |
| S3 | 0.2198 | 0.879 | 27.3% |
| S4 | −0.7414 | −2.966 | 0% |
| S5 | −0.0474 | −0.190 | 9.1% |
| S6 | 0.0946 | 0.378 | 36.4% |

Because the N=5 scalar requires global raw-information aggregation, its cost
must include every packet needed to form/deliver it, not merely the final
payload size.  Under the current metric, piggybacking avoids cost only when
it creates no additional packet; the metric does not model payload bytes or
airtime.  No claim of free piggybacking is made.

## 10. IL9 numerical validation inventory

The authoritative artifact contains:

- `finite_horizon_F.csv` and `finite_horizon_r.csv`;
- `affine_validation.csv` for all ten payload classes;
- `link_identifiability.csv` with ranks, nullities, projection residuals,
  scalar closure, and coalition results;
- `dynamic_witness.csv` for both preregistered reachable-history pairs;
- `workspace.mat`, `summary.json`, provenance, console log, and one generated
  diagnostic figure.

The code checks:

1. \(F_H\xi+r_H\) equals the existing centralized O1 baseline;
2. \(\ell^{\top}\xi+c\) equals the O1 cross-term;
3. the affine quadratic value equals O1;
4. null witnesses satisfy \(C\delta=0\) and change the statistic;
5. appending the one missing scalar closes the row-space test;
6. full MATLAB trajectories match the augmented affine dynamics;
7. sender-indistinguishable trajectories reverse actual and candidatewise
   value signs.

## 11. Remaining proof gaps and scope limits

No gap remains in the linear-algebra iff proof, fixed-action minimal-scalar
proof, multi-action dimension proof, or the two preregistered dynamic
reachable sign witnesses.

The following limits remain explicit:

- `PROOF GAP`: dynamically reachable opposite-sign histories were proved for
  the frozen ordinary 1→5 and pin 1→4 classes, not separately for all ten
  payloads.  All ten have rigorous affine non-identifiability and numerical
  null witnesses, but only two have full trajectory closure.
- `PROOF GAP`: AF0 supplies a packet-memory marginal, not a complete Bayesian
  joint posterior over plant state, every receiver memory, and endogenous
  action history.  The present result is deterministic/set-membership
  identifiability.  It proves that the marginal alone cannot determine even
  the exact current-value sign; it does not claim a universal impossibility
  for a fully specified stochastic prior and optimal nonlinear filter.
- Saturation, 6-DOF dynamics, directed/switching graphs, disturbances, and
  arbitrary reference dynamics remain outside the theorem.
- The all-five-agent coalition result is specific to the actual N=5 graph,
  gains, state choice, and strongest local observation maps.
- Feedback economics uses the preregistered packet-frequency metric.  A
  byte/airtime/energy model may change the price of scalar aggregation.
- No request, pull, beacon, compression, or aggregation architecture has been
  designed or evaluated.

These are scope boundaries, not reasons to reopen scheduler tuning.

## 12. IL10 decision

Classification: **`LIMITS_THEORY_STRONG`**.

The frozen criteria are met:

- rigorous identifiability iff theorem: pass;
- actual system violates the condition on all 10 nonzero payload classes:
  pass;
- two preregistered dynamically reachable opposite-sign history pairs: pass;
- fixed-action minimal scalar and multi-action rank characterization: pass;
- ownership/coalition classification: pass, and it exposes a global
  aggregation requirement;
- feedback-economic break-even connection: pass.

The appropriate next Research Lead decision is whether this bounded result is
enough to develop a TCNS limits/co-design manuscript.  It does not authorize
a new scheduler or any held-out, scalability, or full-grid campaign.

## 13. Reproduction

MATLAB R2025a:

```matlab
run('tests/test_tcns_information_limits.m')
run('experiments/tcns_information_limits_validation.m')
```

The first command verifies the exact affine identities, row/null-space
contract, one-scalar closure, and both reachable histories.  The second
regenerates the complete machine-readable IL artifact.  The authoritative
run records source commit `b3064c7`, seed `27020001`, H=25, D=4, and MATLAB
R2025a in `meta.json`/`summary.json`.
