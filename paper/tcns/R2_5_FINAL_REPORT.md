# R2.5 adversarial hardening report

Date: 2026-09-08

Branch: `paper-v3-tcns`

Pushed R2 snapshot: `c1538ae8045cfdc8053ef7196e02c2a0eabc23be`

R2.5 implementation commit: `edad129`
Authoritative R2.5 artifact commit: `4ef8a477cdeb839ad814be2d01f0b77083b474f4`

No R3 study, scheduler, acquisition protocol, held-out evaluation, or registry
expansion was performed.

## 1. Files changed

Implementation and tests:

- `utils/tcnsR2RegistryConfiguration.m`
- `utils/tcnsInformationLimitsReplayWitness.m`
- `utils/tcnsR25ValidateWitnessPair.m`
- `utils/tcnsR25AdversarialAudit.m`
- `experiments/tcns_r2_5_adversarial_validation.m`
- `tests/test_tcns_r2_5_persisted_witness_replay.m`
- `tests/test_tcns_r2_5_adversarial_artifact.m`

Audit/report layer:

- `paper/tcns/R2_5_CLAIM_EVIDENCE_AUDIT.md`
- `paper/tcns/R2_5_REGISTRY_RANK_AUDIT.md`
- `paper/tcns/R2_5_WITNESS_NORMALIZATION_AUDIT.md`
- `paper/tcns/R2_5_MANUSCRIPT_LANGUAGE_AUDIT.md`
- `paper/tcns/R2_5_NOVELTY_STRESS_TEST.md`
- `paper/tcns/R2_5_FINAL_REPORT.md`
- `paper/tcns/GM_CLAIM_EVIDENCE_LEDGER.md`
- `paper/tcns/GM_REVIEWER_RISKS.md`
- `paper/tcns/manuscript/{README,REPRODUCIBILITY}.md`
- `ARTIFACT_README.md`

Scientific manuscript:

- `paper/tcns/manuscript/tcns_information_limits.tex`

Generated evidence:

- `results/tcns_r2_5_adversarial_validation/2026-09-08_175427/`
- `results/tcns_r2_5_adversarial_validation/LATEST.txt`
- `results/INDEX.md`

Earlier R2.5 runs are preserved rather than hidden: `173845` and `173921`
are explicitly invalid, and `174125` is labeled development-only.

## 2. New functions

`tcnsR2RegistryConfiguration` reconstructs one exact frozen R2 cell from its
declared identifiers.  `tcnsInformationLimitsReplayWitness` independently
rebuilds plant/receiver state from persisted coordinates and replays the
implemented controller and dynamics.  `tcnsR25ValidateWitnessPair` applies
the independent acceptance and fixed-response checks.  The orchestrator
`tcnsR25AdversarialAudit` reconstructs the registry, emits tolerance/rank
diagnostics, replays persisted witnesses, audits three normalizations, and
exhaustively recomputes coalition results.

## 3. New tests

`test_tcns_r2_5_persisted_witness_replay` replays all ten actions and includes
negative controls: an intentional sender-information mismatch and an
intentional action-response mismatch must both be rejected.
`test_tcns_r2_5_adversarial_artifact` checks exact row counts, absence of
silent exclusions, projection conclusions, selected VPA agreement, witness
acceptance, normalization completeness, and exhaustive coalition validity.
Both tests resolve evidence paths from their own source location, so they also
pass when the caller changes MATLAB's working directory.

## 4. New experiment and artifacts

The new study is an adversarial audit of the already declared R2 registry,
not an expansion study.  The authoritative directory contains:

- 72-row registry construction/exclusion audit;
- 6600-row action-by-tolerance rank/projection audit;
- selected 80-digit fragile-case diagnostics;
- ten-row independent actual-witness replay in CSV and JSON;
- ten-row normalization sensitivity audit;
- 448-row exhaustive coalition audit and its compact distribution;
- `workspace.mat`, provenance JSON, source snapshot, and console log.

## 5. Test results

The following all pass in MATLAB R2025a:

- `test_tcns_information_limits`
- `test_tcns_r1_theory_depth`
- `test_tcns_r2_generalization`
- `test_tcns_actual_witness_audit`
- `test_tcns_r2_5_persisted_witness_replay`
- `test_tcns_r2_5_adversarial_artifact`
- `test_lock_regression`

MATLAB Code Analyzer reports zero findings on all seven new implementation,
experiment, and test files.  The locked regression first fell back to serial
when a process pool failed to start, later connected to 16 workers, and
completed with PASS; all locked numerical targets were reproduced.

## 6. Registry/generalization result

The exact Cartesian registry has 72/72 feasible cells: N in {5,7,9}, three
predeclared deterministic graph families, two parity pin sets, H in {15,25},
and D in {2,4}.  It contains 1320 action functionals.  There are zero
`MODEL_INFEASIBLE`, zero `SCIENTIFIC_RESULT_EXCLUDED`, and zero silent
exclusions.  Every action is projection-nonidentifiable at all five declared
tolerances, hence 6600/6600 diagnostic rows are nonidentifiable.

What appears robust is recurrence over this finite registry and tolerance
grid.  What changes is raw numerical rank, sender-wise compression, and
coalition ownership.  This remains finite-registry evidence; no arbitrary-N,
arbitrary-topology, or arbitrary-gain theorem is claimed.

## 7. Actual-witness coverage

- Structural nonidentifiability: 10/10 frozen N=5 controller-relevant actions.
- Actual controller response tested: 10/10.
- Dynamically reachable, unsaturated, opposite-sign witnesses: 10/10.
- Failures: none (`failureReason=NONE` for every row).

