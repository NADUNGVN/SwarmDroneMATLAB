# EXP23Y invalid run — collision frame/attempt ambiguity

Invalid run:
`results/exp23y_migration_common_phy/2026-09-04_233623`.

The run completed all 1,800 rows but passed only 17/18 gates. In every
incomplete-union row the transition kernel reported 52 collision frames,
while the post-clock row recorded 104. Inspection showed that
`applyDstrAffineClockSchedule` reports the number of colliding DATA-attempt
rows in `expectedDataCollisionFrames`; the incomplete-union fixture contains
two colliding transmitters per physical frame. The migration runner
incorrectly compared this attempt-row count with unique kernel frames.

No supported safety, timing, packet, byte, airtime, recipient or causal gate
failed. Nevertheless, the run remains invalid and is not promoted.

The repair stores both quantities explicitly:

- `physicalCollisionAttempts = nnz(any(dataCollisionMask,2))`;
- `physicalCollisionFrames = numel(unique(dataFrame(collisionRow)))`.

A regression contract requires 104 colliding attempts and 52 unique frames
for the deterministic negative fixture. The complete 1,800-row matrix must be
rerun; the failed gate is not relaxed.
