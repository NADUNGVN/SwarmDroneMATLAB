# Operational amendment 02

After all 360 rows, tables and the 16/16 valid verdict were written, final
housekeeping lacked the timer and index metadata in the resumed experiment
struct. The helper now reconstructs them from the opened record, run path and
active MATLAB version. Resume has zero pending simulation work and only
regenerates deterministic analyses and finishes provenance/index bookkeeping.
See `docs/EXP21D_BOUNDARY_AMENDMENT_02.md`.
