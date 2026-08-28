# IEEE TCNS submission requirements

Verified on **2026-08-28** from current IEEE Control Systems Society (CSS)
and IEEE Author Center sources. Publication-specific TCNS instructions govern
where they are narrower than generic IEEE guidance.

## Authoritative sources

1. [TCNS Information for Authors (IEEE CSS)](https://ieeecss.org/publication/transactions-control-network-systems/information-authors)
2. [TCNS journal page and scope (IEEE CSS)](https://ieeecss.org/publication/transactions-control-network-systems)
3. [IEEE journal article structure](https://journals.ieeeauthorcenter.ieee.org/create-your-ieee-journal-article/create-the-text-of-your-article/structure-your-article/)
4. [IEEE graphics guidance](https://journals.ieeeauthorcenter.ieee.org/create-your-ieee-journal-article/create-graphics-for-your-article/)
5. [IEEE graphics resolution and size](https://journals.ieeeauthorcenter.ieee.org/create-your-ieee-journal-article/create-graphics-for-your-article/resolution-and-size/)
6. [IEEE graphics file formatting](https://journals.ieeeauthorcenter.ieee.org/create-your-ieee-journal-article/create-graphics-for-your-article/file-formatting/)
7. [TCNS final accepted manuscript instructions and page-charge form](https://docs.google.com/document/d/1Uvi2GTaOYT3xzqCgt3hz3d4Ye_Zp2-5yi_5G2aM_fjE/edit?usp=sharing)

## Locked interpretation for this manuscript

| Requirement | Verified rule | Consequence here |
|---|---|---|
| Manuscript type | TCNS is an IEEE Transactions journal accepting full-length articles/papers in its networked-control scope. The TCNS instructions do not define a shorter letter category for this submission. | Treat this work as a regular full-length Transactions article. |
| Submission class | IEEE Transactions 10-point, double-column format. TCNS gives the exact LaTeX declaration `\documentclass[10pt,twocolumn,twoside]{IEEEtran}`. The Alternate Transactions Articles template is encouraged, while the standard Transactions template remains accepted with no page-length difference. | Compile with `IEEEtran` in the exact TCNS options. |
| Initial page policy | Maximum **12 pages** in the required double-column format. TCNS further describes this as main paper up to 10 pages plus an appendix up to 2 pages, all in one PDF. Papers over 12 pages are not considered. | The target is 12 total PDF pages, not an inherited estimate. |
| What counts | The 12-page count includes all figures, tables, references, and author biographies. | References and every visible artifact count. |
| Overlength | Final accepted manuscripts remain capped at 12 pages. Pages above 10 incur mandatory overlength charges. The current TCNS page-charge form states **US$125 per overlength page**; its voluntary charge is separate. | Pages 11--12 are allowed but chargeable if accepted; page 13 is not an option. |
| Supplementary materials | TCNS-specific submission instructions identify only two manuscript supplement cases: the final conference version for an expanded conference paper, or the complementary part of a two-part paper. Generic IEEE systems can upload multimedia/data supplements, but the narrower TCNS rule does **not** authorize moving this paper's scientific evidence to a separate length-avoidance supplement. | Do not create a scientific evidence supplement for this batch. Keep the main article self-contained. |
| Review anonymity | **Single-anonymous**: reviewers are unknown to authors, but reviewers know author identities. The first page is to contain authors and affiliations. | Do not anonymize the manuscript. Because real metadata was not provided, use conspicuous placeholders and flag replacement as manual; do not invent identities. |
| ORCID | TCNS requires ORCID for all authors in the submission system. | Manual submission item only; no ORCID is fabricated in the manuscript. |
| Author biographies | TCNS final-file instructions require biographies and corresponding author photographs in the IEEE Transactions source. The 12-page limit explicitly counts biographies. | No biography or photo is invented. Final accepted page budgeting must be rechecked after the real author list is known. |
| Abstract | TCNS permits up to 300 words; generic IEEE guidance recommends a single self-contained paragraph up to 250 words, without references, footnotes, abbreviations requiring external definition, or equations. | Use the stricter 250-word target. |
| Index terms | IEEE journal structure calls for 3--5 discoverability keywords/phrases, with abbreviations defined. | Add `IEEEkeywords` with 3--5 relevant terms. |
| Figures and color | IEEE prefers vector graphics (PDF/EPS/PS); raster color/grayscale should exceed 300 dpi and monochrome line art 600 dpi. Normal widths are 3.5 in (one column) and 7.16 in (two columns); figure text should appear about 9--10 point at final size. Graphics must remain interpretable in grayscale and should use line style/marker shape as well as color. | Retain vector PDFs, check labels at 100%, and verify grayscale-independent encodings visually. |
| Bibliography | Numbered square-bracket citations and IEEE reference style; TCNS specifies `\bibliographystyle{IEEEtran}`. | Replace `unsrt` with `IEEEtran`. |
| First-page metadata | TCNS requests title without symbols, authors/affiliations, abstract, contact details, correspondence address, and support footnotes where applicable. | Title and abstract are real; author/contact/funding fields remain explicit placeholders pending owner-supplied metadata. |

## Apparent generic/specific differences

Two generic IEEE pages are broader than the TCNS-specific instructions:

- generic IEEE abstract guidance says up to 250 words, while TCNS says up to
  300; this manuscript follows 250 and therefore satisfies both;
- generic IEEE infrastructure supports separate supplementary files, while
  TCNS lists only the conference-version and complementary-two-part cases;
  the publication-specific restriction controls, so no evidence supplement
  is used.

These are resolved by following the narrower rule and do not create an
operational conflict requiring a stop.

## Page-budget rule for this branch

1. First compile all accepted scientific content unchanged in the actual
   `IEEEtran` layout.
2. Record that uncut TCNS-layout page count.
3. Only if it exceeds 12 pages, remove redundancy or compress presentation
   while retaining all 15 protected scientific points in the main PDF.
4. Stop rather than delete protected evidence if 12 pages cannot be reached.

## Semantic-audit candidate compliance

The current main manuscript is nine pages before verified author metadata is
inserted. The submission target is to remain at or below the TCNS 10-page main
paper limit after the real page-1 metadata is supplied. No numeric metadata
headroom is estimated, and no appendix is added merely because the separate
two-page appendix allowance exists.

| Submission check | Candidate status |
|---|---|
| Abstract | 192 source words when each generated metric macro is counted as one token; below the official 300-word maximum. |
| Document class | Exact `IEEEtran` 10-point, two-column, two-sided declaration. |
| Paper size | Compiled media box is 612×792 points, i.e. US Letter 8.5×11 inches. |
| Bibliography | `\bibliographystyle{IEEEtran}`; 53 publisher-verified references. |
| Self-citations | **BLOCKED_BY_AUTHOR_METADATA.** With author identities still placeholders, the overlap between manuscript authors and cited authors cannot be determined. Recheck against the TCNS maximum of five after names are supplied. |
| Page-1 identity/contact fields | **BLOCKED_BY_AUTHOR_METADATA.** The conspicuous author/affiliation placeholder must be replaced with verified identities, affiliations, mailing addresses, phone numbers, email addresses, and correspondence details. |
| ORCID | **BLOCKED_BY_AUTHOR_METADATA.** ORCIDs are required in the submission system for every author; none is invented here. |
| Funding/support | Unknown and intentionally not populated. Supply or explicitly confirm absence before submission. |
| Appendix / supplement | None. All evidence supporting the main claims remains in the main PDF. |
