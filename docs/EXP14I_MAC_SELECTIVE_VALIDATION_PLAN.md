# EXP14I preregistered MAC-selective feedback validation plan

## Scientific question

EXP14E--H expose a feedback-mode reversal rather than a universal ACK rule.
Piggyback-only is better under N5/N10 CSMA, the selected adaptive standalone
mode is better under N5 ALOHA, and the N20 adaptive policy already invokes
standalone service too rarely for a supported per-decision estimate. EXP14I
tests whether one observable, categorical context variable—the configured MAC
type—can select the appropriate feedback route on entirely new traces.

The frozen mapping is

| MAC type | Selected feedback route |
|---|---|
| p-persistent CSMA | piggyback-only |
| slotted ALOHA | adaptive standalone + piggyback |

Both routes retain analytical access scaling `pAccess=min(pConfigured,1/N)`
and disable the failed fixed load guard. The selector does not inspect queue,
AoI, control error, realized loss, collision or outcome. It is deliberately a
two-branch policy, not a fitted per-decision predictor.

## Provenance boundary

- Version: `EXP14I-MAC-SELECTIVE-HOLDOUT-v1`.
- Design source: completed EXP14E--H development evidence.
- New holdout seeds: `16021001:16021100`.
- The seed block is disjoint from EXP14, EXP14C--H and all diagnostic seeds.
- Opening the holdout freezes mapping, cells, arms, metrics, multiplicity,
  safety guard and code snapshot.
- No parameter, route or hypothesis may change after the first holdout run.
- Negative cells and failed hypotheses remain in the report.

## Frozen matrix

Four cells are retained:

1. N5 CSMA Moderate;
2. N10 ring2 CSMA;
3. N20 ring2 CSMA, mandatory sparse boundary;
4. N5 ALOHA at configured access 0.20.

Every seed/cell uses one absolute generated trace for four paired arms:

1. `mac-selective-scaled`;
2. `fixed-adaptive-scaled`;
3. `fixed-piggyback-scaled`;
4. `access-only-scaled`.

The matrix contains `100 × 4 × 4 = 1600` simulations. The candidate is an
exact configuration alias of fixed piggyback in each CSMA cell and of fixed
adaptive in ALOHA. Both the alias identity and the comparison against the
opposite route are audited. The candidate is not claimed as a new within-cell
algorithm; the contribution being tested is the frozen cross-MAC selector.

## Confirmatory family

Lower is better. The six one-sided paired hypotheses are:

- N5 CSMA: candidate lower than fixed adaptive on RMSE and offered utilization;
- N10 CSMA: candidate lower than fixed adaptive on RMSE and offered utilization;
- N5 ALOHA: candidate lower than fixed piggyback on RMSE and offered
  utilization.

Raw paired t-test p-values are adjusted together by Holm at familywise
`alpha=0.05`. Each cell is supported only when both adjusted tests reject in
the registered direction and the observed candidate safety-failure count does
not exceed its registered opposite-route comparator. The safety condition is
an observed guard, not a population safety test.

The global mapping claim is supported only if all six tests and all three cell
guards pass. Partial support and complete failure are retained verbatim.

## N20 boundary

N20 is not part of the confirmatory family. Candidate equals the frozen
piggyback route there. Differences against adaptive and access-only receive
paired descriptive intervals and raw safety counts only. No equivalence,
per-decision causal value, or population safety claim is permitted. This
preserves the EXP14G/H support failure instead of hiding it inside a larger
matrix.

## Estimation and integrity

- Report paired mean differences, 95% paired t intervals and deterministic
  10,000-resample paired bootstrap intervals.
- Pairing unit is seed; diverged pairs are excluded from continuous contrasts
  and counted explicitly as failures.
- Required integrity gates include registry hash, complete/unique matrix,
  common trace/channel realization, causal conservatism, bounded memory,
  physical accounting, access semantics, exact route semantics, exact
  candidate/reference alias outcomes, finite eligible outputs and divergence
  accounting.
- Performance analysis opens only after every integrity gate passes.

## Claim ceiling

EXP14I may claim validation of the registered selector within these four
simulated cells. It may not claim universal MAC optimality, N20 standalone-ACK
value, security robustness, hardware energy savings, or real-radio validity.
Those require new MAC families and EXP15 trace/radio/HIL evidence.
