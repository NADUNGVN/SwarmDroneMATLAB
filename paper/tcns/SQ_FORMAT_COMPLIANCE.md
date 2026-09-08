# SQ TCNS format-compliance audit

**Audit date:** 2026-09-08  
**Official source:** [TCNS Information for Authors](https://ieeecss.org/publication/transactions-control-network-systems/information-authors)

| Requirement | Result | Evidence / action |
|---|---|---|
| IEEE Transactions 10-point, double-column | Pass | Source uses exactly \(\backslash\)documentclass[10pt,twocolumn,twoside]{IEEEtran}. |
| Maximum 12 pages, main up to 10 plus appendix up to 2 | Pass | Compiled PDF is 11 letter-size pages. Conclusion and appendix begin on page 10; appendix occupies pages 10–11. |
| One submission PDF | Pass | Package identifies one intended manuscript PDF. |
| Alternate Transactions template | Reviewed; no conversion | Current TCNS guidance encourages the Alternate template but explicitly says standard Transactions submissions continue to be accepted with no page-length difference. The source uses the exact class line separately required by the same page. No aesthetic-only conversion was made. |
| First-page author/contact metadata | Human input only | Repository contains no verified author names, affiliations, addresses, phones, emails, ORCIDs, corresponding author, or funding statement. Explicit fields are isolated in submission_metadata.tex; nothing was invented. |
| Title without problematic symbols | Pass | Plain-text title; no math or unsupported symbol. |
| Abstract at most 300 words | Pass | 289 words after TeX markup removal. |
| IEEE keywords | Pass | Seven terms supplied in the IEEEkeywords environment. |
| Numbered IEEE-style references | Pass | IEEEtran bibliography style; 33 cited archival entries. |
| Appendix placement | Pass | Appendices follow Conclusion and precede References within the single PDF. |
| Figure readability | Pass | All 11 pages rendered at 150 dpi and inspected at final page scale; figures were also checked at their printed single-/double-column size. |
| Grayscale distinction | Pass | Frontier families use both different line colors and circle/square markers; witness traces use solid/dashed lines; sign bars are labeled. |
| Embedded fonts | Pass | Poppler pdffonts reports embedded=yes for every manuscript and MATLAB-figure font. |
| Cropping / rasterized tiny text | Pass | Visual inspection found no clipping/overlap; principal figures are embedded PDF vector graphics. |
| Undefined references/citations | Pass | Final compile log contains none; BibTeX completed normally. |
| Overfull boxes | Pass | Final compile log contains none. Underfull spacing warnings were reviewed visually and caused no defect. |
| ORCID | Human input only | TCNS requires ORCID for every author; checklist blocks portal upload until completed. |

The official page has internally awkward wording that both encourages the
Alternate template and says standard Transactions submissions remain
accepted. The audit follows the explicit class command and acceptance sentence
rather than performing a risky template conversion without a scientific or
page-limit need.
