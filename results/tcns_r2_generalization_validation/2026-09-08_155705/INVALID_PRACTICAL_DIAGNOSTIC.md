# Invalid practical-scale diagnostic (retained)

The structural generalization tables and the ten actual-action witness
constructions in this run passed their declared checks. They are retained as
the first complete R2 execution.

The practical-scale columns `referenceValidCount`,
`referenceMedianAbsValue`, `normalizedAmbiguity`,
`compatibleIntervalCrossingFraction`, and
`localCentralizedSignDisagreementRate` must **not** be used:

- all ten actions had `referenceValidCount = 0` because the mixed-coordinate
  radius `0.05` was incorrectly applied to `h*w` as though it were velocity;
- the displayed finite `normalizedAmbiguity` values are a reporting bug caused
  by division through `eps` after the median was `NaN`;
- no practical-scale scientific conclusion is drawn from these columns.

The dimensional correction was preregistered as an explicit amendment in
`paper/tcns/R2_GENERALIZATION_WITNESS_PROTOCOL.md` before the replacement run.
The invalid run is preserved rather than silently removed.
