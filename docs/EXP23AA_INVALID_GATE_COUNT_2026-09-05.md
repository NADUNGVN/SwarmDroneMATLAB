# EXP23AA invalid run — registry gate-count mismatch

Invalid run:
`results/exp23aa_emergency_data_development/2026-09-05_073456`.

All 120 trajectory rows were generated, but analysis stopped before writing
`validation_gates.csv` or a verdict. The frozen registry declared 18 required
contracts while the runner implemented 19: `supported_closed_loop_safety`
had been added as a separate gate without updating the counter.

No criterion, arm, seed, parameter or statistical comparison is changed.
The registry and plan are corrected to 19 contracts and the complete matrix
must be rerun. This directory is invalid and cannot support a claim; its
intermediate summary and contrast files are not promoted.
