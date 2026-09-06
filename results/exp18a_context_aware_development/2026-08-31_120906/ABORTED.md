# Aborted pre-performance development run

This run stopped in the first parallel batch before any performance row or
checkpoint was written. MATLAB rejected assignment between dissimilar row
structures because disabled-context arms omitted two EXP18 metadata fields.

- No development outcome was analyzed.
- This directory is not evidence and must not be resumed.
- The schema contract was repaired in `utils/runExp18Cell.m` and added to
  `tests/test_exp18_contracts.m` before opening a new run ID.
