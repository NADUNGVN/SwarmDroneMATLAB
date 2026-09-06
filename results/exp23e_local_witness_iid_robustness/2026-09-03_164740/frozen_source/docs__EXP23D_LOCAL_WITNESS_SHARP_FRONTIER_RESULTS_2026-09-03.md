# EXP23D — ELCS-W sharp measured-cost periodic frontier results

Run: `results/exp23d_local_witness_sharp_frontier/2026-09-03_163244`

Status: **valid frontier evidence; robustness and method-promotion gates remain
open**.

## Execution and integrity

- 30 fresh paired seeds (`16061001:16061030`), disjoint from EXP23C and the
  cost-only calibration seeds.
- Two cells and three arms; 180/180 unique trajectories completed in 4 min
  56 s.
- Registry hash `63727237` over 52 leaves.
- All 15/15 frozen integrity gates passed.
- Zero unsafe or divergent trajectories.
- Verdict: `ELCS_W_SHARP_PERIODIC_FRONTIER_SURVIVES`.

The lower-cost periodic arm achieved the required measured cost condition,
not merely a nominal-rate condition:

- N5: 1.28535% lower total offered utilization than ELCS-W;
- N10: 1.38292% lower total offered utilization than ELCS-W.

## Frontier result

| Cell | Arm | Mean RMSE (m) | Mean total offered util. | Relative RMSE vs ELCS-W | Relative cost vs ELCS-W |
|---|---|---:|---:|---:|---:|
| N5 6-DOF | ELCS-W | 0.02991136 | 0.29045333 | — | — |
| N5 6-DOF | periodic cost-match | 0.03075743 | 0.29056000 | +2.82862% | +0.03672% |
| N5 6-DOF | periodic lower-cost | 0.03084423 | 0.28672000 | +3.11880% | -1.28535% |
| N10 ring-2 | ELCS-W | 0.05086633 | 0.30976000 | — | — |
| N10 ring-2 | periodic cost-match | 0.05615141 | 0.30976000 | +10.39014% | 0.00000% |
| N10 ring-2 | periodic lower-cost | 0.05673587 | 0.30547627 | +11.53915% | -1.38292% |

For the lower-cost periodic contrast, the paired 95% bootstrap intervals for
`RMSE_periodic - RMSE_ELCS-W` are:

- N5: `[0.00091773, 0.00094828]` m;
- N10: `[0.00585271, 0.00588572]` m.

Both intervals are strictly positive, and the point-estimate RMSE penalties
are substantially larger than the pre-registered +1% epsilon allowance.
Therefore neither lower-cost periodic reference epsilon-dominates ELCS-W.
The cost-match references also have higher RMSE in both cells.

No strict dominance, epsilon-dominance, or confidence-supported epsilon-
dominance by periodic TDMA is found.

## Interpretation and next gate

This result strengthens the candidate relative to EXP22M because the
all-to-all management assumption has been removed while total control airtime
is charged by actual variable packet bytes. It establishes a fresh-seed,
common-PHY clean-channel frontier advantage over guarded periodic TDMA.

It does not establish robustness. Under control loss, exact-sequence retry
increases CLAIM/RESPONSE airtime; under DATA loss, delivery freshness and
formation error change even if the certified schedule remains collision-free.
The next frozen study must therefore cross loss location (CLAIM, RESPONSE,
DATA and joint loss) with N5/N10 cells, retain retry and terminal-certificate
failures, and compare against matched periodic references using actual total
airtime. Method promotion and any submission claim remain forbidden until
that robustness gate passes.
