# EXP22F: direct feasibility results

**Run:** `results/exp22f_direct_feasibility/2026-09-01_180435`  
**Integrity:** 600/600 rows, 14/14 gates  
**Frozen decision:** `ELCS_FEASIBILITY_NONDOMINATED_CONTINUE_REFERENCES`

## Integrity

All static schedules are collision-free under the full-mission affine clock;
D-STR and ELCS receiver masks replay exactly; all management, recipient and
offered-airtime accounts close; and no row has a causal, protocol, safety or
divergence failure.

## Direct frontier

ELCS-F occupies a real tradeoff point on the sampled grid:

- N5: RMSE `0.030112`, total offered utilization `0.350788`;
- N10: RMSE `0.050863`, total offered utilization `0.376951`.

Native D-STR is more accurate but more expensive:

- N5: RMSE improves by `6.70%`, cost rises by `9.62%`;
- N10: RMSE improves by `29.07%`, cost rises by `101.0%`.

No sampled periodic point improves both ELCS metrics by the preregistered 1%
margin. However, this result is not yet a robust non-dominance certificate:

- N5 periodic 20 Hz has RMSE only `0.148%` worse while using `12.43%` less
  offered load. The paired RMSE difference is small but positive
  (`[3.21e-5, 5.66e-5] m`).
- N10 periodic 12.5 Hz has `1.43%` lower RMSE while using only `1.87%` more
  offered load.

Because pre-saturation periodic airtime is linear in requested rate, both
cells have an untested interpolation interval near the ELCS cost. The sampled
grid verdict therefore authorizes a targeted frontier closure, not robustness.

## Decision refinement without rescoring

The frozen EXP22F verdict and files remain unchanged. Programme-level
continuation is deliberately stricter: EXP22G will evaluate analytically
cost-matched and 2%-below-cost periodic rates on disjoint seeds. It will report
both the original “1% better on both axes” rule and a practical epsilon rule:
at least 1% cheaper with RMSE no more than 1% worse. This directly addresses
dominance-margin sensitivity rather than selecting a favorable convention.
