# R1 theory-depth and novelty-hardening report

**Classification:** `INTERNAL_REVIEW_PASS`
**Scientific scope:** exact affine communication-action value under the frozen
sampled linear formation model
**Authoritative R1 run:**
`results/tcns_r1_theory_depth_validation/2026-09-08_103325`
**Source commit recorded by MATLAB:** `05fa200`
**MATLAB:** 25.1 (R2025a), PCWIN64
**Policy/performance/held-out work:** none

This classification means the requested theory-depth revision is internally
complete. It is not submission authorization.

## 1. Novelty audit and resulting boundary

The 2025--2026 functional-observability audit changes the manuscript's claim
hierarchy rather than merely adding citations.

| Work | Established result that already implies part of this manuscript | Consequence here |
|---|---|---|
| Zhang, Fernando, Darouach, IEEE TAC 2025, [DOI 10.1109/TAC.2024.3462558](https://doi.org/10.1109/TAC.2024.3462558) | modal/structural functional-observability characterizations and functional sensor placement | The row-space test is an application; the coalition search is not a new generic optimization problem. |
| Krauss, Lopez, Mueller, IEEE L-CSS 2025, [DOI 10.1109/LCSYS.2025.3582512](https://doi.org/10.1109/LCSYS.2025.3582512) | necessary and sufficient sample-based functional-observability conditions under irregular/infrequent samples | Finite sampled history is not novelty by itself. |
| Darouach, Fernando, Automatica 2025, [DOI 10.1016/j.automatica.2025.112115](https://doi.org/10.1016/j.automatica.2025.112115) | functional-observer existence, reduced order, and pole placement | The missing instantaneous-statistic dimension is not functional-observer order. |
| Zhang, Fernando, Darouach, Automatica 2025, [DOI 10.1016/j.automatica.2025.112232](https://doi.org/10.1016/j.automatica.2025.112232) | structural functional observability/output controllability for generically diagonalizable systems and minimal placements | No new generic structural-observability claim is made. |
| Montanari, Duan, Motter, IEEE TAC 2025, [DOI 10.1109/TAC.2025.3552001](https://doi.org/10.1109/TAC.2025.3552001) | target-control/functional-observation duality | Target-functional system theory is treated as mature prior art. |
| Commault, Systems & Control Letters 2026, [DOI 10.1016/j.sysconle.2026.106503](https://doi.org/10.1016/j.sysconle.2026.106503) | structural functional observability with a fixed observable set and structural duality | The N=5 coalition result is only an instantiated ownership/economics result. |

The defensible addition is therefore the communication-decision layer: the
exact closed-loop action-value functional, the irreducible value radius and
binary decision regret when that functional is hidden, the joint missing
dimension for simultaneous actions, and the distinction between algebraic
sufficiency, information ownership, and acquisition price.

## 2. Irreducible value uncertainty

At a fixed sender observation, let the compatible exact-value image be

\[
\mathcal Q(o)=[q_-(o),q_+(o)],
\qquad
\Delta_q(o)=\frac{q_+(o)-q_-(o)}{2}.
\]

For any sender-local scalar estimate (y=\widehat q(o)), the triangle
inequality gives

\[
q_+-q_-\le |q_+-y|+|y-q_-|
\le 2\max\{|q_+-y|,|y-q_-|\}.
\]

Thus every estimate has worst-compatible-state error at least
\(\Delta_q\), and the interval midpoint attains that bound. Consequently,

\[
\inf_{\widehat q(o)}\sup_{x\in\mathcal X(o)}
|\widehat q(o)-q(x)|=\Delta_q(o).
\]

On the Euclidean information fiber, with
\(a_\perp=(I-C^\dagger C)a\) and hidden radius \(\rho\), this becomes
\(\Delta_q=\rho\|a_\perp\|_2\).

## 3. Unavoidable binary communication regret

When \(q_-<0<q_+\), a sender-local randomized decision transmits with one
probability (p) for all compatible states. Its positive- and
negative-endpoint regrets are

\[
R_+(p)=(1-p)q_+,
\qquad
R_-(p)=p(-q_-).
\]

The first decreases and the second increases in (p). Equalizing them gives

\[
p^*=\frac{q_+}{q_++(-q_-)},
\qquad
R_{\rm rand}^*=\frac{q_+(-q_-)}{q_++(-q_-)}.
\]

Restricting to deterministic decisions, (p\in\{0,1\}), gives

\[
R_{\rm det}^*=\min\{q_+,-q_-\}.
\]

Both are strictly positive for an interval that strictly straddles zero.
This is a local, one-decision minimax result over the declared compatible set,
not a dynamic-regret, Bayes-risk, mission-level, or universal stochastic-
control lower bound.

### Reachable N=5 witnesses

| Payload | (q_-) | (q_+) | (p^*) | (R_{\rm rand}^*) | (R_{\rm det}^*) |
|---|---:|---:|---:|---:|---:|
| ordinary 1->5 | -5.297043775e-6 | +5.297043775e-6 | 0.500000 | 2.648521887e-6 | 5.297043775e-6 |
| pinned leader 1->4 | -4.957400211e-6 | +4.957400211e-6 | 0.500000 | 2.478700105e-6 | 4.957400211e-6 |

These are the existing reachable, unsaturated, sender-indistinguishable
trajectory pairs; no new witness was selected after seeing R1 results.

## 4. Multiple actions and missing-information compression

For sender (j), stack all its controller-relevant action coefficients into
\(L_j\). The minimum number of supplementary instantaneous linear scalar
statistics is

\[
r_j^\star=\operatorname{rank}
\left[L_j(I-C_j^\dagger C_j)\right].
\]

| Sender | Actions (p_j) | (r_j^\star) | (r_j^\star/p_j) | Nonzero singular values | Minimum owning coalition |
|---:|---:|---:|---:|---|---|
| 1 | 4 | 3 | 0.75 | 26.9757915; 20.5236761; 1.8316357 | {1,2,3,4,5} |
| 2 | 1 | 1 | 1.00 | 49.7427406 | {1,2,3,4,5} |
| 3 | 2 | 2 | 1.00 | 55.0690308; 16.5170354 | {1,2,3,4,5} |
| 4 | 2 | 2 | 1.00 | 61.7395906; 5.3403120 | {1,2,3,4,5} |
| 5 | 1 | 1 | 1.00 | 45.7776587 | {1,2,3,4,5} |

Sender 1 has genuine algebraic compression across its four current action
values: three hidden directions suffice. The shared direction is explained,
not marketed as universal: its ordinary and pinned-leader unit actions into
follower 2 induce the same structural output-response direction. Senders 3
and 4 introduce independent hidden directions for their two actions.

For all five sender-wise value families, exhaustive N=5 enumeration finds
that only the five-agent coalition owns the entire missing subspace. Hence
(r_j^\star) is not a packet count: a three-dimensional missing subspace can
still require operands distributed across five agents.

## 5. Rank robustness

- All 10 nonidentifiability decisions are unchanged for relative tolerance
  factors (10^{-6},10^{-8},10^{-10},10^{-12},10^{-14}).
- The reference retained/discarded singular-value gaps range from
  (3.08\times10^{11}) to (1.32\times10^{12}).
- Appending the action-value row raises rank by exactly one for all 10 links.
- Seven raw information ranks remain constant over the full grid. Three
  follower maps retain roundoff-level modes at (10^{-14}), changing raw
  rank but leaving normalized value residuals at 0.071--0.080.
- Leader and pinned-payload raw ranks remain stable over the entire grid.
- An 80-digit row-basis projection reproduces all double-precision normalized
  residuals within relative difference (2.4\times10^{-15}). The smallest
  verified residual is 0.0036264466 for pinned leader 1->4.

The high-precision calculation operates on implementation-generated matrices.
It independently reevaluates the projection arithmetic but is not an exact
symbolic proof for arbitrary gains or graphs.

## 6. Communication interpretation

If the decision maker receives (r) independent real-valued linear scalar
statistics before deciding, exact identification of all (p) values requires
(r\ge r_\star\). Equality is algebraically achievable when the received
statistics span the missing row space. This is not a data-rate theorem:

\[
\text{statistic dimension}\ne\text{packet count}
\ne\text{bits/rate}\ne\text{distributed acquisition cost}.
\]

Coalition ownership says which agents collectively possess the operands; the
frozen FB0 break-even analysis then asks whether acquiring them can be paid
for. No aggregation protocol or scheduler is proposed.

## 7. Reproducibility and QA

Run from the repository root:

```matlab
run('tests/test_tcns_r1_theory_depth.m')
run('experiments/tcns_r1_theory_depth_validation.m')
```

The authoritative run records seed 27020001, H=25, D=4, source commit
`05fa200`, MATLAB R2025a, all machine-readable tables, the singular spectra,
the tolerance sweep, the witness regrets, and the console log. The earlier
`2026-09-08_101541` directory is retained as a preliminary run rather than
rewritten.

The manuscript source defects in `\qquad` and the malformed inline delimiter
were corrected. A source audit found 30 cited keys and no key absent from the
81-entry bibliography; inline-math delimiter counts are balanced. Tectonic
0.17.0 compiled the IEEEtran manuscript to a visually inspected 10-page PDF
with zero undefined citations, zero undefined cross-references, zero overfull
boxes, and zero LaTeX errors. The retained log records underfull-box notices
and four XeTeX/IEEEtran class-load `TU/ptm` font-shape fallbacks; these do not
change references or body-font loading, but a final publisher-toolchain build
remains part of pre-submission QA. The compiled PDF and log are stored beside
the manuscript source.

## 8. Internal verdict

`INTERNAL_REVIEW_PASS`

The objection “this is only functional observability and sensor selection” is
now answered narrowly: those classical components are credited as such, while
the manuscript establishes a quantitative communication-decision consequence
and a nontrivial simultaneous-action/ownership/economics closure on the actual
formation implementation. The remaining novelty judgment is editorial, not
an unresolved mathematical gap inside the stated scope.