The independent replay's maximum sender-information mismatch is
`7.98e-20`, maximum dynamic residual `4.17e-16`, maximum affine/oracle value
mismatch `4.07e-20`, and minimum saturation margin `0.952`.  The smallest
absolute value endpoint is `8.52e-8`, more than `8.5e4` times the sign
tolerance, so sign crossing is not a numerical-noise artifact.

## 8. Fixed-response consistency

All 10/10 witness pairs preserve the actual 0.01 m/s2 controller correction,
finite-horizon response, target indices and values, payload/packet semantics,
unsaturated controller branch, and horizon.  Response mismatch is exactly
zero in the saved audit.  Direct values are recomputed using
`tcnsCentralizedStateOracleValue`; the affine construction is not reused as
the only sign check.  Deliberate corruption of either sender history or the
response is rejected by the replay test.

## 9. Practical-normalization sensitivity

The primary normalization is information radius divided by the median
absolute exact value from 32 deterministic unsaturated reference states per
action.  Across ten actions it spans `2.67e-4` to `0.2315` (median `0.0109`).
Using RMS and IQR/1.349 scales changes the maxima to `0.1446` and `0.1752`.
Thus the largest value is partly denominator-sensitive; it is not reported in
isolation.  The two weakest actions remain order `1e-4` under all three
normalizations.  The ambiguity result is formal and heterogeneous, not a
population-level performance claim.

## 10. Coalition distribution

Independent exhaustive enumeration reproduces all 448 sender-cell minima.
All minima are unique within the registry.

| Minimum coalition size | Frequency | Fraction |
|---:|---:|---:|
| 5 | 120 | 0.2679 |
| 7 | 120 | 0.2679 |
| 8 | 56 | 0.1250 |
| 9 | 152 | 0.3393 |

Conditioned on N: all 88 N=5 rows require 5; N=7 has 32/152 rows requiring 5
and 120/152 requiring 7; N=9 has 56/208 requiring 8 and 152/208 requiring 9.
Coalition size is kept distinct from hidden-statistic dimension, packet
count, payload bits, and acquisition cost.

## 11. Claims weakened or qualified

No core scientific claim failed, but three phrasings required correction:

1. “Appending the value row increases rank for all 1320” is valid only after
   orthonormalizing the retained row space and normalizing the value row.  Raw
   augmented-rank bookkeeping is explicitly reported as threshold-sensitive.
2. The maximum normalized ambiguity 0.232 is now accompanied by RMS/IQR
   sensitivity and the small order-1e-4 cases.
3. The frozen R2 `summary.seed` field is incomplete metadata: registry seed is
   27022001, witness scenario seed is 27020001, and normalization streams use
   27022001 plus action index.  The deterministic witness result is unchanged.

## 12. Claims strengthened

The frozen N=5 all-action witness statement now has independent persisted
replay, direct centralized value recomputation, explicit fixed-response
semantics, negative-control tests, and large sign-to-tolerance margin.  The
finite-registry statement now has an independent 6600-row reconstruction,
zero-exclusion audit, selected VPA attack, and explicit separation between
projection membership and raw rank.  The topology dependence of coalition
ownership is now quantified rather than described qualitatively.

## 13. Remaining novelty risk

The work uses classical functional-observability and row-space tools.  Its
novelty must therefore rest on the combined control-communication chain:
the exact communication-action value as the target functional, reachable
sign ambiguity and local minimax decision loss, simultaneous-action hidden
dimension, distributed ownership, and feedback economics.  A reviewer who
requires a new standalone observability primitive may still regard the paper
as an application/synthesis contribution.

## 14. Remaining technical risk and strongest reviewer attack

The smallest registry projection residual is only 3.029 times the loosest
declared tolerance.  Selected 80-digit checks agree, but this is a numerical
margin rather than a symbolic lower bound.  The strongest remaining attack is
therefore: the 1320/1320 recurrence may be largely induced by this architecture
and registry, while generalization beyond it is not proved.  The correct
response is the paper's finite-registry wording and the general conditional
theorems, not another favorable sweep.

## 15. Manuscript locations changed

- Table II caption and Sec. VIII-A: scale-controlled projection versus raw
  rank; independent 6600-row audit.
- Sec. VIII-B: independent ten-action replay, fixed-response checks, sign
  margin, and normalization sensitivity.
- Sec. VIII-C: 448-row coalition-size distribution and no cost inference.
- Sec. IX: numerical-margin limitation.
- Reproducibility appendix: authoritative R2.5 path and exact seed split.

No main scientific figure or frozen data source was modified.  Detailed rank,
witness, and normalization rows remain in machine-readable artifacts rather
than consuming main-paper columns.

## 16. Git and PDF status

The accepted R2 snapshot was pushed unchanged as
`c1538ae8045cfdc8053ef7196e02c2a0eabc23be`; R2.5 remains a separate local
review layer pending coauthor review.  The final local report commit is
reported in the coauthor handoff because a commit cannot contain its own SHA.

Tectonic compiles `paper/tcns/manuscript/tcns_information_limits.pdf` in
11 pages.  Main text ends and Appendix A begins on page 10; the complete PDF
is within the 12-page budget.  The abstract has 282 words.  The final log has
zero LaTeX errors, undefined references/citations, overfull boxes, or multiply
defined labels.  Independent extraction confirms all 28 used font resources
are embedded.  All 11 rendered pages were inspected; figures, tables, text,
and references are readable and uncropped.  PDF SHA-256:
`E9FC02FA03C54A54C162D35C0818FDE8886CFC131ADF69FB1A96B3FDB09E20BD`.
