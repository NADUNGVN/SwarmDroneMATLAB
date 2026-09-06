# EXP18B — preregistered capacity-screen and abstention holdout

**Protocol status:** written before holdout opening; fresh seeds remain unused.  
**Method version:** `EXP18B-CAPACITY-SCREEN-HOLDOUT-v1`.  
**Development source:** EXP18A--A4 only.  
**Confirmatory seed block:** `16025001:16025100` (100 paired seeds).

## 1. Scientific question and claim boundary

EXP17 rejected configured MAC type as a general feedback-route selector.
EXP18A4 replaces that general claim with two narrower propositions:

1. a parameter-free analytical screen can identify registered operating cells
   whose *mean* per-node DATA service exceeds the existing AoI-rate target;
2. immediately below that screen, abstaining from standalone ACK can improve
   control error and offered load relative to adaptive standalone feedback.

The screen is causal and uses only declared swarm size, frame geometry,
configured access type, background-load setting, the stationary forward-link
success calibration and the pre-existing AoI threshold. It does not inspect
realized future loss, collisions, packet success, RMSE or safety.

The holdout does **not** test universal route optimality. In particular, an
infeasible screen value is not a claim that the observed trajectory, formation
or network must fail.

## 2. Frozen policy

The capacity-gated selector is unchanged from EXP18A4:

```text
if serviceRatio < 1:  frame-aware piggyback-only
else if MAC is CSMA:  frame-aware piggyback-only
else:                 frame-aware legacy adaptive ACK
```

Frame-aware access is fixed at

```text
CSMA:  p = min(pConfigured, 1/N)
ALOHA: p = min(pConfigured, 1/[N(2*L_DATA-1)])
```

No learned parameter, new threshold or outcome-dependent branch is allowed.
The threshold `serviceRatio = 1` comes directly from the analytical rate
comparison; it may not be moved after opening.

## 3. Provenance and opening rule

- Seeds `16025001:16025100` are disjoint from EXP12--EXP18A4.
- No smoke test, pilot, unit test or partial run may consume a holdout seed.
- Tests use synthetic inputs or a separately declared development seed below
  `16025001`.
- Before the first holdout simulation, the runner must write
  `frozen_registry.json`, `holdout_opened.json`, a source snapshot and the
  registry/source hashes into the new run directory.
- Policy, cells, outcomes, contrasts, multiplicity, safety guards and verdict
  logic freeze at opening. All negative cells and failed tests remain visible.
- A stopped or interrupted execution resumes the same run directory; it does
  not open a replacement seed block.

This document alone does not open the holdout. Opening occurs only when the
executable EXP18B runner writes `holdout_opened.json` before simulating seed
`16025001`.

## 4. Frozen matrix

The 10 EXP18A4 contexts are retained without selection:

- eight core cells: `N={5,10}`, channel `{Moderate,Stressed}`, background
  occupancy `{0,0.30}`;
- two descriptive N5 Moderate boundaries: reverse-asymmetric ACK loss and
  hidden-terminal carrier sensing.

Each context is run under CSMA and ALOHA with four paired arms:

1. `capacity-gated-selector` — proposed policy;
2. `frame-piggyback` — fixed frame-aware piggyback route;
3. `frame-adaptive` — fixed frame-aware adaptive route;
4. `legacy-selector` — the rejected MAC-only selector with legacy `1/N`
   access, retained to separate access repair from feedback abstention.

The complete matrix is `100 × 10 × 2 × 4 = 8000` simulations. One absolute
generated channel trace is shared by all four arms within a seed/context/MAC
group. Trace, channel-state and estimator hashes must match exactly.

The five screen-positive core cells are frozen from the formula, not selected
again on holdout outcomes:

| ID | Context--MAC | Development screen ratio |
|---|---|---:|
| F1 | N5 Moderate bg0 CSMA | 2.942 |
| F2 | N5 Moderate bg0 ALOHA | 1.156 |
| F3 | N5 Stressed bg0 CSMA | 2.313 |
| F4 | N10 Moderate bg0 CSMA | 1.421 |
| F5 | N10 Stressed bg0 CSMA | 1.117 |

The registered abstention boundary is N5 Stressed bg0 ALOHA, with fixed
screen ratio 0.909. It was selected because it is the closest screen-negative
core cell and remained operational in all 20 development trajectories, not
because it had the largest favorable effect.

## 5. Nine-test confirmatory family

Familywise alpha is `0.05`. All raw one-sided t-test p-values below enter one
Holm family of size nine. A missing or incomplete test cannot reject.

### H1--H5: positive-screen mean-service tests

For each F1--F5 cell and seed,

