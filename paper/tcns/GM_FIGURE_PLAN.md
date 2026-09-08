# GM main-figure and table plan

All numerical figures are generated from frozen machine-readable artifacts by
`paper/tcns/manuscript/make_gm_figures.m`.  No scientific datum is edited by
hand.

| Item | Main question | Source | Status/scope |
|---|---|---|---|
| Fig. 1 information architecture | What does a sender see, and what remains distributed? | implementation graph/model | schematic; no performance claim |
| Fig. 2 mechanism falsification | Does a valid communication-error bound make a good scheduler? | Gate-5 frozen frontiers | motivating development counterexample |
| Fig. 3 centralized headroom and boundary | Is exact current value ever useful, and is it universal? | O1 S2 and S4 frozen frontiers | privileged diagnostic; not deployable |
| Fig. 4 feedback economics | At what information price does headroom disappear? | FB0 frozen tables | development accounting diagnostic |
| Fig. 5 information geometry | Why is exact action value hidden? | generic row/null-space geometry | explanatory theorem schematic |
| Fig. 6 reachable sign ambiguity | Can identical sender histories require opposite value-sign decisions? | IL dynamic witnesses | theorem validation for ordinary 1->5 and pin 1->4 |
| Table I prior-art matrix | What is established and what is the scoped gap? | GM novelty audit | four-thread story |
| Table II identifiability | Does the condition fail on all N=5 payloads? | IL 10-link table | all 10 affine; two dynamic witnesses only |
| Table III coalition/economics | Who owns the statistic and can traffic pay for it? | IL coalition + FB0 | N=5 and frozen cost metric only |

S6 O1 is supplemental.  The old AoI-policy development plots, calibration
plots, and all other scenario frontiers remain reproducible but do not enter
the main paper.

