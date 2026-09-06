# EXP23Y — Local migration common-PHY results

Canonical run:
`results/exp23y_migration_common_phy/2026-09-04_233744`.

Status: **LOCAL_MIGRATION_COMMON_PHY_VALID (18/18 gates)**.

The canonical matrix contains 1,800/1,800 unique rows over 50 seeds,
`N={5,10,20}`, six channel/oracle cases and paired zero/affine clock arms.
It maps the repaired EXP23X local union-graph migration kernel to one
continuous PHY carrying REVOKE, CLAIM, LOCK-PROOF, RESPONSE and DATA.

Results:

- trace, kernel-state, native-schedule and logical-opportunity hashes pair
  exactly across the two clock arms;
- packet-kind, recipient, attempt, byte and exact-airtime accounting replay
  the migration kernel exactly;
- the fixed 20-frame LOCK-PROOF window continues independently after local
  receipt closure, avoiding the causal shortcut found in the superseded
  EXP23X run;
- DATA follows the registered old-slot, silence, and new-slot/fail-silent
  sequence exactly;
- all supported zero-loss, IID-20, IID-40, REVOKE-blackout and
  RESPONSE-blackout rows have zero physical collision frames;
- every zero-loss row reacquires at frame 12; all IID-20 and IID-40 rows
  reacquire, with mean reacquisition frames between 12.94 and 15.22 across
  swarm sizes;
- permanent RESPONSE blackout remains fail-silent and REVOKE loss cannot
  alter the local transition state;
- the analytical affine-clock guard prevents every inter-group overlap and
  trims no registered logical event;
- the incomplete-union negative control remains visible after continuous
  mapping: every clock/size group retains 2,600 unique collision frames, with
  two colliding DATA attempts per collision frame;
- bounds and causal-instrumentation gates pass with zero forbidden reads.

The earlier run `2026-09-04_233623` is invalid and superseded. It compared
colliding DATA-attempt rows with unique physical collision frames, giving 104
versus 52 per deterministic negative fixture. The repair stores both
quantities and adds a regression contract; no physical behavior or supported
safety gate was changed.

Artifact SHA-256:

- `timing_tidy.csv`: `A29B0CDF289A1A95DA62AA6364BEB7F27475554C1A811552EB9376B236016405`
- `summary.csv`: `5989E8A23FC42BEC8515FC181BE653672CB5AC6E654D193B58D3BEA9DC329115`
- `validation_gates.csv`: `063A3CF99D2B57462943E590A3D2ACA98C40170C63539F4B744293FAF10622DD`
- `timing_verdict.json`: `486BFFE6E5F0E8CFD9D628670C981E8EA60AA674245BFCEEE1A6563425AC3F3C`

This is integration-validity evidence only. It does not run the UAV
controller, does not establish a control-performance advantage, and is not
submission evidence by itself. The next gate must compose the same local
migration traffic with shared DATA outcomes and the closed-loop swarm model,
while retaining a graph/oracle construction independent of private future
state.
