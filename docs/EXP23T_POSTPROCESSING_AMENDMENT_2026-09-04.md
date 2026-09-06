# EXP23T post-processing amendment

Run: `results/exp23t_static_coherence_closed_loop/2026-09-04_180732`

All 300/300 preregistered trajectories completed and were written to
`trajectory_checkpoint.csv` and `trajectory_tidy.csv` before post-processing
failed. The summary function requested nonexistent table column `armLabel`;
the stable closed-loop schema names that descriptive column `methodLabel`.

The sole repair changes the summary grouping column from `armLabel` to
`methodLabel`. It does not change the registry, seeds, trajectories, metrics,
contrast equations, bootstrap settings, gates or decision thresholds. The
same run ID is resumed from the complete checkpoint; no trajectory is rerun.
