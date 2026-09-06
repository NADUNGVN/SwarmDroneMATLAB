# EXP20A execution-only technical amendment — 2026-09-01

The first full EXP20A invocation completed all 1,800 native rows and then
stopped before producing any formation row. The formation dispatcher did not
map the frozen identifiers `oracle-deficit-maxweight` and
`oracle-urgency-maxweight` to the already tested EXP19A adapter identifiers
whose only additional suffix is `-piggyback`.

The correction adds only that two-entry identifier map. It does not alter the
registry, arms, algorithms, parameters, seeds, stochastic traces, metrics,
gates, or analysis. The run resumes from the atomic native checkpoint in the
same result directory. The original frozen source is retained unchanged, and
the corrected files are copied to `technical_amendment_source` on resume.
