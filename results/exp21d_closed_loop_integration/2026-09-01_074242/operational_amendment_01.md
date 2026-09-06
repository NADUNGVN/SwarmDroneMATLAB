# Operational amendment 01

After the first complete checkpoint (18/180 rows), the failed process-pool
startup was removed by changing the batch runner from `parfor` to `for`.
MATLAB had already executed the first batch serially. The registry, simulations,
seeds, traces, metrics, gates and analysis are unchanged. The run resumes from
the existing checkpoint; completed rows are not recomputed. See
`docs/EXP21D_CLOSED_LOOP_AMENDMENT_01.md` in the project source.

