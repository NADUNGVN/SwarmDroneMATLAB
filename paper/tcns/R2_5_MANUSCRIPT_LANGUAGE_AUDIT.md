# R2.5 adversarial manuscript-language audit

The source was searched case-insensitively for `all`, `always`, `general`,
`generic`, `universal`, `requires`, `necessary`, `sufficient`, `minimum`,
`exact`, `every`, `cannot`, and `impossible`.  The theorem-scoped occurrences
were checked against their assumptions.  The R2-linked occurrences are
audited below by manuscript location.

| Location / wording | Scope check | Disposition |
|---|---|---|
| Abstract: 1320/1320 registry functionals | explicitly follows the 72-combination registry definition | retain |
| Abstract: all ten actual actions | immediately restricted to the frozen five-UAV instance | retain |
| Contribution 4: 1320/1320 and all ten | registry and frozen N=5 scopes both explicit | retain |
| Sec. VIII-A: “All 72 configurations” | bounded by the frozen Cartesian registry | retain |
| Table II: “every row ... gains one rank when its value row is appended” | ambiguous because raw augmented rank is scale/cutoff sensitive | revise to normalized value row plus orthonormal retained row basis |
| Sec. VIII-A: all 72 VPA checks positive | selected one minimum-residual action per cell; wording does not mean every action had VPA | retain with “selected” qualifier already present |
| Sec. VIII-A: membership stable for all 1320 | independently reproduced at all five tolerances | retain |
| Sec. VIII-B: every controller-relevant action / all ten | subsection first fixes the N=5 catalog | retain; add independent persisted replay/fixed-response sentence |
| Table III/Fig. 6: all ten actions | captions explicitly say N=5 | retain |
| Sec. VIII-C: every fixed payload has rank one | refers to frozen N=5 payload table in immediate context | retain |
| Sec. VIII-C: every sender needs all five agents | immediately restricted to evaluated N=5 graph/H/objective/maps and later contradicted for geometric registry | retain |
| Sec. VIII-C: leader compression in every registry cell; every tested follower | finite registry and “tested” are explicit | retain |
| Sec. VIII-C: every sender for ring2/sparse4 | refers to registry rows only | retain; add aggregate distribution without generalization |
| Conclusion: all 1320 and all ten | explicitly says 72-cell registry and evaluated five-UAV topology | retain |

No empirical R2 statement is promoted to a general theorem.  The one material
language defect is the unqualified augmented-rank phrase; R2.5 requires it to
be rewritten as a scale-controlled normalized-basis diagnostic.
