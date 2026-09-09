# TCNS submission QA report

**Audit date:** 2026-09-09

**Frozen manuscript baseline:** `7376fb097ca6c25fe0758dcb4c89f69c66a66003`

**Approved R2.6 refinement:** `d0edd2c810c39a1795ceca0e3139e4ff81ea1cae`

**Approved R2.7 result:** `105183e255df2849dbc6d00f35f312ce5d4d5f7a`

**Audited integration:** local coauthor-review commit reported at handoff; not pushed
**Submission action:** not performed.

## Binary recommendation

`READY_FOR_FINAL_COAUTHOR_REVIEW`

The R2.7 manuscript integration, frozen-evidence regression, reproducibility,
and PDF QA gates pass. The current PDF visibly contains author placeholders
and must not be uploaded as-is.
After the Research Lead supplies the fields listed in
`submission/AUTHOR_METADATA_CHECKLIST.md`, replace only
`manuscript/submission_metadata.tex`, rebuild the PDF, and repeat the first-page
and page-count checks. No scientific revision is required or authorized.

## Gate results

| Gate | Result | Evidence |
|---|---|---|
| SQ0 scientific freeze | Pass | Annotated tag `tcns_internal_science_pass` resolves to the accepted R1 commit and is pushed to `origin`. Later edits are confined to manuscript scope, references, figures, formatting, reproducibility, and submission metadata scaffolding. |
| SQ1 hostile review | Pass after R2.7 closure | The absolute-value/relative-value/decision distinction is retained, and the common-maximizer theorem is instantiated directly on common physical fibers with all candidate responses preserved jointly. See `GM_REVIEWER_RISKS.md`, `R2_6_DECISION_IDENTIFIABILITY_NOTE.md`, and `R2_7_COMMON_FIBER_REPORT.md`. |
| SQ2 theorem audit | Pass | Fixed-response affine expansion; absolute and relative row-space conditions; set-valued fiberwise argmax; Euclidean margins; binary minimax regret; absolute/relative statistic dimensions; common-offset rank gap; augmented no-transmission corollary; and coalition specialization were checked. |
| SQ3 novelty audit | Pass | `NO_DIRECT_COLLISION_FOUND`. The search covered the 2025--2026 functional-observability literature, VoI/action-value work, and 2026 goal-oriented communication. This is an audit result, not proof of priority. See `SQ_NOVELTY_AUDIT.md`. |
| SQ4 format | Pass | The source uses 10-point IEEEtran double-column format. The PDF is 12 letter-size pages; all main text ends on page 10 and appendices start on page 11. Abstract is 276 words. |
| SQ5 author metadata | Human input isolated | Names, affiliations, addresses, phones, emails, ORCIDs, corresponding author, and funding were not present in the repository and were not invented. Explicit placeholders and a blocking checklist are supplied. |
| SQ6 references | Pass | All 33 cited entries resolve to archival DOI/publisher records; metadata and neighboring claim support were audited. One ACC pagination error was corrected. See `SQ_REFERENCE_AUDIT.md`. |
| SQ7 figures/PDF | Pass | No figure data were regenerated. The complete 12-page PDF was rendered at 120 dpi and every page was visually inspected; no crop, overlap, malformed heading, or unreadable equation was found. Every PDF font is embedded. |
| SQ8 claim scrub | Pass | The manuscript distinguishes exact unit-response row-space nonidentifiability from structural functional observability, and never calls the relative rank the minimum information for argmax. |
| SQ9 reproducibility | Pass | The public-facing command map includes R2.7 protocol/result provenance and its frozen artifact without introducing a new simulation workflow. See `manuscript/REPRODUCIBILITY.md`. |
| SQ10 package | Pass subject to metadata | Source, bibliography, six vector figures, PDF, cover-letter draft, keywords, expertise areas, conflict checklist, and reproduction statement are prepared under `manuscript/` and `submission/`. No graphical abstract was added. |

## Verification executed

The authorized frozen regression/theorem suite returned nine passes:

- `test_lock_regression: PASS`;
- `test_tcns_information_limits: PASS`, including affine residual
  `4.323e-16` and two opposite-sign reachable witnesses;
- `test_tcns_r1_theory_depth: PASS`, including `10/10` tolerance-stable link
  tests;
- `test_tcns_r2_generalization: PASS`;
- `test_tcns_actual_witness_audit: PASS`;
- `test_tcns_r2_5_persisted_witness_replay: PASS`;
- `test_tcns_r2_5_adversarial_artifact: PASS`;
- `test_tcns_r2_6_decision_identifiability: PASS` (`6/6` base synthetic and
  `4/4` rank-gap refinement cases);
- `test_tcns_r2_7_common_fiber: PASS` (`30/30` deterministic attempts, all
  three corruption controls rejected, and the nested R2.6 suite passed).

The final TeX build returned exit code zero. Log and PDF audit found:

- 0 LaTeX errors;
- 0 undefined citations or references;
- 0 overfull boxes;
- 36 underfull hboxes and 1 underfull vbox, visually harmless;
- 12 pages at 612 x 792 pt, with all main text ending on page 10;
- no cropped or overlapping figure, table, equation, or caption.

## Exact submission artifact

Intended PDF path:

`paper/tcns/manuscript/tcns_information_limits.pdf`

SHA-256:

`E97425139007484FBBE22297B78CBED995FCB527FE0FA19F0284FD6A34AF2F4E`

The matching source is
`paper/tcns/manuscript/tcns_information_limits.tex`; author metadata is isolated
in `paper/tcns/manuscript/submission_metadata.tex`; the compile log is
`paper/tcns/manuscript/tcns_information_limits_compile.log`.

## Residual reviewer risks

These are disclosed, scoped, and not QA blockers:

1. An editor may judge the synthesis incremental relative to established
   functional observability even though the manuscript explicitly concedes the
   classical row-space/history/sensor-selection components.
2. The theorem concerns conditional fixed-response affine value in a sampled
   linear model; it is not a general Bellman-VoI, Bayesian-policy, nonlinear
   UAV, or arbitrary-code result.
3. The all-five coalition and all-ten unit-response audit are conditional on the
   evaluated N=5 graph, global output, horizon, gains, information maps, and
   unit-response construction.
4. Empirical frontiers use development data as counterexample/mechanism
   evidence, not population superiority evidence.
5. Packet-frequency economics do not price bytes, airtime, collisions, energy,
   or an implemented global-statistic acquisition protocol.
6. A terminology-adjacent, unarchived 2026 public working manuscript was found;
   no direct theorem collision was located, and the audit records it rather
   than making a priority claim.
7. The common-fiber audit covers ten deliberately persisted N=5 centers and
   three multi-action senders. Its 24 disjoint-argmax cases establish
   implementation-closed existence witnesses, not prevalence, a random-state
   estimate, a registry-wide argmax result, or arbitrary-topology generality.

## Human release checklist

Before portal upload only:

1. complete verified author/contact/ORCID/funding metadata;
2. verify author order, approvals, originality, overlap, and genuine conflicts;
3. insert the public repository URL and archival DOI in the cover letter;
4. rebuild the same source and confirm first-page layout and page count;
5. upload the resulting single PDF through the TCNS portal.

This report prepares the package but does not authorize or perform submission.
