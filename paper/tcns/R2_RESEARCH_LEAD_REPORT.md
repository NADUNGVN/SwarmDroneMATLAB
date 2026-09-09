# R2 research-lead report: generalization and actual-action witnesses

## Decision

`R2_EVIDENCE_STRENGTHENED_WITH_QUALIFICATIONS`

The two requested reviewer vulnerabilities are materially reduced:

1. the structural observation now recurs in a preregistered 72-cell,
   1320-action registry spanning N=5/7/9 and several graph/pin/H/D choices;
2. dynamically reachable actual-action opposite-sign witnesses now cover all
   ten actions in the frozen N=5 model rather than only two leader examples.

This remains a finite-registry numerical study plus an N=5 reachable-witness
closure. It is not an arbitrary-graph theorem, a scheduler, or evidence for a
causal missing-statistic acquisition protocol.

Authoritative result directory:
`results/tcns_r2_generalization_validation/2026-09-08_161130/`.

## 1. Files changed

Pre-experiment audit and protocol:

- `paper/tcns/REVIEWER_RISK_AUDIT.md`
- `paper/tcns/R2_GENERALIZATION_WITNESS_PROTOCOL.md`

Implementation and tests:

- `utils/tcnsInformationLimitsActionCatalog.m`
- `utils/tcnsR2GeneralizationAudit.m`
- `utils/tcnsInformationLimitsActualWitnessAudit.m`
- `experiments/tcns_r2_generalization_validation.m`
- `tests/test_tcns_r2_generalization.m`
- `tests/test_tcns_actual_witness_audit.m`

Reports and artifact routing:

- `paper/tcns/R2_GENERALIZATION_WITNESS_REPORT.md`
- `paper/tcns/R2_RESEARCH_LEAD_REPORT.md`
- `ARTIFACT_README.md`
- `results/INDEX.md`
- two timestamped R2 result directories and `LATEST.txt`

Manuscript/evidence layer:

- `paper/tcns/manuscript/tcns_information_limits.tex`
- `paper/tcns/manuscript/make_gm_figures.m`
- six reproducibly regenerated figure pairs; only Figure 6 changes scientific
  content
- compiled manuscript PDF and compile log
- manuscript README and reproducibility guide
- claim-evidence ledger and reviewer-risk register

Frozen simulation-v1 source and result histories were not modified.

## 2. New functions

### `tcnsInformationLimitsActionCatalog`

Creates a complete, stable catalog of ordinary and pinned-leader actions backed
by `tcnsInformationLimitsActionMap`. Its default `[1 0 0]` correction is
explicitly labeled structural, not trajectory-realized.

### `tcnsR2GeneralizationAudit`

Builds the Cartesian deterministic registry, tests full finite-history
row-space membership, cross-checks compressed-null and direct calculations,
sweeps rank tolerance, computes sender-wise `r_j*`, exhaustively enumerates
coalitions up to N=9, and performs selected 80-digit projection checks.

### `tcnsInformationLimitsActualWitnessAudit`

For every N=5 action, constructs a real controller correction, enforces held
target memory, full sender-history equality, actual-response equality, and
consistent initial dynamics; projects the value gradient into the admissible
hidden subspace; replays both trajectories through the controller/integrator;
and checks the affine value against the independent centralized computation.

## 3. New tests

- `test_tcns_r2_generalization.m`: action/tolerance row counts, dimensions,
  `r_j* <= p_j`, direct/compressed agreement, augmented-rank bounds, VPA
  completion, repeatability, actual minimum-coalition verification, and
  persisted CSV/JSON consistency.
- `test_tcns_actual_witness_audit.m`: no missing action, explicit failure
  reason, sign crossing for successes, sender-history equality, direct dynamic
  replay, actual-response equality, oracle agreement, and saturation margin.

The tests verify invariants; they do not require nonidentifiability or witness
success merely to force a favorable scientific result.

## 4. New experiments and artifacts

