# EXP14D operational amendments

## Amendment 001 — exclude CPU runtime from the N5 bit-identity gate

After all 384 simulations completed, the N5 access-scaling negative-control
gate failed while every other integrity gate passed. The runner had already
printed its machine selection before raising on the failed integrity gate.
No detailed cell-wise performance analysis had yet been conducted.

A column-level audit compared all 96 registered N5 `S=0/S=1` pairs. The only
differing column was `NETWORK_RUNTIME_SEC`; every physical, control, AoI,
traffic, accounting, protocol and realization-hash output was bit-identical.
CPU wall time is measured separately for two sequential MATLAB calls and was
never part of the scientific negative-control contract stated in the plan.

The gate is corrected to exclude only `NETWORK_RUNTIME_SEC`. The original
failed `gates.csv` is retained as `gates_pre_runtime_exclusion.csv`. No seed,
trace, simulation row, policy parameter, performance metric, candidate rule or
method output is changed, and the 384 simulations are not rerun. Finalization
recomputes the declared analysis from the existing `tidy.csv`.

Repeated finalization also exposed that `finishExperiment` could append the
same run twice to `results/INDEX.md`. Its index write is now idempotent on the
pair `(runId, experiment)`; the existing three-minute execution entry remains
the sole row for this run.

