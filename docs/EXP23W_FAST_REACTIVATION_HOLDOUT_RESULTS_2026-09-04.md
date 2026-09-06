# EXP23W — Fixed-graph fast-reactivation holdout results

Run: `results/exp23w_fast_reactivation_holdout/2026-09-04_225232`

Status: **FAST_REACTIVATION_FIXED_GRAPH_CONFIRMED**.

The preregistered holdout completed all 800/800 trajectories over the disjoint
seed block `16083001:16083100`. The frozen registry hash is
`174479477/159`; the frozen-source hash is `35903784847/38`. All 21/21
integrity gates passed before outcome interpretation.

All 300/300 normal fast trajectories reactivated after causal eligibility and
fresh incident-witness closure but before the conservative old fence. All
600 dynamic events occurred after positive scheduled state, emitted one exact
24-byte common-PHY REVOKE and suppressed locally in the event frame. Delivered
and permanently lost REVOKE arms have identical local suppression,
reactivation, RMSE and offered-utilization histories. All permanent
reacquisition-RESPONSE-blackout rows remain suppressed.

The six registered one-sided paired tests all reject after Holm correction:

| Test | Registered contrast, candidate minus tested reference | Mean delta | Bootstrap 95% CI | Holm-adjusted p |
|---|---|---:|---:|---:|
| H1 | early RMSE minus conservative early RMSE | -0.001500 m | [-0.001834, -0.001219] | 1.14e-15 |
| H2 | late RMSE minus conservative late RMSE | -0.003571 m | [-0.004068, -0.003135] | 4.60e-27 |
| H3 | early RMSE minus 1.01 x static RMSE | -0.000555 m | [-0.000562, -0.000548] | 5.55e-119 |
| H4 | early cost minus static cost | -0.000983 | [-0.001063, -0.000899] | 1.65e-42 |
| H5 | early cost minus 1.05 x conservative early cost | -0.003145 | [-0.003351, -0.002937] | 7.31e-51 |
| H6 | late cost minus 1.05 x conservative late cost | -0.003222 | [-0.003427, -0.003019] | 9.96e-53 |

In direct descriptive terms, fast reactivation reduces RMSE by 2.64% for the
early event and 5.98% for the late event relative to old-fence waiting. It
raises offered utilization by 3.81% and 3.78%, respectively, remaining below
the registered 5% ceiling. Fast early has mean RMSE 0.055318 m and offered
utilization 0.274280, compared with 0.055320 m and 0.275263 for static
coherence. Fast late has mean RMSE 0.056185 m at cost 0.274273.

Neither fast arm is epsilon-dominated by the static or periodic reference
under the frozen 1% RMSE / 1% cost rule. The periodic arm remains more
accurate but more expensive. The permanent RESPONSE-blackout arm has mean
RMSE 0.063050 m and cost 0.294597 and remains a disclosed fail-silent
performance boundary.

Every scheduled candidate row has zero scheduled collisions, false-valid
edge frames, safety failures and divergence. DATA/control replay,
affine-clock composition, common-PHY overlap, background overlay, management
bytes/airtime, recipient accounting, absolute control bounds and causal
forbidden-read checks all close.

Artifact SHA-256:

- `trajectory_tidy.csv`: `C3F65197B4CC371602B6B1DDA60C6869A4CEE0224DE05ECE2E0E63D5826BB896`
- `primary_tests.csv`: `2BA207DA330F79B964A6FADCB97701CED25D3E00F252D2E94FF94129DB6DACC2`
- `holdout_verdict.json`: `09A748C43386E0D2E668C52E121752AA24359FD8BE67365E2178030E460DDC5A`

Scope boundary: this confirmation proves the fixed-graph mechanism only. It
does not validate replacement of the certified graph or color under topology
change. The authorized next study is causal local union-graph migration with
new incident edges, removed edges, a changed slot, packet loss and a missing-
response fail-silent boundary.
