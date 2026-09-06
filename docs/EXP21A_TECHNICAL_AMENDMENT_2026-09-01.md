# EXP21A technical amendment — integrity-gate count label

**Recorded:** 2026-09-01, after the full 1680-row outcome was generated

**Classification:** reporting-only literal correction

The first analyzer execution wrote `13 integrity gates pass` into the detail
text of the `all_integrity_gates` decision row.  The actual integrity table has
15 rows and all 15 passed.  The number 13 was a stale hard-coded display
literal in `analyzeExp21AResults.m`; it was not used in any Boolean decision.

The literal is replaced by `all integrity gates passed`.  The analyzer alone
is rerun.  No trajectory, seed, cell, arm, trace, metric, threshold, decision
logic, gate value, or verdict changes.  The run's `frozen_source` directory
retains the originally executed analyzer, and this amendment is retained next
to the study documentation and in the run directory.
