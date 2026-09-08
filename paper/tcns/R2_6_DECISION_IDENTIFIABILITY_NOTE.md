# R2.6 decision-identifiability closure

**Status:** coauthor theory report; authoritative manuscript unchanged

**Frozen manuscript HEAD:** `2fd13592185377fbac65e0e5805418e225293647`

**Frozen R2 input:** `results/tcns_r2_generalization_validation/2026-09-08_161130`

**R2.6 post-processing run:** `results/tcns_r2_6_decision_identifiability/2026-09-08_232116`

**Numerical reference tolerance:** `1e-10`, inherited from R2

**New simulations, graphs, seeds, policies, or noise models:** none

This note closes a real decision-theory gap. Exact reconstruction of every
action value, reconstruction of all relative values, and selection of an
optimal action on one information fiber are three different properties. The
first implies the second, and the second is sufficient for ranking, but
neither converse holds in general.

## 1. Setup and the three distinct objects

Let the finite action set be \(\mathcal A=\{1,\ldots,p\}\),

\[
q_a(x)=\ell_a^\top x+c_a,\qquad o=Cx+d,
\]

and stack \(\ell_a^\top\) as the rows of \(L\in\mathbb R^{p\times n}\).
Write

\[
P_C=C^\dagger C,\qquad P_\perp=I-P_C.
\]

For exact algebra, \(P_C\) is the orthogonal projector onto \(\row(C)\).
The numerical artifact constructs the same projector from the retained right
singular vectors at the frozen R2 tolerance.

The objects are:

1. **Individual-value reconstruction.** Every \(q_a\) is a function of
   \(o\). Under the same domain qualification as the manuscript's current
   static theorem, this is equivalent to \(\row(L)\subseteq\row(C)\), or
   \(LP_\perp=0\).
2. **Relative-value reconstruction.** Every
   \(d_{ab}=q_a-q_b\) is a function of \(o\). This can hold even when a common
   hidden offset makes every individual value nonidentifiable.
3. **Fiberwise optimal-action decidability.** At one observation, it is enough
   that one action be optimal at every compatible state. This can hold even
   when some relative values vary on the fiber.

The row-space equivalences below apply on \(\mathbb R^n\), or locally on a
feasible set containing an open relative neighborhood in every direction of
\(\ker C\), exactly as in the current manuscript. On an arbitrary restricted
set, the set itself can remove hidden directions, so the unrestricted
row-space condition remains sufficient but need not be necessary. The direct
fiberwise theorem does not need this row-space-domain assumption.

## 2. Relative-value identifiability

Choose any \(B\in\mathbb R^{(p-1)\times p}\) with full row rank and

\[
\row(B)=\mathbf 1^\perp.
\]

For reference action \(r\), one example stacks \(e_a^\top-e_r^\top\) for
all \(a\ne r\). Define

\[
L_{\rm rel}=BL,\qquad c_{\rm rel}=Bc.
\]

### Proposition A (all relative affine values)

Under the domain qualification above, all pairwise action-value differences
are exactly identifiable from \(o\) if and only if

\[
\row(L_{\rm rel})\subseteq\row(C),
\]

equivalently,

\[
L_{\rm rel}(I-C^\dagger C)=0.
\]

The exact conclusion is independent of the chosen full-rank difference basis
\(B\).

**Proof.** The coefficient of \(d_{ab}\) is
\((e_a-e_b)^\top L\). The vectors \(e_a-e_b\) span
\(\mathbf 1^\perp=\row(B)\). Hence every pairwise coefficient lies in
\(\row(C)\) if and only if every row of \(BL\) lies in \(\row(C)\). Orthogonal
projection onto \(\row(C)^\perp=\ker C\) gives the equivalent projector
condition. If \(B_1\) and \(B_2\) are two such bases, there is an invertible
\((p-1)\)-square matrix \(T\) with \(B_2=TB_1\). Therefore
\(\row(B_2L)=\row(TB_1L)=\row(B_1L)\). \(\square\)

The constants \(c_a\) are known and do not affect identifiability.

### Reviewer counterexample: common hidden offset

Let \(x=(o,z)\), \(C=[1\ 0]\), and

\[
q_1=o+z,\qquad q_2=2o+z.
\]

Neither individual value is reconstructible because each contains hidden
\(z\). Nevertheless, \(q_1-q_2=-o\) is exactly reconstructible. Numerically,
\(\rank(LP_\perp)=1\) while \(\rank(BLP_\perp)=0\). Thus individual and
relative identifiability are not equivalent.

