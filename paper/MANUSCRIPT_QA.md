# Manuscript QA

Publication-grade quality checks on `paper/main.tex` and its nine sections.

---

## 1. Compilation — BLOCKED, with the exact blocker

| | |
|---|---|
| **Compiled** | **NO** |
| **Reason** | No TeX distribution is installed in this environment |
| **Probed** | `pdflatex`, `xelatex`, `lualatex`, `latexmk`, `tectonic`, `bibtex`, `biber` — **all absent from `PATH`**; no TeX Live or MiKTeX installation directory present |
| **Why not resolved here** | Installing a TeX distribution is a new environment dependency, which this work was scoped not to add. The manuscript source is complete and self-consistent; only the build step is unavailable |
| **Owner action to unblock** | Install TeX Live (or MiKTeX), then from `paper/`: `pdflatex main && bibtex main && pdflatex main && pdflatex main` |

Because the document cannot be compiled here, everything below is a
**static** check performed directly on the source. Static checks catch
undefined references, duplicate labels, unbalanced environments, missing
artefacts and unresolved citekeys — they cannot catch overfull boxes, float
placement, or the true page count.

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
| Missing figure files | **0** — 11 referenced, 11 present as `.pdf` (and `.png`) |
| Missing table files | **0** — 6 referenced, 6 present |
| Unresolved citekeys | **0** — 48 keys used, 48 defined in `references.bib` |
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
| Figures | 11 (2 schematic, 9 data) |
| Tables | 6 (3 full-width `table*`) |
| References | 48 |
| Algorithms | 2 |
| Numbered equations | 12 |
| Abstract | 205 words (target 180–230) |

**Estimated total page count: 17–19 pages** once figures and tables are
placed. This is a real constraint, not a formality:

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

## 5. Figure inspection — manual, all 11 reviewed

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

**Minor cosmetic notes (not defects):** in Figure 11 the inline statistics
box slightly overlaps the confidence band in the first two panels; in
Figure 3 the dotted chain line passes near the P10 marker, which a reader
could momentarily read as membership of the chain. Both are legible and
neither changes an interpretation. Fix if a venue requests it.

## 6. Overfull boxes and float placement

**Cannot be assessed without compiling.** Two locations are flagged as
likely to need attention on first build, both because of long unbroken
content rather than prose:

1. **Table V and Table VI** use fixed-width `p{}` columns holding long
   sentences; column widths were chosen for a full-width `table*` at
   letter paper and will need adjustment under a venue template.
2. **Algorithm 1** has several long `\State` lines with inline mathematics
   that may overrun a single column; the algorithm is likely to need
   `\algorithmicindent` tuning or line splitting.

Neither is a content problem. Both must be re-checked on the first
successful build, and the outcome recorded here.

## 7. What remains open

| Item | Status |
|---|---|
| Compile the document | **BLOCKED** — no TeX distribution (§1) |
| True page count | Unknown until compiled; estimated 17–19 |
| Overfull/underfull box log | Unavailable until compiled |
| Float placement review | Unavailable until compiled |
| Venue template conversion | Deliberately not started — see `VENUE_SHORTLIST.md` |
| Author list, affiliations, funding, ORCIDs | Withheld in this draft |

## 8. Verdict

**Static QA: PASS.** Zero undefined references, zero duplicate labels, zero
missing artefacts, zero unresolved citekeys, zero placeholders, zero
hard-coded result numbers, all acronyms expanded before first use, and both
rate normalisations labelled wherever they are used.

**Compilation QA: BLOCKED**, for the single stated reason that no TeX
distribution exists in this environment. That blocker is environmental, not
a defect in the manuscript, and it is recorded rather than worked around.
