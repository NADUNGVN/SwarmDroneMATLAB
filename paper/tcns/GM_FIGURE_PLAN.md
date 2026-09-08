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
| Table II identifiability/rank robustness | Does the condition fail on all N=5 payloads under tolerance and 80-digit checks? | IL/R1 10-link audit | all 10 affine; implementation-derived matrices |
| Table III reachable regret | How large is the unavoidable local binary-decision loss at the witnesses? | IL witnesses + R1 formulas | two preregistered payload classes only |
| Table IV simultaneous actions/coalition | Do actions share missing directions, and who owns the joint subspace? | R1 sender-wise rank + coalition enumeration | N=5 topology/unit responses only |
| Table V feedback economics | Can the frozen traffic budget pay to acquire hidden value information? | FB0 | packet-frequency metric only |

S6 O1 is supplemental.  The old AoI-policy development plots, calibration
plots, and all other scenario frontiers remain reproducible but do not enter
the main paper.
