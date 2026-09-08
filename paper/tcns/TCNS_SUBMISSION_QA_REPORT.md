# TCNS submission QA report

**Audit date:** 2026-09-08  
**Scientific baseline:** `tcns_internal_science_pass` ->
`7c679610af2098acc2aa5e8f005e81a898435f29`  
**Audited submission-package commit:**
`5340d0b34f2f828a9903e91d8ab669ec3070db81`  
**Submission action:** not performed.

## Binary recommendation

`READY_TO_SUBMIT`

The scientific, novelty, theorem, reference, figure, reproducibility, and PDF
QA gates pass. The only remaining input is verified human author metadata. The
current PDF visibly contains placeholders and must not be uploaded as-is.
After the Research Lead supplies the fields listed in
`submission/AUTHOR_METADATA_CHECKLIST.md`, replace only
`manuscript/submission_metadata.tex`, rebuild the PDF, and repeat the first-page
and page-count checks. No scientific revision is required or authorized.

## Gate results

| Gate | Result | Evidence |
|---|---|---|
| SQ0 scientific freeze | Pass | Annotated tag `tcns_internal_science_pass` resolves to the accepted R1 commit and is pushed to `origin`. Later edits are confined to manuscript scope, references, figures, formatting, reproducibility, and submission metadata scaffolding. |
| SQ1 hostile review | Pass after response | Three independent hostile reviews returned raw `MAJOR` verdicts from functional-observability, networked-control/VoI, and multi-agent/UAV perspectives. All scientifically valid objections were accepted and addressed. No theorem defect or unaddressed major criticism remains. See `SQ_HOSTILE_REVIEW.md`. |
| SQ2 theorem audit | Pass | Fixed-response affine expansion, static/history row-space conditions, closed-interval minimax radius, strict-straddle randomized/deterministic regret including edge cases, multi-action linear-statistic lower bound/construction, and coalition specialization were rederived. See `SQ_THEOREM_AUDIT.md`. |
| SQ3 novelty audit | Pass | `NO_DIRECT_COLLISION_FOUND`. The search covered the 2025--2026 functional-observability literature, VoI/action-value work, and 2026 goal-oriented communication. This is an audit result, not proof of priority. See `SQ_NOVELTY_AUDIT.md`. |
| SQ4 format | Pass | Official TCNS guidance checked. The source uses 10-point IEEEtran double-column format. The PDF is 11 letter-size pages; the main text ends and appendices start on page 10. Abstract is 289 words. See `SQ_FORMAT_COMPLIANCE.md`. |
| SQ5 author metadata | Human input isolated | Names, affiliations, addresses, phones, emails, ORCIDs, corresponding author, and funding were not present in the repository and were not invented. Explicit placeholders and a blocking checklist are supplied. |
| SQ6 references | Pass | All 33 cited entries resolve to archival DOI/publisher records; metadata and neighboring claim support were audited. One ACC pagination error was corrected. See `SQ_REFERENCE_AUDIT.md`. |
| SQ7 figures | Pass | Six figures were regenerated from frozen data, the complete 11-page PDF was rendered and inspected, and every font is embedded. Visual QA caught and removed one literal `qquad` source defect before the final build. See `SQ_FIGURE_AUDIT.md`. |
| SQ8 claim scrub | Pass | Terms including *first*, *novel*, *optimal*, *fundamental*, *impossible*, *always*, *guarantee*, *universally*, *free*, and *minimum information* were checked against theorem scope. See `SQ_CLAIM_SCRUB.md`. |
| SQ9 reproducibility | Pass | A public-facing command map separates essential paper reproduction from historical research artifacts. See `manuscript/REPRODUCIBILITY.md`. |
| SQ10 package | Pass subject to metadata | Source, bibliography, six vector figures, PDF, cover-letter draft, keywords, expertise areas, conflict checklist, and reproduction statement are prepared under `manuscript/` and `submission/`. No graphical abstract was added. |

## Verification executed

The authorized frozen regression/theorem suite returned:

- `test_lock_regression: PASS`;
- `test_tcns_information_limits: PASS`, including affine residual
  `4.323e-16` and two opposite-sign reachable witnesses;
- `test_tcns_r1_theory_depth: PASS`, including `10/10` tolerance-stable link
  tests.

The final TeX build returned exit code zero. Log and PDF audit found:

- 0 LaTeX errors;
- 0 undefined citations or references;
- 0 overfull boxes;
- 25 underfull boxes, all visually inspected and harmless;
- 11 pages at 612 x 792 pt;
- all listed fonts embedded;
- no cropped or overlapping figure, table, equation, or caption.

## Exact submission artifact

Intended PDF path:

`paper/tcns/manuscript/tcns_information_limits.pdf`

SHA-256:

`3E8D5AC5705DF798002322B37F0C8B758AF1094667D5905B237F134605B21F72`

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
3. The all-five coalition and all-ten structural audit are conditional on the
   evaluated N=5 graph, global output, horizon, gains, information maps, and
   unit-response construction.
4. Empirical frontiers use development data as counterexample/mechanism
   evidence, not population superiority evidence.
5. Packet-frequency economics do not price bytes, airtime, collisions, energy,
   or an implemented global-statistic acquisition protocol.
6. A terminology-adjacent, unarchived 2026 public working manuscript was found;
   no direct theorem collision was located, and the audit records it rather
   than making a priority claim.

## Human release checklist

Before portal upload only:

1. complete verified author/contact/ORCID/funding metadata;
2. verify author order, approvals, originality, overlap, and genuine conflicts;
3. insert the public repository URL and archival DOI in the cover letter;
4. rebuild the same source and confirm first-page layout and page count;
5. upload the resulting single PDF through the TCNS portal.

This report prepares the package but does not authorize or perform submission.
