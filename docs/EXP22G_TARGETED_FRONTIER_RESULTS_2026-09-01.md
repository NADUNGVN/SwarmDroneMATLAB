# EXP22G: targeted frontier closure results

**Run:** `results/exp22g_targeted_frontier_closure/2026-09-01_182938`  
**Integrity:** 180/180 rows, 10/10 gates  
**Verdict:** `ELCS_EPSILON_DOMINATED_RETURN_TO_DESIGN`

The interpolation gap left by EXP22F changes the research decision. The
2%-below-cost periodic point confidence-supported epsilon-dominates ELCS-F in
both cells; at N5 it also strictly dominates under the original two-axis 1%
rule.

| Cell | Arm | RMSE (m) | Total offered util. | Relative RMSE vs ELCS | Relative cost vs ELCS |
|---|---|---:|---:|---:|---:|
| N5 | ELCS-F | 0.030112 | 0.350720 | — | — |
| N5 | periodic cost-match, 22.8378 Hz | 0.028659 | 0.350720 | -4.82% | 0.00% |
| N5 | periodic -2%, 22.3810 Hz | 0.028943 | 0.343885 | -3.88% | -1.95% |
| N10 | ELCS-F | 0.050876 | 0.376977 | — | — |
| N10 | periodic cost-match, 12.2706 Hz | 0.050738 | 0.377207 | -0.27% | +0.06% |
| N10 | periodic -2%, 12.0251 Hz | 0.051319 | 0.369527 | +0.87% | -1.98% |

For the N5 -2% arm, paired RMSE delta is `-0.001168 m` with 95% bootstrap CI
`[-0.001182, -0.001155]`; cost delta is `-0.006835` with CI
`[-0.006972, -0.006699]`. For N10, RMSE is within the frozen 1% tolerance
(`+0.870%`) while cost is lower by `1.976%`; both confidence conditions hold.

The negative result is not a safety failure. All lease, clock, physical replay,
airtime and closed-loop gates remain valid. It is an efficiency failure caused
by recurring STATUS/GRANT traffic displacing useful state delivery. Robustness
and confirmation are therefore closed for the current design.
