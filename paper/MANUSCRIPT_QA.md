# Manuscript QA

Publication-grade quality checks on `paper/main.tex` and its nine sections.

---

## 1. Compilation — PASS in isolated CI

| | |
|---|---|
| **Compiled** | **YES** — GitHub Actions run `33141338862` |
| **Environment** | `pdflatex` via `latexmk`, isolated TeX Live 2025 Debian container |
| **Local environment** | Unchanged; no TeX distribution or other dependency was installed locally |
| **Artifact** | `paper/main.pdf`, uploaded with `main.log`, BibTeX outputs and `generated/ci_latex_report.txt` |
| **Result** | **PASS** — 0 undefined citations, 0 undefined references, 0 duplicate labels, 0 missing figures/tables |

The repository now contains a paper-only workflow at
`.github/workflows/paper-latex.yml`. It checks the frozen scientific boundary,
compiles only `paper/main.tex`, rejects unresolved citations/references,
duplicate labels and missing artifacts, and uploads the PDF plus QA evidence.

### Dependencies the build needs

All are in a standard full TeX Live / MiKTeX installation; none is exotic:
`geometry`, `amsmath`, `amssymb`, `graphicx`, `booktabs`, `multirow`,
`algorithm`, `algpseudocode`, `xcolor`, `hyperref`, `caption`.

The bibliography style is **`unsrt`**, which ships with every BibTeX
installation, chosen deliberately so the document builds with no added
dependency. Substitute `IEEEtran.bst` when targeting an IEEE venue — see
`VENUE_SHORTLIST.md`.

## 2. Static structural checks — all PASS

| Check | Result |
|---|---|
| Undefined `\ref` / `\eqref` targets | **0** (39 distinct references, 52 labels) |
| Duplicate labels | **0** |
| Unbalanced environments (`figure`, `table`, `tabular`, `algorithm`, `algorithmic`, `itemize`, `enumerate`, `center`, `abstract`, `document`, and starred variants) | **0** |
| Missing figure files | **0** — 13 referenced, 13 present as `.pdf` (and `.png`) |
| Missing table files | **0** — 8 referenced, 8 present |
| Unresolved citekeys | **0** — all 53 bibliography entries compile through BibTeX |
| Placeholder markers (`TODO`, `FIXME`, `XXX`, `PLACEHOLDER`, `??`, empty `\cite{}`, `RELATED_WORK_NEEDS`) | **0** |
| Hard-coded numeric results in prose | **0** — every headline number is a generated macro |
| Undefined metric macros | **0** — 65 used, all defined in `generated/metrics.tex` |
| Macro names LaTeX-legal (letters only) | **125 / 125** |

**13 unused labels** exist (section and equation anchors that are not
cross-referenced). These are harmless — an unused `\label` produces no
warning and no output — and are kept because several are referenced from
the companion documents.

## 3. Length and composition

| Item | Value |
|---|---|
| Body words (excluding LaTeX markup, comments, tables, captions) | **≈ 9,440** |
| Estimated text-only extent, two-column IEEE at ~900 words/page | **≈ 10.5 pages** |
| Actual compiled extent | **23 pages** in the current letter-paper, two-column article layout |
| Figures | 13 (2 schematic, 11 data) |
| Tables | 8 |
| References | 53 |
| Algorithms | 2 |
| Numbered equations | 12 |
| Abstract | 205 words (target 180–230) |

The actual 23-page count supersedes the earlier 17–19 page estimate. It is
not yet a TCNS-template count, but it confirms that substantial compression
would be needed for a 12-page target. Ranked, protected reduction options are
recorded in `LENGTH_REDUCTION_PLAN.md`; no major cut has been made.

| Venue | Limit | Verdict |
|---|---|---|
| TCNS | 12 pages | **Over — substantial cut required** |
| TCST | 16 pages (Paper) | Marginally over; achievable with modest trimming |
| TAES | no formal limit, \$200/page beyond 10 | Fits, at a page charge |
| RA-L | 6 pages (+2 at charge) | **Far over — would require restructuring, not trimming** |
| IEEE Access | not binding | Fits |

Reduction candidates, in the order they should be cut, chosen so that no
negative result is lost: fold the design-evolution prose into
Table~II; compress the statistical-conventions subsection to one paragraph;
move §7.7–§7.11 mechanism discussions to supplementary material; merge
Figures 9 and 10. **Table VI and the ACK-inclusive reversal are not
reduction candidates.**

## 4. Notation and consistency audit

| Check | Result | Notes |
|---|---|---|
| Acronym defined before first use | **PASS** | Verified mechanically for AoI, UAV, ACK, RMSE, DOF, RTT, ARQ. Four required correction during this pass: ACK, 6-DOF, RTT and ARQ were used bare before expansion and are now expanded at first use |
| AoI notation consistent | **PASS** | $A_{ij}(t)$ is always the true, omniscient-observer age; $\hat{A}(t)$ is always the sender's ACK-derived estimate. The distinction is defined once (§3.4) and never blurred |
| DATA / ACK capitalisation | **PASS** | `DATA` and `ACK` are set as all-caps protocol payload classes throughout; the word "acknowledgement" is lower-case prose |
| Per-channel vs swarm-total traffic labelled | **PASS** | §5.6 defines both; the caption of every rate-bearing table states which one it uses; audit rule A11 checks both labels are present |
| Units on quantities in text | **PASS** | m, m/s, m/s², Hz, s, B consistently; `~` used before all units to prevent line breaks |
| Mathematical variables defined | **PASS** | All of $N$, $A$, $\pi$, $n_c$, $\pos_i$, $\vel_i$, $\delta_i$, $d_{\min}$, $g_{ij}$, $A_{ij}$, $\hat{A}$, $\bar{A}$, $\rho$, $s_0$, $s_{\min}$, $s(t)$, $u(t)$, $\epsilon_p$, $\epsilon_v$, $\tau_{\min}$, $\tau_r$, $\tau_{\max}$, $\mathcal{O}$, $k^{\mathrm{sent}}$, $C_w$, $C_{\mathrm{air}}$, $C_{\mathrm{bcast}}$, $\bar d$, $\sigma_d$ are introduced where first used |
| SI unit style | **PASS** | Plain units rather than `siunitx`, to avoid an added dependency; spacing and capitalisation are uniform |

