# EXP23E — ELCS-W separated and joint 5% IID loss robustness

Status: frozen before fresh-seed trajectory generation on 2026-09-03.

## Question

Does ELCS-W retain terminal local certification, lease safety and its
formation-error advantage over the EXP23D lower-cost periodic reference when
5% IID loss affects CLAIM, RESPONSE, DATA, or all three packet classes?

EXP23E is a bounded IID robustness screen. Passing it permits a later bursty-
loss and exogenous-load study; it does not by itself establish broad
robustness or promote the method.

## Frozen design

- Parent frontier:
  `results/exp23d_local_witness_sharp_frontier/2026-09-03_163244`.
- Fresh seeds: `16063001:16063030`.
- Cells: N5 6-DOF and N10 ring-2.
- Loss conditions: clean, CLAIM IID 5%, RESPONSE IID 5%, DATA IID 5%, and
  joint CLAIM/RESPONSE/DATA IID 5%.
- Arms: fixed EXP23D lower-cost guarded periodic TDMA and ELCS-W with affine
  clocks.
- Total: 600 paired trajectories.
- No retransmission is added to DATA. ELCS-W retains its already validated
  exact-sequence CLAIM retry rule.
- Management reach remains exactly one hop.

DATA losses for both arms are derived from the same absolute
`(time-slot, receiver, sender)` shared-medium random field. ELCS-W outcomes
are overlaid after the affine clock transform, so the draw is indexed by the
actual physical transmission time. CLAIM and RESPONSE conditions threshold
the frozen ELCS-W control trace. All five conditions for one seed/cell are
nested on the same absolute random realizations.

## Falsification criteria

Experiment integrity requires all 19 accounting, causality, stimulus and
pairing gates to pass. Unsafe, divergent, false-valid and terminal-
uncertified outcomes are retained as scientific results rather than being
reclassified as experiment-integrity failures.

After integrity passes, ELCS-W fails this screen if any cell/condition has:

- terminal physical certification rate below 100%;
- any false-valid edge-frame or scheduled collision;
- any candidate safety failure or divergence; or
- periodic epsilon-dominance, defined as periodic mean cost at least 1%
  lower and periodic mean RMSE no more than 1% above ELCS-W.

Paired 10,000-resample 95% bootstrap intervals are reported for RMSE and
total offered utilization. Point-estimate epsilon-dominance remains the
conservative kill rule.

Possible decisions are:

- `ELCS_W_IID_ROBUSTNESS_STUDY_INVALID` for failed integrity;
- `ELCS_W_IID_ROBUSTNESS_SAFETY_FAIL` for certification/safety failure;
- `ELCS_W_IID_EPSILON_DOMINATED_RETURN_TO_DESIGN` for periodic dominance;
- `ELCS_W_IID5_ROBUSTNESS_SCREEN_SURVIVES` otherwise.
