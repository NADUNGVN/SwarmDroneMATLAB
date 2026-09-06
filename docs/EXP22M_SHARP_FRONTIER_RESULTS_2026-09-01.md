# EXP22M sharp periodic-frontier results

Run: `results/exp22m_sharp_frontier_closure/2026-09-01_200249`

## Verdict

- 180/180 unique trajectories on 30 fresh paired seeds.
- 13/13 integrity gates passed.
- Decision: `ELCS_TARGETED_FRONTIER_SURVIVES`.
- Robustness continuation is permitted; promotion and submission claims remain
  prohibited.

The finite-horizon 0.99-cost arm was eligible in both cells:

| Cell | ELCS RMSE | Periodic RMSE | ELCS cost | Periodic cost | Relative periodic RMSE | Relative periodic cost |
|---|---:|---:|---:|---:|---:|---:|
| N5 6-DOF | 0.0301129 | 0.0306841 | 0.2935467 | 0.2905600 | +1.897% | -1.017% |
| N10 ring2 | 0.0508672 | 0.0558067 | 0.3191552 | 0.3157077 | +9.711% | -1.080% |

For N5, the paired RMSE delta (periodic minus ELCS) was 0.00057112 m
with 95% bootstrap CI [0.00056050, 0.00058136]. The cost delta was
-0.00298667 with CI [-0.00313173, -0.00285013]. For N10, RMSE delta was
0.00493952 m [0.00491586, 0.00496295], and cost delta was -0.00344747
[-0.00371200, -0.00319147].

Thus the most favorable sampled periodic point satisfying the frozen 1% cost
requirement is outside the 1% RMSE equivalence margin in both cells. The
periodic development frontier is closed for the current zero-loss, full-
visibility model.

## Next gate

The result does not close a more important communication-model boundary.
EXP22I showed that restricting management reach to the one-hop neighbor graph
left 0/200 local-visibility rows fully certified while retaining zero
false-valid events. In the current graphs, 4/10 N5 and 17/30 N10 sender-
conflict edges are not direct neighbor edges, although all lie in the two-hop
closure. The next design gate therefore replaces all-to-all management reach
with explicit one-hop conflict witnesses and fully charged certificate
traffic before running generic loss robustness.