The new experiment is
`experiments/tcns_r2_generalization_validation.m`. It writes:

- configuration registry CSV;
- 1320-row action CSV and JSON;
- 6600-row tolerance-grid CSV;
- sender-wise multi-action/coalition CSV;
- selected VPA CSV;
- ten-action witness CSV and JSON;
- MAT workspace, summary JSON, source snapshot, meta JSON, and console log.

The first run `2026-09-08_155705` is preserved. Its structural and witness
results passed, but its practical diagnostic mixed units in `[e;h w]` and has
zero unsaturated reference states. It is explicitly invalidated, not deleted.
The dimensional amendment was written before the replacement run. The
authoritative run is `2026-09-08_161130`, generated from commit `a2cec3b`.

## 5. Test results

All required checks passed:

- `test_tcns_r2_generalization`: PASS;
- `test_tcns_actual_witness_audit`: PASS;
- existing `test_tcns_information_limits`: PASS;
- existing `test_tcns_r1_theory_depth`: PASS;
- full `test_lock_regression`: PASS, including locked EXP05C/EXP06A/EXP07A
  values, trace identity, and ACK causality checks;
- MATLAB Code Analyzer: zero messages on the three new utilities, experiment,
  and two new tests after cleanup;
- `git diff --check`: PASS.

PDF QA after manuscript update:

- compile: PASS with Tectonic 0.17.0;
- pages: 11 total; appendix begins on page 10, so main text is 9 pages;
- abstract: 282 words;
- undefined references/citations: zero;
- overfull boxes: zero;
- embedded font programs: 15/15;
- every page and revised Figure 6 visually rendered and inspected.

## 6. Results of the generalization study

### Robust observations

- admissible theorem-scope cells: 72/72;
- unit-response functional nonidentifiability: 1320/1320 action rows;
- membership conclusion stable from relative tolerance `1e-6` through
  `1e-14`: 1320/1320;
- compressed-null/direct-row-space agreement: 1320/1320;
- appended value row increases rank by one: 1320/1320;
- selected 80-digit checks: 72/72 successful, minimum normalized residual
  `3.0291e-6`;
- every full coalition identifies every sender-wise target set.

Leader action sets share hidden directions throughout the registry. Depending
on graph/N, `r_1*/p_1` is 2/3, 5/7, 3/4, 4/5, or 5/6. Every tested follower
sender has `r_j*=p_j`.

### Heterogeneity and counterevidence

- raw numerical information-map rank is stable for only 608/1320 rows. Small
  singular modes cross extreme cutoffs even though value membership does not;
  this must remain disclosed.
- all-agent ownership is not topology universal. Ring2 and sparse4 require
  all N agents for every sender. Geometric N=7 follower sets require 5/7,
  and geometric N=9 follower sets require 8/9; the leader still requires all.
- no counterexample to exact unit-response row-space nonidentifiability was found in the finite
  registry, but that absence is not a proof for arbitrary graphs or gains.
- pinning, H, and D did not change the categorical conclusions in the tested
  cells; this is recurrence evidence, not invariance theorem.

## 7. Actual-witness coverage

- structural actions nonidentifiable: **10/10**;
- actual action responses constructed and tested: **10/10**;
- dynamically reachable opposite-sign witnesses: **10/10**;
- failures: **none** (`failureReason=NONE` for every action).

The strongest replay residuals are:

- sender observation: `7.980e-20`;
- dynamic reachability: `4.163e-16`;
- actual response: `0`;
- affine vs independent centralized value: `4.066e-20`;
- minimum saturation margin: `0.9521 m/s2`.

Practical scale is not uniform. Normalized ambiguity ranges from 0.0002666 to
0.2315. Seven actions cross zero somewhere on the selected 32-state local
grid; three do not. Sender-projection sign disagreement is nonzero for nine;
ordinary 4->5 has zero disagreement on that grid. These descriptive fractions
are not population estimates.

## 8. Claims that can now be strengthened