```text
serviceMargin = DATA_GOODPUT_HZ/N - 1/aoiThreshold.
```

The one-sample alternative is `mean(serviceMargin) > 0`. These hypotheses test
mean service under the registered simulator distribution. They do not assert
a per-trajectory guarantee, a deterministic lower bound or external-radio
calibration.

### H6--H7: abstention effect at the conservative boundary

At N5 Stressed bg0 ALOHA, compare candidate with `frame-adaptive` using paired
within-seed differences. Lower is better:

- H6: `mean(RMSE_candidate - RMSE_frame-adaptive) < 0`;
- H7: `mean(OFFERED_UTIL_candidate - OFFERED_UTIL_frame-adaptive) < 0`.

This isolates the feedback-route abstention because both arms use identical
frame-aware access.

### H8--H9: N10 ALOHA access repair

For each seed, first average the candidate-minus-legacy difference over the
four N10 ALOHA core contexts. Lower is better:

- H8: mean absolute `COLLISION_FRAMES` difference is below zero;
- H9: mean `OFFERED_UTIL` difference is below zero.

These are communication-layer burden hypotheses. They do not imply safe
formation behavior in the high-load cells.

All nine Holm-adjusted tests must reject in their registered directions for a
complete confirmatory verdict. Partial support is reported by hypothesis and
cannot be renamed global support.

## 6. Integrity and observed safety guards

Performance analysis is blocked unless all integrity gates pass:

- registry/source hash and pre-run opening record exist;
- exactly 8000 unique rows are complete;
- holdout seeds are exact and disjoint from every registered prior seed block;
- paired arms share exact trace/channel/estimator realizations;
- finite-output and explicit divergence accounting close;
- causal conservatism and protocol invariants hold;
- queue/history boundedness and physical recipient/airtime accounting close;
- access probabilities equal the frozen CSMA/ALOHA formulas;
- service ratios are seed-independent within context--MAC cells;
- every candidate row exactly aliases its declared fixed route on the 17
  EXP18A4 fields;
- every screen-negative candidate row emits zero standalone ACK;
- reverse-asymmetric cells retain the declared nominal-calibration mismatch.

At the H6--H7 boundary, the candidate observed safety-failure count must not
exceed either `frame-adaptive` or `legacy-selector`. This is a continuation
guard, not a population noninferiority or safety test. Raw counts and Wilson
95% intervals are reported for every arm/cell, including collapsed cells.

## 7. Estimation and descriptive analyses

- Pairing unit: seed.
- Report raw means, paired mean differences, 95% paired-t intervals and
  deterministic 10,000-resample paired percentile-bootstrap intervals.
- Bootstrap seed: `18218218`.
- Holm-adjusted p-values are inferential only for H1--H9.
- Diverged continuous pairs are excluded from their contrast and counted as
  failures; the registered test is incomplete if fewer than 100 pairs remain.
- For all 20 context--MAC cells, report predicted rate, observed per-node
  goodput, signed calibration error and whether the cell mean exceeds the
  target. Screen-negative cells are descriptive; they are never scored as
  required failures.
- Report candidate versus both fixed routes throughout the matrix, but no
  unregistered route contrast is promoted to a confirmatory claim.
- Reverse-asymmetric and hidden-terminal cells remain descriptive boundaries.

## 8. Frozen verdict logic

`SUPPORTED_WITHIN_REGISTERED_SCOPE` requires:

1. all integrity gates pass;
2. all 9/9 Holm-adjusted hypotheses reject in the registered direction;
3. the N5 Stressed bg0 ALOHA observed safety guard passes;
4. exact route aliasing and screen-negative zero-standalone behavior hold.

Otherwise the verdict is `PARTIAL_OR_NOT_SUPPORTED`; individual positive and
negative hypotheses are still reported. There is no threshold such as “most
cells pass.”

Even a supported verdict permits only the following statement:

> Within the registered abstract shared-medium cells, the analytical screen
> identifies five mean-service-positive cells, capacity-gated abstention
> improves the registered N5 Stressed ALOHA boundary relative to adaptive
> feedback, and frame-aware access reduces aggregate N10 ALOHA contention
> burden relative to the legacy selector.

It does not permit universal optimality, named-standard MAC behavior,
population safety, measured energy, adversarial ACK robustness or real-radio
validity.

## 9. Post-holdout decision

- If the complete verdict passes, proceed only to EXP15 measured-trace/radio
  bench validation. This authorizes neither flight tests nor UAV procurement.
- If any primary family component fails, retain the result and stop automatic
  hardware progression. No retuning or replacement holdout is allowed.
- Hardware remains deferred while this protocol is unopened.
