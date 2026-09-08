# GM appendix and supplementary-material structure

The main manuscript already contains self-contained theorem statements,
proofs, the formation mapping, and reproducibility scope.  A submission-stage
supplement should contain only the following evidence, generated from existing
frozen sources.

1. **S1: sampled formation derivation.** Expanded construction of
   \(A_h,D_h,T_y,T_\nu,F_H,r_H\), including analytical-leader residuals and
   the semi-implicit Euler convention.  Source:
   `paper/tcns/THEORY_NOTES.md` and `utils/tcnsInformationLimitsModel.m`.
2. **S2: full sender information maps.** Per-agent state-coordinate tables,
   current maps, held-memory history maps, and the argument that known action
   and sent histories affect only affine data.  Source:
   `utils/tcnsInformationLimitsSenderMap.m`.
3. **S3: all ten numerical audits.** Singular values, rank tolerance,
   current/history residuals, missing-vector norms, and one-scalar closure.
   Source: authoritative IL `link_identifiability.csv` and workspace.
4. **S4: dynamic witness construction.** Consistent-initialization map,
   null-space direction, scaling, exact erasure history, saturation checks,
   and full traces for ordinary 1->5 and pin 1->4.  Source:
   `tcnsInformationLimitsDynamicWitness.m` and Fig. 6 data.
5. **S5: centralized oracle diagnostic breadth.** S3, S5, and S6 frontiers;
   traffic allocation and no-information-attempt diagnostics.  S4 remains the
   main-paper negative boundary.  Source: frozen O1 Stage A/B artifacts.
6. **S6: receiver-information accounting.** C0/C1/C2 reconstruction and all
   operating-point break-even values.  Source: AB0 and FB0 artifacts.
7. **S7: stopped-path record.** Concise reproducible account of bound-trigger
   falsification, explicit-ACK stop, calibrated ACK-free memory belief, and AF3
   identifiability stop.  This protects against selective reporting without
   turning the paper into a scheduler chronology.
8. **S8: artifact manifest.** Git SHAs, MATLAB R2025a, seeds, configs, commands,
   checksums, and machine-readable file index.

No new policy comparison, held-out claim, scalability grid, 6-DOF theorem, or
Bayesian posterior is required for this supplement.

