# EXP23Z aborted pre-execution run

Directory: `results/exp23z_local_migration_closed_loop/2026-09-05_072551`.

The runner stopped before registry serialization and before trajectory 1
because the new experiment file referenced local `writeJson` and
`snapshotSource` helpers that had not yet been defined. No trajectory,
summary, gate or verdict artifact was produced. The scientific registry,
matrix and validation criteria were not changed. The directory is retained
as an auditable pre-execution software failure and cannot support any claim.
