# GM generalization and manuscript gate report

**Classification:** `MANUSCRIPT_READY_FOR_INTERNAL_REVIEW`  
**Scientific thesis:** frozen  
**Policy engineering:** permanently closed  
**Held-out / scalability / full grid:** not run  
**Authoritative theorem-validation run:**
`results/tcns_information_limits_validation/2026-09-08_060901`

## 1. Generic result

For fixed response \(g_a\) and quadratic finite-horizon output cost,

\[
q_a(x)=\|Fx+r\|_Q^2-\|Fx+r+g_a\|_Q^2
=\ell_a^\top x+c_a,
\]

with \(\ell_a=-2F^\top Qg_a\) and
\(c_a=-2r^\top Qg_a-g_a^\top Qg_a\).  Exact value is identifiable from
\(o=Cx+d_o\) iff \(\ell_a\in\operatorname{row}(C)\).  For affine dynamics and
a length-L history, the exact condition is

\[
(A_0^L)^\top\ell_a\in
\operatorname{row}\operatorname{col}(C,CA_0,\ldots,CA_0^L).
\]

If an information fiber spans both signs, no deterministic local policy can
always reproduce the exact sign on that fiber.  For multiple action
coefficients L, the minimum number of supplementary linear scalar statistics
is

\[
r_\star=\operatorname{rank}\{L(I-C^\dagger C)\}.
\]

These are action-value specializations of functional observability.  The
report and manuscript explicitly do not claim the generic row-space fact as a
new linear-algebra theorem.

## 2. Formation mapping and proof audit

The generic state is the exact 99-dimensional Gate-3 augmented state; F and r
are the sampled H=25 formation-response maps; each g is the D=4 link-action
response; and C is the strongest realistic sender map.  All maps are assembled
from controller/dynamics matrices, not fitted.

The maximum numerical identity residual over all ten payloads remains
\(4.34\times10^{-16}\).  All ten fail current and complete-held-history
identifiability.  One missing scalar closes every fixed-action row-space gap.
For the implemented N=5 observation topology, no individual or endpoint pair
owns that scalar; exhaustive enumeration requires the five-agent coalition for
each payload.

Two full dynamically reachable witnesses close physical/sign relevance for
the preregistered ordinary 1->5 and pinned-leader 1->4 payloads.  Sender
observations and action responses agree exactly, expected action values have
opposite signs, affine residuals are below \(3\times10^{-16}\), and commands
remain more than 1.93 m/s2 inside the acceleration limit.

No unresolved proof gap remains inside the stated claims.  The fixed-response,
linear-statistic, local-operating-set, and two-witness scopes are explicit.

## 3. Literature/novelty verdict

The deep audit materially narrowed the novelty statement:

- functional observability already supplies the row-space criterion;
- target sensor selection overlaps the coalition formulation;
- decentralized information structure is classical;
- VoI already supplies marginal regulation value;
- ACK-free receiver-memory hypotheses already exist in formation control.

The defensible synthesis is therefore: exact communication-action value as
the target functional; sign-decision consequences; minimum statistic
dimension versus distributed ownership/acquisition; and a frozen
formation/economics closure.  `GM_NOVELTY_MATRIX.md` records the full matrix and
threats.

## 4. Empirical role

Six main-paper figures are generated from scripts.  They show architecture,
bound-trigger falsification, O1 S2 headroom with S4 negative boundary,
feedback economics, row/null-space geometry, and reachable sign witnesses.
They support the theory and are not reframed as held-out algorithm validation.

The claim/evidence ledger bars population claims from five-seed development
data.  It also preserves the negative S4 boundary and the stopped explicit-ACK
and ACK-free policy tracks.

## 5. Delivered source package

- generic results and proof audit: `GM_THEORY_AUDIT.md`;
- novelty/contribution matrix: `GM_NOVELTY_MATRIX.md`;
- figure/table plan: `GM_FIGURE_PLAN.md`;
- claim/evidence ledger: `GM_CLAIM_EVIDENCE_LEDGER.md`;
- reviewer risks: `GM_REVIEWER_RISKS.md`;
- appendix/supplement plan: `GM_SUPPLEMENT_STRUCTURE.md`;
- complete manuscript: `manuscript/tcns_information_limits.tex`;
- generated figures and source: `manuscript/figures/` and
  `manuscript/make_gm_figures.m`.

## 6. Internal-review decision

`MANUSCRIPT_READY_FOR_INTERNAL_REVIEW` means the requested GM theorem,
mapping, narrative, manuscript, ledger, and figures are complete and
reproducible.  It does not mean ready to submit.  The leading internal-review
question is whether TCNS considers the action-value specialization and
formation/economic closure sufficiently nontrivial beyond established
functional observability.  That risk is disclosed rather than hidden.

