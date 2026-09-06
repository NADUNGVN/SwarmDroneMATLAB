# EXP23E — ELCS-W separated and joint 5% IID loss results

Run: `results/exp23e_local_witness_iid_robustness/2026-09-03_164740`

Status: **valid bounded-IID robustness evidence; burst/load robustness and
method promotion remain open**.

## Execution and integrity

- 30 fresh seeds, two topology cells, five packet-class loss conditions and
  two arms.
- 600/600 unique trajectories completed in 16 min 44 s.
- Registry hash `77758983` over 68 leaves.
- All 19/19 integrity gates passed.
- Candidate and periodic arms used the same absolute link-time DATA-loss
  random field; conditions were nested on the same per-seed field.
- Variable CLAIM/RESPONSE bytes and airtime closed exactly.
- Maximum full-kernel attempt and byte bound ratios were `0.146000` and
  `0.141437`.
- Verdict: `ELCS_W_IID5_ROBUSTNESS_SCREEN_SURVIVES`.

## Safety and liveness

Across all 300 ELCS-W trajectories:

- physical terminal certification rate is 100% in every cell/condition;
- false-valid edge-frames: 0;
- scheduled collision frames: 0;
- safety failures: 0;
- divergences: 0.

Control loss activates the intended exact-sequence retry behavior while
remaining bounded. Mean physical retry CLAIM counts are:

| Cell | CLAIM 5% | RESPONSE 5% | Joint 5% |
|---|---:|---:|---:|
| N5 | 18.47 | 11.50 | 30.57 |
| N10 | 24.23 | 12.90 | 39.07 |

Mean uncertified node-frames remain small: the maximum is 2.63 in the N10
joint condition. Two isolated fallback-collision frames occur over the full
study (one N5 joint and one N10 RESPONSE condition); neither becomes a
scheduled collision or a terminal certification/safety failure.

## Periodic falsification result

The fixed EXP23D periodic reference is at least 1% cheaper in all ten
cell/condition contrasts. Nevertheless it does not meet the +1% RMSE
allowance in any contrast.

| Cell | Condition | ELCS-W RMSE (m) | Periodic RMSE (m) | Periodic RMSE penalty | Periodic cost advantage |
|---|---|---:|---:|---:|---:|
| N5 | Clean | 0.0299120 | 0.0308327 | +3.0780% | 1.2853% |
| N5 | CLAIM 5% | 0.0299120 | 0.0308327 | +3.0780% | 2.6508% |
| N5 | RESPONSE 5% | 0.0299120 | 0.0308327 | +3.0780% | 2.3164% |
| N5 | DATA 5% | 0.0312182 | 0.0320298 | +2.5997% | 1.2853% |
| N5 | Joint 5% | 0.0312182 | 0.0320298 | +2.5998% | 3.5787% |
| N10 | Clean | 0.0508617 | 0.0567449 | +11.5672% | 1.3857% |
| N10 | CLAIM 5% | 0.0508617 | 0.0567449 | +11.5671% | 3.2701% |
| N10 | RESPONSE 5% | 0.0508616 | 0.0567449 | +11.5673% | 2.7044% |
| N10 | DATA 5% | 0.0542943 | 0.0602478 | +10.9654% | 1.3857% |
| N10 | Joint 5% | 0.0542943 | 0.0602478 | +10.9652% | 4.5475% |

Every paired 95% bootstrap interval for
`RMSE_periodic - RMSE_ELCS-W` is strictly positive. The narrowest robustness
margin is N5 under DATA or joint loss: periodic is approximately 2.60% worse
in RMSE, still above the 1% kill boundary.

No point-estimate or confidence-supported epsilon-dominance is found.

## Mechanistic interpretation

CLAIM/RESPONSE loss raises control airtime but barely changes RMSE because
uncertified nodes use the bounded fallback region and recover quickly. DATA
loss, in contrast, raises true AoI and RMSE in both methods while leaving the
witness schedule and control effort bit-identical to clean. This separation
confirms that control retry and DATA freshness effects are not conflated.

The hardest observed cell is N5 under DATA loss, where the RMSE advantage
contracts from about 3.08% to 2.60%. A stronger stress study must therefore
target correlated/bursty loss and exogenous channel occupancy, not simply add
more IID seeds at the same 5% probability.

## Next gate

EXP23E is only a 5% IID screen. The next study must introduce time-correlated
loss bursts and actual shared-channel exogenous occupancy on the replay
timeline, preserve one-hop management and variable packet accounting, and
retain cell-specific dominance decisions. Until that passes, no broad
robustness, method-promotion or submission claim is authorized.
