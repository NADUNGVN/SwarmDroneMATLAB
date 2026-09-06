# EXP22L event-driven targeted-frontier results

Run: `results/exp22l_event_driven_frontier_gate_repair/2026-09-01_195423`

## Validity

- 180/180 unique rows: 30 fresh paired seeds, two cells, three arms.
- 13/13 integrity gates passed.
- Zero causal/protocol/safety/divergence failures.
- Exact DATA and management replay, recipient and airtime accounting.
- Zero GRANT without decoded request; exact STATUS partition.
- Maximum logical control-attempt/bound ratio: 0.982967.
- First all-certified frame never exceeded `N`.

The valid decision is `ELCS_TARGETED_FRONTIER_SURVIVES`. This permits only the
next development study; it is not a promotion, robustness or submission claim.

## Means and paired contrasts

| Cell | Arm | RMSE (m) | Offered util. | Relative to ELCS |
|---|---|---:|---:|---|
| N5 6-DOF | event-driven ELCS-F | 0.0301093 | 0.2936320 | reference |
| N5 6-DOF | periodic cost-match | 0.0303695 | 0.2931200 | RMSE +0.864%; cost -0.174% |
| N5 6-DOF | periodic -2% | 0.0308107 | 0.2880000 | RMSE +2.329%; cost -1.918% |
| N10 ring2 | event-driven ELCS-F | 0.0508588 | 0.3188565 | reference |
| N10 ring2 | periodic cost-match | 0.0556806 | 0.3195563 | RMSE +9.481%; cost +0.219% |
| N10 ring2 | periodic -2% | 0.0561576 | 0.3123200 | RMSE +10.419%; cost -2.050% |

For N5 periodic -2%, the paired RMSE delta (periodic minus ELCS) was
0.00070137 m with 95% bootstrap CI [0.00069229, 0.00071057]; the cost delta was
-0.0056320 with CI [-0.0057685, -0.0054955]. For N10, the corresponding RMSE
delta was 0.00529887 m [0.00527297, 0.00532575] and cost delta -0.00653653
[-0.00674987, -0.00632320].

No periodic reference satisfied strict or practical epsilon dominance.

## Remaining boundary gap

The practical rejection rule admits a periodic dominator at exactly 1% lower
cost. EXP22L's buffered arm realized about 1.92--2.05% lower cost. Because N5
is close, the most favorable eligible periodic point lies nearer the -1%
boundary and was not directly sampled. EXP22M therefore freezes a 0.99-cost
arm before robustness begins. The rate is derived from communication cost
only; no EXP22L RMSE is used to choose it.