Basis invariance is exact algebra. A finite-tolerance numerical rank can
change under an arbitrarily ill-conditioned rescaling of a basis; the R2.6
artifact therefore uses the fixed reference-action basis and reports
projection residuals in addition to ranks. The synthetic test compares two
well-conditioned full-rank bases.

## 3. Minimum information for all relative values

Define

\[
r_{\rm value}^\star=\rank(LP_\perp),\qquad
r_{\rm rel}^\star=\rank(BLP_\perp).
\]

### Proposition B (minimum relative-value statistic dimension)

Under an instantaneous, noiseless, arbitrary-precision real-valued linear
supplementary map \(Hx\), the minimum number of scalar rows needed to recover
all relative affine action values is

\[
r_{\rm rel}^\star=\rank\!\left(BL(I-C^\dagger C)\right).
\]

Moreover,

\[
r_{\rm rel}^\star\le r_{\rm value}^\star,
\]

and strict inequality is possible.

**Proof.** If \(BL\) is identifiable from \(\col(C,H)x\), project any row-space
representation onto \(\ker C\). This gives

\[
\row(BLP_\perp)\subseteq\row(HP_\perp).
\]

Consequently the number of rows of \(H\) is at least
\(\rank(BLP_\perp)\). Conversely, choose the rows of \(H\) as any row basis of
\(BLP_\perp\). Since \(BL=BLP_C+BLP_\perp\), with the first term in
\(\row(C)\) and the second in \(\row(H)\), every relative value is then
identifiable. Finally,

\[
BLP_\perp=B(LP_\perp)
\]

implies \(\rank(BLP_\perp)\le\rank(LP_\perp)\). The common-hidden-offset
example has \(r_{\rm rel}^\star=0<1=r_{\rm value}^\star\), proving that the
inequality can be strict. \(\square\)

This is the **minimum linear-statistic dimension for recovering all relative
action values**. It is sufficient for exact ranking and argmax, but it is not
the universally minimum information needed for a particular constrained or
fiber-specific decision.

## 4. Exact fiberwise argmax decidability

For a nonempty compatible fiber \(\mathcal X(o)\), define the set-valued
full-information optimizer

\[
\mathcal A^\star(x)=\arg\max_{a\in\mathcal A}q_a(x)
\]

and its common-optimal set

\[
\Gamma(o)=\bigcap_{x\in\mathcal X(o)}\mathcal A^\star(x).
\]

### Theorem C (exact local decision criterion)

A deterministic sender-local action can be full-information optimal for every
\(x\in\mathcal X(o)\) if and only if

\[
\Gamma(o)\ne\varnothing.
\]

If the intersection is nonempty, the sender may select any member. If it is
empty, no deterministic function of \(o\) can be full-information optimal for
every compatible state.

**Proof.** A deterministic sender observes the same \(o\) for all states in
the fiber and must therefore return one action \(a_o\). It is optimal at every
compatible state exactly when
\(a_o\in\mathcal A^\star(x)\) for every \(x\), which is exactly
\(a_o\in\Gamma(o)\). \(\square\)

This statement deliberately preserves ties. If a single-valued tie-break
\(t(x)\in\mathcal A^\star(x)\) is imposed, exact reproduction of that rule
requires \(t(x)\) to be constant over the fiber. This is a different and
stronger requirement: a common optimal action can exist even when a chosen
state-dependent tie-break changes at a boundary.

## 5. Closed form on the Euclidean local fiber

Let

\[
\mathcal X(o)=\{x_0+v:v\in\ker C,\ \|v\|_2\le\rho\},\qquad \rho\ge0,
\]

and, for actions \(a,b\), define

\[
d_{ab}(x_0)=q_a(x_0)-q_b(x_0),\qquad
h_{ab}=P_\perp(\ell_a-\ell_b).
\]

### Proposition D (pairwise interval and common maximizer)

The exact image of the pairwise difference is

\[
d_{ab}(\mathcal X(o))=
\left[d_{ab}(x_0)-\rho\|h_{ab}\|_2,
      d_{ab}(x_0)+\rho\|h_{ab}\|_2\right].
\]

Action \(a\) is optimal for every compatible state if and only if, for every
\(b\ne a\),

\[
m_{ab}(x_0,\rho):=
d_{ab}(x_0)-\rho\|h_{ab}\|_2\ge0.
\]

Therefore an exact locally valid full-information action exists if and only
if at least one action satisfies all these inequalities.

**Proof.** For \(v\in\ker C\),

\[
d_{ab}(x_0+v)=d_{ab}(x_0)+(\ell_a-\ell_b)^\top v
=d_{ab}(x_0)+h_{ab}^\top v.
\]

