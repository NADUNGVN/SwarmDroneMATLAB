# TCNS manuscript QA

## Compiled layout

The accepted scientific-content baseline was 23 pages before TCNS conversion.
With content unchanged, the required `IEEEtran` TCNS layout compiled to 20
pages (CI run 33152637160). Controlled reduction then produced a 9-page main
manuscript. The semantic audit restored logical bridges and scope
qualifications without increasing the page count; all figures, tables, and 53
references remain included.

| Check | Final result |
|---|---:|
| Undefined citations | 0 |
| Undefined references | 0 |
| Duplicate labels | 0 |
| Missing figures/tables | 0 |
| Overfull hbox / vbox | 0 / 0 |
| Underfull hbox / vbox | 5 / 3 |
| Float-placement problems | 0 |
| Figures / tables / references | 3 / 6 / 53 |
| Text words (`texcount`) | 3,387 |
| Headers / caption words | 101 / 218 |
| Abstract source words | 192 |

The five underfull hboxes occur in the long safety equation paragraph, one
narrow Table I text cell, and the H2b paragraph. The three underfull vboxes are
page-building warnings around the wide Table VI and Figs. 1--2. Rendering
shows no clipping, overlap, or readability defect; these warnings are cosmetic.

## Compilation environment

GitHub Actions compiles only `paper/main.tex` in isolated TeX Live 2025 using
`latexmk`/`pdflatex`, stages `paper/output/manuscript_tcns.pdf`, and uploads the
PDF, log, BibTeX products, word count, QA report, PDF metadata, and a 144-dpi
render of every page. The workflow does not run MATLAB and rejects changes
under the frozen scientific-source directories. Poppler rendering occurs only
inside the disposable CI runner; nothing was installed in the local research
environment.

## Visual QA

All nine PDF pages from CI run 33157597435 were rendered to PNG and inspected.
The three two-column figures have readable axes, legends, and labels at normal
viewing size; Tables I--VI fit their spans and remain readable; Algorithm 1 and
Eqs. (8)--(15) remain inside the column. Page 9 has substantial unused vertical
space because the remaining references are balanced across its two columns;
this is not clipping or a stranded float. No figure is clipped, no table
overlaps text, and no float-placement defect was found. Color figures also use
labels, marker shapes, or distinct line styles rather than color alone.

## Numeric and release integrity

`generated/metrics.tex`, `generated/headline_metrics.csv`, the EXP11
verification record, `references.bib`, and `REFERENCE_AUDIT.csv` are unchanged
from the accepted `ff4065c5...` baseline. `paper_guard` and `paper_audit` pass;
scientific-source modifications are zero. EXP11 remains separately anchored
supplemental evidence outside `simulation-v1.0` while being citable by the
paper.

The end-to-end semantic review found and repaired 17 compressed logical or
interpretive gaps. Reviewer red-team disposition is PASS 7, FIX WORDING 0,
LIMITATION 8; each limitation is stated rather than answered with a new claim.

## Manual submission items

Author names, affiliations, mailing addresses, phone numbers, email addresses,
correspondence details, funding disclosure, and ORCIDs still require verified
owner input. Self-citation count is likewise
`BLOCKED_BY_AUTHOR_METADATA`, because the placeholder author list cannot be
matched against the bibliography; it must be rechecked against the TCNS limit
of five after names are supplied. If accepted, real author biographies and
photographs must be added and the 12-page total budget rechecked. No submission
metadata or identity was invented in this batch.