- The structural mechanism recurs across 1320/1320 declared action instances,
  not only one N=5 matrix.
- All ten N=5 actions, not merely two leader payloads, possess directly replayed
  actual-action opposite-sign reachable witnesses.
- Sender diversity is now covered in N=5: leader and follower senders both have
  actual-action witnesses.
- Leader action-value deficits share missing directions across every tested
  topology/N, while follower action sets do not in the registry.
- The implementation/manuscript adjacency-matrix mismatch is corrected: the
  analytical leader's unused incoming row is zero in actual code.

## 9. Claims that must be weakened or qualified

- Do not say dynamic sign ambiguity holds for all R2 actions or arbitrary N;
  10/10 is the frozen N=5 catalog only.
- Do not say all topologies need all agents; geometric follower cases are
  strict counterexamples.
- Do not say numerical rank itself is tolerance-stable for all rows; only the
  row-space membership decision is.
- Do not infer practical importance solely from witness existence; two actions
  have normalized radius below `3.5e-4`.
- Do not interpret 32 deterministic states as a statistical population.
- Do not equate one missing scalar with one packet, bits, data rate, or causal
  acquisition cost.
- The ACK-like figure remains an accounting sensitivity diagnostic, not a
  deployable protocol measurement.

## 10. Remaining TCNS reviewer risks

1. The 72-cell result is numerical recurrence, not arbitrary-graph theory.
2. The row-space core remains a functional-observability specialization; paper
   depth still rests on action-value decision consequences and co-design.
3. Actual-action 10/10 coverage is limited to unsaturated N=5 double-integrator
   histories with one correction magnitude and fixed H/D.
4. Practical ambiguity varies by almost three orders of magnitude.
5. Selected VPA begins from implementation-generated double matrices rather
   than exact rational arbitrary-parameter matrices.
6. Coalition ownership does not implement robust distributed aggregation.
7. Packet-frequency economics omits bytes, airtime, MAC, collision, and energy.
8. Bayesian prior-specific conditional decisions and nonlinear observers remain
   outside scope.
9. No 6-DOF/nonlinear or switching-within-history theorem is claimed.
10. The updated 11-page PDF still contains human author-metadata placeholders.

## 11. Manuscript sections, tables, and figures modified

- Abstract: adds finite-registry and 10/10 actual-action evidence.
- Introduction contribution 4: replaces N=5/two-witness scope with the exact
  R2 hierarchy.
- Section III-A: corrects the literal N=5 adjacency matrix to match code.
- Section VIII-A: becomes cross-instance structural validation.
- Table II: replaces the ten-link-only rank table with nine graph/N aggregate
  rows while retaining tolerance and coalition qualifications.
- Section VIII-B and Table III: report all ten actual-action witnesses and
  practical-scale heterogeneity.
- Figure 6: replaces two representative time traces with ten endpoint pairs
  and normalized-radius diagnostics.
- Section VIII-C: adds coalition heterogeneity beyond N=5.
- Discussion/limitations and conclusion: explicitly separate finite-registry,
  within-N=5 dynamic, and topology-dependent claims.
- Appendix C and reproducibility documentation: add authoritative R2 routing.
- Internal development labels are reduced in external-facing captions/prose.

No theorem statement or proof was changed in this round.

## 12. Git diff summary

The round starts at accepted QA commit
`9d9212e134c9e2cae3bbdb0f79d918d3560e5359` and uses isolated commits:

- `253b99b`: pre-modification reviewer-risk audit and preregistration;
- `a2cec3b`: implementation, tests, first retained run, dimensional amendment;
- `f6baa19`: authoritative replacement artifact and results report;
- manuscript/reproducibility update: committed separately after this report.

Most line volume comes from machine-readable JSON/CSV result artifacts. The
scientific source delta consists of three utilities, one experiment, two tests,
audit/protocol/reports, and evidence-scoped manuscript updates. No existing
experiment history was rewritten or squashed.
