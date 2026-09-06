# EXP14E — Preregistered holdout of adaptive ACK with scaled access

## 1. Frozen status

EXP14E is a new 100-seed holdout for the candidate selected by the complete
EXP14D development factorial. It does not modify or append EXP14A--D. The
holdout seeds are `14015001:14015100`; no test or smoke run may consume them.

The registry, arm mapping, cell mapping, integrity gates, primary hypotheses,
multiplicity correction and reporting rules must be executable and hash-locked
before `holdout_opened.json` is written. After opening, no policy parameter,
seed, cell, comparator, exclusion rule or hypothesis may change.

The frozen registry has `configHash=87778193` over 58 leaves. Seed-zero base
cell hashes are N5 CSMA `104373580`, N10 `113322136`, N20 `139133994`, and N5
ALOHA `104814180`.

## 2. Frozen candidate and comparators

The proposed candidate is EXP14D arm `a1-g0-s1`:

- local-busy adaptive cumulative ACK;
- branch load guard disabled;
- `p=min(p_configured,1/N)`;
- all trigger and ACK thresholds unchanged from EXP14C/D.

Seven fixed arms run on every paired seed/cell trace:

1. selected adaptive ACK + scaled access;
2. access-only causal hybrid ACK + scaled access;
3. historical frozen causal hybrid (`p=0.2` at every N);
4. causal piggyback-only + scaled access;
5. state-event default threshold + scaled access;
6. delayed-ACK belief default threshold `0.12 s` + scaled access;
7. Periodic-P10 + scaled access.

The historical hybrid is retained only as continuity with EXP14 and is not the
fair contemporary comparator at N10/N20. Access-only is the primary comparator.
State-event, delayed belief and P10 prevent a self-ablation-only evaluation.
Every nonhistorical arm uses the same access-scaling rule.

## 3. Frozen cells and run count

All cells use the frozen Moderate Gilbert--Elliott DATA/ACK channel and the
four-slot abstract PHY:

1. N5 ring2, fully sensed CSMA, 6-DOF — primary;
2. N10 ring2, fully sensed CSMA, double integrator — primary;
3. N20 ring2, fully sensed CSMA, double integrator — primary;
4. N5 ring2, slotted ALOHA, 6-DOF — mandatory boundary.

Every seed/cell draws one absolute plant/channel/MAC-uniform trace before any
arm is applied. The matrix contains `100 × 4 × 7 = 2,800` runs.

## 4. Confirmatory hypotheses

The independent experimental unit is the paired seed. For each of the three
CSMA cells, compare selected minus access-only on two co-primary outcomes:

- RMSE;
- offered airtime utilization.

This produces six one-sided paired-t hypotheses with alternative
`mean(selected-access) < 0`. Holm correction controls familywise alpha at
`0.05` across all six tests. A CSMA cell supports the proposed trade-off only
when both Holm-adjusted tests reject and all 100 registered pairs are usable.

Observed safety is an additional claim guard, not a proof of population
noninferiority: selected must have no more observed safety failures than
access-only in each primary cell. The overall confirmatory claim is supported
only if all three cells pass both continuous tests and this observed-safety
guard.

Mean true AoI, collision count, DATA/ACK attempts, channel utilization and all
candidate comparisons against the other five arms are secondary. Their
paired-t and deterministic paired-bootstrap intervals are descriptive and
unadjusted.

## 5. Boundary and negative-result rules

ALOHA is excluded from the confirmatory family because development already
showed an adverse mean direction. It must nevertheless run all seven arms and
report identical outcomes, intervals and safety denominators. No universal
MAC claim is permitted, even if the ALOHA result happens to favor the candidate.

Divergence and safety failure are retained outcomes. A divergent pair is
removed only from the affected continuous contrast, with requested/usable/
dropped counts exposed. Seeds are never added because an interval is wide or
unfavorable.

## 6. Inference and safety reporting

- paired two-sided 95% t intervals for effect size;
- deterministic 10,000-resample paired percentile bootstrap as sensitivity;
- one-sided paired-t p-values and Holm adjustment only for the six frozen
  primary tests;
- raw failure numerator/100 and Wilson 95% intervals for every arm/cell;
- paired safety improved/worsened/equal counts for candidate versus every
  comparator.

No p-value from a secondary comparison is promoted into the primary family.

## 7. Integrity gates

Integrity, never favorable performance, decides whether the run is valid:

- frozen registry hash and exact run count;
- one row per seed/cell/arm and one complete seven-arm group;
- one absolute trace and channel-state realization per seed/cell;
- causal conservatism and zero protocol invariant violations;
- bounded queue/history and terminal DATA/ACK accounting;
- declared method/feedback/access semantics for every arm;
- candidate has adaptive ACK, disabled guard and zero guard suppressions;
- channel utilization and local-busy estimates remain bounded;
- divergences are binary, retained and counted as safety failures.

No RMSE, AoI, load, collision or safety value is an integrity pass gate.

## 8. Claim boundary

Even a positive result is limited to the abstract shared-medium simulator,
declared topology/traffic/plant cells and selected thresholds. EXP14E cannot
validate a named MAC standard, measured radio energy, adversarial ACK security,
hardware timing or flight behavior. Those remain EXP15 tasks.
