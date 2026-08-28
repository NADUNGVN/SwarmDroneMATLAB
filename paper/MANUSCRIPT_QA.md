# TCNS manuscript QA

## Compiled layout

The accepted scientific-content baseline was 23 pages before TCNS conversion.
With content unchanged, the required `IEEEtran` TCNS layout compiled to 20
pages (CI run 33152637160). Controlled reduction then produced a 9-page main
manuscript, including all figures, tables, and 53 references.

| Check | Final result |
|---|---:|
| Undefined citations | 0 |
| Undefined references | 0 |
| Duplicate labels | 0 |
| Missing figures/tables | 0 |
| Overfull hbox / vbox | 0 / 0 |
| Underfull hbox / vbox | 5 / 1 |
| Float-placement problems | 0 |
| Figures / tables / references | 3 / 6 / 53 |
| Text words (`texcount`) | 3,038 |
| Headers / caption words | 101 / 166 |

The five underfull hboxes occur in the long safety equation paragraph, one
narrow Table I text cell, and the H2b paragraph. The one underfull vbox is a
page-building warning adjacent to a wide figure. Rendering shows no clipping,
overlap, or readability defect; these warnings are cosmetic.

## Compilation environment

GitHub Actions compiles only `paper/main.tex` in isolated TeX Live 2025 using
`latexmk`/`pdflatex`, stages `paper/output/manuscript_tcns.pdf`, and uploads the
PDF, log, BibTeX products, word count, and QA report. The workflow does not run
MATLAB and rejects changes under the frozen scientific-source directories.
Nothing was installed in the local research environment.

## Visual QA

All nine PDF pages were rendered to PNG and inspected. The three two-column
figures have readable axes, legends, and labels at normal viewing size; Tables
I--VI fit their spans; Algorithm 1 and Eqs. (8)--(15) remain inside the column;
the final bibliography page is balanced with `flushend`.
No figure is clipped, no table overlaps text, and no float is stranded.
Color figures also use labels, marker shapes, or distinct line styles rather
than color alone.

## Numeric and release integrity

`generated/metrics.tex`, `generated/headline_metrics.csv`, the EXP11
verification record, `references.bib`, and `REFERENCE_AUDIT.csv` are unchanged
from the accepted `ff4065c5...` baseline. `paper_guard` and `paper_audit` pass;
scientific-source modifications are zero. EXP11 remains separately anchored
supplemental evidence outside `simulation-v1.0` while being citable by the
paper.

## Manual submission items

Author names, affiliations, correspondence details, funding disclosure, and
ORCIDs still require verified owner input. If accepted, real author biographies
and photographs must be added and the 12-page budget rechecked. No submission
metadata or identity was invented in this batch.