Cauchy--Schwarz bounds the final term by
\(\rho\|h_{ab}\|_2\), and the upper and lower bounds are attained by choosing
\(v=\pm\rho h_{ab}/\|h_{ab}\|_2\) when \(h_{ab}\ne0\); if it is zero, the
interval is a singleton. Action \(a\) is optimal everywhere exactly when
\(d_{ab}\ge0\) everywhere for every competitor \(b\), which is equivalent to
the lower-endpoint inequalities. Theorem C gives the existence statement.
\(\square\)

If every inequality is strict for \(b\ne a\), then \(a\) is the unique
maximizer at every state in the fiber. Conversely, unique optimality at every
state on this compact fiber implies these strict lower margins. This should
not be confused with \(\Gamma(o)=\{a\}\): the intersection can be a singleton
even if another action ties \(a\) only on a proper subset of the fiber, in
which case one margin is zero.

The action margin

\[
m_a(x_0,\rho)=\min_{b\ne a}m_{ab}(x_0,\rho)
\]

has the intended limited robustness interpretation:

- \(m_a>0\): \(a\) remains strictly optimal throughout the declared fiber;
- \(m_a=0\): boundary/tie;
- \(m_a<0\): \(a\) is not guaranteed optimal throughout the fiber.

No sensor-noise or model-mismatch theorem follows from this result. A proved
additional uncertainty support bound could enlarge the pairwise interval,
but that model is outside R2.6.

## 6. Binary decision corollary

Let action 1 be transmit and action 0 be no transmission. With net benefit

\[
d_{10}(x)=q_1(x)-q_0(x)-\tau,
\]

the interval on the Euclidean fiber is

\[
[d_{10}(x_0)-\rho\|h_{10}\|_2,
  d_{10}(x_0)+\rho\|h_{10}\|_2].
\]

Transmit is common-optimal if the lower endpoint is nonnegative. No transmit
is common-optimal if the upper endpoint is nonpositive. If the interval
strictly straddles zero, neither action is common-optimal, reproducing the
current manuscript's two-action sign/threshold impossibility. If an endpoint
equals zero, the set-valued formulation admits the action that is weakly
optimal throughout; an externally imposed strict rule such as “transmit iff
\(d_{10}>0\)” must be analyzed separately at that tie.

## 7. Two scheduling semantics

### A. Exactly one of \(p\) communication actions

Only relative ordering among \(q_1,\ldots,q_p\) matters. A common hidden
offset can cancel, and \(r_{\rm rel}^\star\), not
\(r_{\rm value}^\star\), is the dimension needed to recover every relative
value.

### B. At most one transmission

Include no transmission as action 0 with \(q_0=0\), or subtract a fixed
opportunity cost \(\tau\) from each communication action. Differences against
action 0 retain every coefficient row of \(L\). Therefore, for this fixed
no-transmission baseline,

\[
\rank(L_{\rm augmented,rel}P_\perp)
=\rank(LP_\perp)=r_{\rm value}^\star.
\]

Thus a common hidden offset across all communication actions is irrelevant to
exactly-one ranking but remains relevant to transmit versus no transmit. The
communication-only \(r_{\rm rel}^\star\) cannot be used to claim that the
implemented at-most-one scheduler is locally decidable. Fiber dominance may
still make a particular decision possible, but that must be established by
Theorem C or Proposition D.

## 8. Frozen-registry post-processing

The R2.6 code read the persisted R2 registry/action/sender CSVs, reconstructed
only the affine matrices specified by those exact rows, and required every
action ID, action count, and reconstructed \(r_{\rm value}^\star\) to match
the frozen result. It did not generate a state trajectory. Outputs are:

- `decision_identifiability_sender.csv` (448 sender-cells);
- `decision_identifiability_n5_frozen.csv` (five senders);
- `decision_identifiability_n5_binary_witness.csv` (ten persisted witnesses);
- `summary.json` and `workspace.mat`.

Across all 448 sender-cells:

- all 1320 individual action rows remain nonidentifiable;
- \(r_{\rm rel}^\star=r_{\rm value}^\star-1\) in every sender-cell;
- strict reduction occurs in all 448 cells, including 360 nontrivial sets with
  \(p\ge2\);
- 88 cells have \(p=1\), for which \(r_{\rm rel}^\star=0\) and relative
  ordering is vacuous;
- no nontrivial \(p\ge2\) set has all pairwise values identifiable;
- among \(p\ge2\) sets, the maximum-pairwise normalized projection residual
  ranges from `0.938061135901660` to `1.0`, far above the frozen tolerance.

Leader patterns, each repeated over the two pin splits, two horizons, and two
delays, are:

