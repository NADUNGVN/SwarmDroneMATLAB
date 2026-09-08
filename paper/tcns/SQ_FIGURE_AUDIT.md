# SQ figure and PDF visual audit

**Audit date:** 2026-09-08  
**Generator:** paper/tcns/manuscript/make_gm_figures.m  
**Data policy:** every numerical figure was regenerated from frozen
machine-readable results; no scientific datum was edited manually.

## Review procedure

1. Regenerated all six PDF and PNG figures with MATLAB R2025a.
2. Compiled the full IEEEtran manuscript.
3. Rendered all 11 letter-size pages through Poppler at 150 dpi and inspected
   them at desktop page scale.
4. Rendered Figs. 2–6 independently at 200 dpi to approximate/ exceed their
   printed single- or double-column size.
5. Inspected labels, axes, units, legends, line/marker distinction, caption
   scope, clipping, overlap, and whitespace.
6. Used Poppler pdffonts on the final manuscript; every listed font reports
   embedded=yes.

The first final render exposed a literal `qquad` token in Eq. (24) that TeX had
accepted as ordinary text. The source was corrected to `\qquad`, recompiled,
and rerendered. Pixel hashes confirm that only page 5 changed; page 5 was then
reinspected at original rendered resolution.

## Figure-by-figure result

| Figure | Result | QA notes |
|---|---|---|
| Fig. 1 information architecture | Pass | Agent labels, sender-local/global distinction, candidate link, pin links, and caption remain legible at one column. Schematic makes no performance claim. |
| Fig. 2 bound-trigger falsification | Pass | Formation RMSE and frozen Hz/channel metric have units; circle/square markers survive grayscale; caption says five paired development seeds and descriptive scope. |
| Fig. 3 centralized O1 frontier | Pass | Both panels use common units and marker coding; title/caption label O1 centralized, privileged, nondeployable, five-seed, and non-inferential. |
| Fig. 4 ACK-like price sensitivity | Pass | Axis, scenarios, IQR, zero line, and price 0.25 line are readable; title/caption no longer implies that the all-agent statistic's acquisition cost was measured. |
| Fig. 5 information geometry | Pass | row(C), ker(C), value coefficient, and missing projection are distinct by geometry, line style, and color; labels are readable at one column. |
| Fig. 6 reachable witnesses | Pass | Solid/dashed histories, payload classes, units, action-response equality, and opposite signs are clear at double-column scale; title/caption say fixed-response and leader-sender scope. |

## Full-PDF result

- no cropped figure, table, equation, or caption;
- no overlap or broken glyph;
- all six principal figures are vector PDF assets;
- no undefined citation/reference;
- no overfull box;
- underfull spacing warnings were inspected and are visually harmless;
- all fonts embedded;
- page count 11, with main text ending and appendices beginning on page 10.

Final compiled PDF SHA-256:
`3E8D5AC5705DF798002322B37F0C8B758AF1094667D5905B237F134605B21F72`.

**Verdict:** figure and visual-layout QA pass.
