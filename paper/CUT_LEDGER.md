# Controlled cut ledger

The uncut scientific-content manuscript compiled to 20 pages after conversion
to the required TCNS `IEEEtran` layout (CI run 33152637160). The official
limit is 12 pages. The entries below record every substantive removal or move.
No frozen scientific result or generated metric was changed.

Final result: **9 pages**, with text words reduced from **10,559** to **3,038**;
figures/tables/references changed from **13/8/53** to **3/6/53**.

| Original section/material | Removed or compressed | Reason | Destination | Claim affected? | Evidence preserved? |
|---|---|---|---|---|---|
| Introduction | Repeated background, experiment chronology, and duplicated numerical narration | Tier A redundancy | Concise main introduction; full provenance remains in reproducibility artifacts | No | Yes |
| Related Work | Per-paper exposition | Tier A generic background already supported by citations | Five compact main-paper strands; full matrix/audit remains in `RELATED_WORK_MATRIX.md` | No | Yes |
| Method Figures 1--2 | Architecture and packet-timeline schematics | Tier B presentation; semantics are specified mathematically and algorithmically | Removed from PDF; source figures remain in repository | No | Yes |
| Method | Two long algorithms and repeated prose | Tier A/B compression | One compact sender/ACK algorithm plus equations and invariants in main | No | Yes |
| Experimental Setup | Detailed chronology, eligibility narration, and statistical tutorial | Tier A reproducibility detail | Concise main protocol; manifests and paths remain in `REPRODUCIBILITY.md` | No | Yes |
| Results Table I | Full parameter table | Reproducibility detail, not evidence | Frozen generated table remains in repository and configuration manifest | No | Yes |
| Results Figures 3, 4, 11, 13 | Plot restatements of retained design, nominal, paired-CI, and EXP11 tables | Tier B duplicate presentation | Corresponding generated figures remain in repository | No | Yes; Tables II--IV and VII--VIII retain the values |
| Robustness Table V and Figures 6--8, 10 | Full secondary matrices and diagnostic plots | Tier B secondary detail | Generated artifacts remain in repository; main text synthesizes boundaries | No promoted claim | Yes; 6-DOF Figure 9 and complete negative/boundary Table VI remain |
| Results prose | Repeated per-experiment narration | Tier A chronology | R1--R6 hierarchy in main | No | Yes |
| Discussion | Eleven mechanism/diagnostic subsections | Tier A repeated interpretation | Three compact main subsections | No | Yes |
| Limitations | Ten repeated subsections | Tier A repetition | One explicit main section | No | Yes |
| Conclusion/future work | Repeated results, future-work inventory, reproducibility subsection | Tier A repetition | Concise conclusion; reproducibility artifacts retained | No | Yes |
| Appendix reproducibility pointer | Standalone appendix | Page economy; TCNS policy does not authorize an evidence supplement for this case | Existing repository reproducibility documents | No | Yes |

No content was moved to a manuscript supplement: the TCNS-specific policy
does not authorize a length-avoidance scientific supplement for this paper.