| Graph | N | \(p_1\) | \(r_{\rm value,1}^\star\) | \(r_{\rm rel,1}^\star\) |
|---|---:|---:|---:|---:|
| ring2 | 5 / 7 / 9 | 4 / 5 / 6 | 3 / 4 / 5 | 2 / 3 / 4 |
| sparse4 | 5 / 7 / 9 | 6 / 7 / 8 | 4 / 5 / 6 | 3 / 4 / 5 |
| geometric | 5 / 7 / 9 | 6 / 7 / 8 | 4 / 5 / 6 | 3 / 4 / 5 |

For every tested follower set with \(p\ge2\),
\(r_{\rm value}^\star=p\) and \(r_{\rm rel}^\star=p-1\). Single-action
followers have the vacuous \((1,0)\) pair.

For the frozen N=5 `ring2/even`, \(H=25,D=4\) instance:

| Sender | \(p\) | \(r_{\rm value}^\star\) | \(r_{\rm rel}^\star\) | Ratio | Full relative identifiable? |
|---:|---:|---:|---:|---:|---|
| 1 | 4 | 3 | 2 | 0.6667 | no |
| 2 | 1 | 1 | 0 | 0 | vacuously yes |
| 3 | 2 | 2 | 1 | 0.5 | no |
| 4 | 2 | 2 | 1 | 0.5 | no |
| 5 | 1 | 1 | 0 | 0 | vacuously yes |

The frozen data therefore realize outcome **A/D**: relative-value recovery
always requires fewer hidden dimensions, but only partial, nonzero reduction
occurs for every meaningful multi-action set. Outcome C (full pairwise
identifiability despite hidden individual values) does not occur for any
nontrivial actual sender set. The only \(r_{\rm rel}^\star=0\) rows have
\(p=1\) and must not be marketed as an ordering result.

The ten persisted N=5 binary witnesses all have \(q_-<0<q_+\). Hence the two
compatible states already prove that neither transmit nor no-transmit is
common-optimal on each witness pair. This is consistent with the at-most-one
semantic warning: communication-action cancellation does not remove the
transmit/no-transmit ambiguity.

The persisted actual-action witnesses use action-specific conditioned fibers,
reference states, and radii. Combining them into a sender-wise multi-action
fiber would change the evidentiary object. R2.6 therefore does **not** report a
dataset common-maximizer verdict for exactly-one multi-action selection. This
is a principled “not evaluated,” not a negative result. The synthetic tests
independently establish that a common maximizer can exist even when
\(r_{\rm rel}^\star>0\).

## 9. Deterministic tests

`tests/test_tcns_r2_6_decision_identifiability.m` covers:

1. common hidden offset: \(r_{\rm value}^\star=1\),
   \(r_{\rm rel}^\star=0\);
2. a difference varying along \(\ker C\);
3. a strictly common maximizer despite a nonidentifiable difference;
4. a difference crossing zero and an empty argmax intersection;
5. binary threshold reduction, including a boundary tie;
6. invariance under two full-rank bases of \(\mathbf1^\perp\).

It also verifies the generated 448-row registry artifact, all frozen
\(r_{\rm value}^\star\) matches, the five N=5 senders, and all ten persisted
binary witness ambiguities. Result: `PASS`.

## 10. Counterexamples and wording constraints

The following stronger phrasings are false or unsupported:

- “individual value identifiability is equivalent to decision
  identifiability” is false by the common-hidden-offset example;
- “\(r_{\rm rel}^\star\) is the minimum information for argmax” is false in
  general: a bounded fiber can have a dominating action while a pairwise
  difference still has a hidden component;
- “strict margins are necessary for the common-optimal intersection to be a
  singleton” is false when a competitor ties only on a proper subset; strict
  margins characterize one action being uniquely optimal at every state;
- “basis invariance guarantees identical finite-tolerance numerical ranks for
  arbitrary scaled bases” is false without a conditioning qualification;
- “communication-only cancellation makes the real at-most-one scheduler
  decidable” is false because comparisons with no transmission preserve the
  hidden common offset.

## 11. Title assessment and stop point

The title *When Is Control-Aware Communication Locally Decidable?* is now
mathematically justified at the theory-note level: Theorem C is the exact
set-valued answer, and Proposition D gives a closed-form answer on the local
Euclidean fiber already used by the paper. The title is not justified by
relative-value rank alone. The authoritative manuscript at the frozen HEAD
does not yet contain this closure and has intentionally not been edited;
publication-level alignment awaits coauthor approval.

No novelty is claimed for generic functional observability, arbitrary graphs,
noise robustness, or a new scheduler. R2.6 stops at the requested theory and
frozen-data report.
