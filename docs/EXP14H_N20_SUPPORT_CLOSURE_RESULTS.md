# EXP14H N20 causal-support closure results

## Verdict

EXP14H stopped at its frozen preflight gate, as required. The run
`results/exp14h_n20_support_closure/2026-08-31_001447` completed all 240 new
N20 pilot simulations (`16020001:16020240`) and recorded 277 permitted
standalone-ACK decisions. Only eight decisions were inside the registered
post-transient/full-window eligibility interval, and they came from seven
distinct parent seeds. Outcome-blind selection therefore locked seven target
events (selection hash `82431794`), below the preregistered minimum of 12.

The verdict is **FAIL-selection-support**. No admit/suppress replay was run, no
causal outcome row was generated, no eligibility rule was relaxed, and no
threshold or predictor was fitted. This result does not alter or repair the
EXP14G verdict.

## Frozen-design audit

| Item | Frozen value | Observed |
|---|---:|---:|
| N20 pilot seeds | 240 | 240 complete |
| Eligibility start | 8 s | unchanged |
| Local outcome horizon | 0.75 s | unchanged |
| Target / minimum distinct seeds | 20 / 12 | 7 |
| Permitted candidate decisions | -- | 277 |
| Eligible candidate decisions | -- | 8 |
| Selected decisions | -- | 7 |
| Outcome replay pairs | only if support passes | 0 |

The design lock has registry hash `142973713` over 25 leaves. The selection
lock records `outcomesInspected=false`, `selectionChangedAfterPilot=false`, and
`predictorFittingPermitted=false`. The machine-readable preflight verdict is
in `preflight_gates.csv` in the run directory.

## Combined support audit, without outcome pooling

The independent EXP14G N20 block supplied four distinct eligible parent seeds
from 60 pilots; EXP14H supplied seven from 240. Because the seed ranges are
disjoint, the registered event process appeared in

\[
\widehat p_{support}=\frac{4+7}{60+240}
=\frac{11}{300}=0.0367.
\]

The two-sided 95% Wilson interval is [0.0206, 0.0645]. This calculation pools
only the binary fact that a seed supplied at least one eligible event. EXP14H
has no replay outcomes, so no causal lead, airtime, AoI, or control effect is
pooled with EXP14G.

The observed rate is evidence of a **practical positivity/overlap failure for
the registered finite design**: under the selected N20 policy, a
post-transient standalone-ACK opportunity with a complete local window is too
rare to support the frozen per-decision analysis. It is not proof that the
population probability is exactly zero, and it is not an effect estimate.

## Mechanism conclusion

The support failure is itself informative. Under N20 ring2 CSMA and scaled
access, the selected adaptive policy already behaves almost like a
piggyback-only policy after the transient. This agrees with EXP14E, where the
policy averaged only 1.1 standalone-ACK frames per run and its continuous
difference from piggyback-only was unresolved.

Running seeds indefinitely or moving the eligibility window after seeing this
result would change the estimand and invite a misleading conclusion. The N20
entry therefore remains a sparse boundary:

- no N20 per-decision causal ACK-value claim;
- no equivalence claim from a nonsignificant full-policy contrast;
- no extrapolation of the N5/N10/ALOHA branch effects to N20;
- no fine-grained ACK predictor fitted from the sparse development events.

The defensible next design is categorical and interpretable: use
piggyback-only feedback in CSMA cells, where standalone ACK is adverse or
unnecessary, and retain adaptive standalone feedback in ALOHA, where the
aggregate MAC reversal remains favorable. EXP14I subsequently froze that
mapping and validated all six registered error/load hypotheses on 100 disjoint
seeds per cell. This later validation does not change the N20 support failure.

## Artifacts

- Plan: `docs/EXP14H_N20_SUPPORT_CLOSURE_PLAN.md`.
- Pilot and selected-event tables: `pilot_runs.csv`, `pilot_candidates.csv`,
  and `selected_events.csv` in the run directory.
- Locks: `design_locked.json`, `frozen_registry.json`, and
  `selection_locked.json`.
- Preflight verdict: `preflight_gates.csv`.
- Frozen implementation snapshot: `frozen_source/`.