## 5. Figure inspection — manual, all 13 reviewed

No mechanical check can confirm that a figure shows what its caption says,
so each was viewed.

| Figure | Axes / units labelled | Legible at column width | Carries its caption's claim |
|---|---|---|---|
| 1 architecture | n/a (schematic) | yes | yes — ACK path drawn in a distinct colour, labelled as the only channel for receiver knowledge |
| 2 protocol timeline | time axis, unitless by design | yes | yes — shows delivery, cumulative ACK, a loss, refresh blocked, backstop firing |
| 3 design evolution | Hz and m, both labelled | yes | yes — the chain trajectory and the oracle's position are both visible |
| 4 adaptive rate | Hz, labelled; scenario categories | yes | yes — periodic flat, ours rising, and the ACK-inclusive panel beside it |
| 5 cost/Pareto | Hz and m | yes | yes — hollow vs filled markers and the arrow make the reversal explicit; baselines correctly show no arrow |
| 6 ACK impairment | Hz (left), unitless scale (right) | yes | yes — Moderate shows the mechanism working, Stressed shows it pinned at the floor |
| 7 topology | in-degree, m | yes | yes — ordering stable, level not |
| 8 fault response | Hz, s | yes | yes — before/during/after windows and recovery |
| 9 DI vs 6-DOF | m on both axes, identity line | yes | yes — all methods above the line, ordering preserved |
| 10 mismatch/estimator | m, Hz, with the ×2 bound drawn | yes | yes — bound breach visible |
| 11 paired holdout | paired difference in m and Hz | yes | yes — K1 and K2a below zero, K2b above; the sign reversal is unmistakable |
| 12 EXP11 adaptivity | swarm-total Hz and mission regimes | yes | yes — all transitions and the no-regime-label comparison are visible |
| 13 EXP11 frontier | RMSE and normalized $C_{0.25}$ | yes | yes — P12.5 remains visibly competitive and is labelled |

**Minor cosmetic notes (not defects):** in Figure 11 the inline statistics
box slightly overlaps the confidence band in the first two panels; in
Figure 3 the dotted chain line passes near the P10 marker, which a reader
could momentarily read as membership of the chain. Both are legible and
neither changes an interpretation. Fix if a venue requests it.

## 6. Overfull boxes and float placement

Final isolated compile and 23-page visual inspection:

| Check | Result |
|---|---|
| Overfull `\hbox` / `\vbox` | **0 / 0** |
| Underfull `\hbox` / `\vbox` | **60 / 5** |
| LaTeX float-placement warnings | **0** |
| Visual overlap, clipping, or displaced floats | **0** after correcting the widths of Tables I–V and moving the paired-claim table to full width |
| Font warnings | One benign Computer Modern bold-small-caps substitution; no missing glyphs |

The underfull warnings are concentrated in narrow table cells, algorithms,
two-column prose and bibliography entries. All pages were rendered and
inspected; they produce visible loose spacing in a few cells/lines but no
lost, obscured, or ambiguous content.

## 7. What remains open

| Item | Status |
|---|---|
| Compile the document | **PASS** in isolated CI (§1) |
| True page count | **23** in the current layout |
| Overfull/underfull box log | **0 / 65** total warnings, detailed in §6 |
| Float placement review | **PASS**, 23/23 pages visually inspected |
| Venue template conversion | Deliberately not started — see `VENUE_SHORTLIST.md` |
| Author list, affiliations, funding, ORCIDs | Withheld in this draft |

## 8. Verdict

**Static QA: PASS.** Zero undefined references, zero duplicate labels, zero
missing artefacts, zero unresolved citekeys, zero placeholders, zero
hard-coded result numbers, all acronyms expanded before first use, and both
rate normalisations labelled wherever they are used.

**Compilation QA: PASS.** The isolated CI build produced a 23-page PDF with
no unresolved cross-reference/citation, duplicate label, missing artifact,
overfull box, or float-placement defect. The remaining 65 underfull warnings
are recorded rather than hidden.

## 9. Post-EXP11 QA (2026-08-28)

The supplemental artifacts were rebuilt from
`results/exp11_dynamic_network/2026-08-27_174026/tidy.csv` without running
MATLAB or the simulator. Static audit results:

| Check | Result |
|---|---|
| Figures / tables / references | **13 / 8 / 53** |
| Undefined citations | **0** |
| Undefined references | **0** |
| Duplicate labels | **0** |
| Missing figures/tables | **0** |
| Scientific-source modifications | **0** |
| Numeric contradictions | **0** |
| Unsupported promoted claims | **0** |
| EXP11 source hash | **PASS**, recorded in `generated/exp11_verification.json` |
| Base generated metrics | **PASS** — 279 pre-EXP11 headline rows and the base macro block are unchanged from `paper-v1`; every recorded source directory contains its frozen `tidy.csv` |
| Local and remote release anchors | **PASS** for both frozen tags |
| EXP11 Figure 12/13 visual inspection | **PASS** — axes, units, method labels and P12.5 counterexample are legible |

No local compiler was installed. The paper-only isolated CI path supplies
the missing compiler without modifying the research environment, and its
PDF/log were used to close the page-count, box-warning and float-placement
checks above.
