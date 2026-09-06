# EXP14G branch-at-decision causal ACK replay results

## Verdict and provenance

EXP14G completed 240 pilot runs, recorded 27,658 permitted ACK decisions,
locked 64 outcome-blind target events (selection hash `788188353`), and
completed 64 actual/shadow branch pairs. The run is
`results/exp14g_branch_at_decision/2026-08-30_235146`.

The original integrity verdict is **FAIL-selection-support**, not PASS. Thirteen
of fourteen gates pass: complete pilot/replay matrices, deterministic selection,
identical pre-decision network and plant/controller hashes, exact intervention
semantics, finite outcomes, zero divergence/protocol violations, valid lead
censoring and an airtime-identity residual below (1.11\times10^{-15}) s. The
failed gate is the frozen minimum of 12 decisions per cell: N5, N10 and ALOHA
each supply 20 decisions from 20 distinct seeds, but N20 supplies only four.

No minimum was lowered, no event was added after seeing outcome and no predictor
was fitted. `analyzeExp14GSupportLimited.m` reports the three independently
supported cells while preserving N20 as a raw sparse boundary. This audit does
not change the original FAIL-support verdict and permits no confirmatory claim.

## Recovery amendment caught by the identity gate

The first replay attempt wrote zero outcome rows. It shortened
`cfg.swarm.T` to the local endpoint; MATLAB's colon time grid then differed by
approximately machine precision, and an event trigger eventually crossed a
different boundary before the target. The target entry/state hashes rejected
the replay.

Before recovery, the locked selection remained unchanged and no performance
outcome had been inspected. The corrected replay retains the full 12 s grid in
both branches and reads cumulative/local outcomes at the first frozen control
tick after 0.75 s. A late-event regression verifies the repair. The exact
amendment and corrected source snapshot are stored in
`replay_recovery_amendment.json` and `recovery_source/`.

This is a useful reproducibility finding: “same start, same trace” is not enough
for causal replay when changing an endpoint perturbs floating time-grid values.
The complete pre-decision state hash is necessary.

## Causal lead and local effect in supported cells

Each target is one aggregate standalone-ACK decision. Entry-level lead is
reported within the decision, but the inference unit is the distinct parent
seed. Positive resource/AoI/control benefit means shadow minus actual; positive
ACK airtime cost means actual used more ACK airtime. Intervals are descriptive
95% t intervals over 20 decisions and are not multiplicity-controlled.

| Cell | Target entries | Entries with positive lead | Mean lead [s], 95% CI | ACK airtime cost [s] | Net airtime benefit [s], 95% CI |
|---|---:|---:|---:|---:|---:|
| N5 CSMA | 39 | 89.74% | 0.02398 [0.01348, 0.03447] | 0.00200 [0.00103, 0.00297] | 0.00240 [−0.00395, 0.00875] |
| N10 ring2 | 41 | 80.49% | 0.04442 [−0.01436, 0.10319] | 0.00325 [0.00149, 0.00501] | 0.00175 [−0.01842, 0.02192] |
| N5 ALOHA | 31 | 70.97% | 0.14441 [0.03646, 0.25236] | 0.00435 [0.00045, 0.00825] | 0.03925 [−0.00646, 0.08496] |

Actual and shadow confirm every target entry within the local window at N5 and
N10. Under ALOHA, actual confirms 96.77% and shadow 93.55%; missing entries are
retained as censored. ALOHA again produces the longest causal lead and largest
mean resource benefit, but its 20-decision interval remains heterogeneous and
contains zero.

## Lead is not equivalent to receiver benefit

| Cell | True-AoI integral benefit [s²], 95% CI | Formation-loss integral benefit [m²s], 95% CI | Pareto beneficial / harmful / mixed decisions |
|---|---:|---:|---:|
| N5 CSMA | −0.001194 [−0.002252, −0.000137] | −4.31e−6 [−1.05e−5, 1.85e−6] | 1 / 11 / 8 |
| N10 ring2 | −0.000361 [−0.001369, 0.000647] | −1.28e−5 [−2.44e−5, −1.24e−6] | 3 / 9 / 8 |
| N5 ALOHA | +0.006916 [−0.003196, 0.017027] | +4.44e−5 [−1.56e−5, 1.04e−4] | 8 / 5 / 7 |

The causal interpretation is sharper than EXP14F:

- N5 standalone ACKs create a reliable short confirmation lead, yet true
  receiver AoI becomes significantly worse over the next 0.75 s. Advancing
  sender belief can suppress or reshape later DATA even though the ACK itself
  carries no state.
- N10 has heterogeneous lead and resource effects, while integrated formation
  loss is significantly adverse. Earlier confirmation is again not a control
  benefit certificate.
- ALOHA has favorable mean signs for airtime, true AoI and control, consistent
  with the full-policy MAC reversal, but the per-decision effects are too
  heterogeneous for a universal “send ACK” rule.

Only 1/20 N5 and 3/20 N10 decisions are Pareto beneficial across resource,
true-AoI and control signs; 11/20 and 9/20 are Pareto harmful. ALOHA improves to
8/20 beneficial but still has five harmful and seven mixed/null decisions.
This directly rejects any policy that equates positive lead with positive
value.

## N20 sparse boundary

The 60 N20 pilot runs contain 75 admitted standalone decisions, but only five
fall in the frozen post-transient/full-window eligibility interval and those
come from four seeds. Outcome-blind one-event-per-seed sampling therefore
selects four decisions, below the required 12.

The nine target entries show only 33.33% positive lead and mean lead 0.0005 s.
Raw mean net airtime benefit is −0.006 s. These values receive no interval and
support no N20 inference.

EXP14H subsequently executed the registered closure on 240 disjoint N20
pilots. It found only seven distinct eligible parent seeds and therefore
stopped before outcome replay at the same minimum of 12. Across the two
support audits, only 11/300 seeds (3.67%; Wilson 95% interval [2.06%, 6.45%])
contain an eligible post-transient event. This is a practical support failure
for the frozen per-decision N20 estimand, not an ACK effect estimate. Full
details are in `docs/EXP14H_N20_SUPPORT_CLOSURE_RESULTS.md`.

## Research consequence

EXP14G identifies per-decision causal lead, but a predictive certificate is
still not ready. The data show strong sign heterogeneity and the study explicitly
forbids fitting a rule on these outcomes. The next steps are:

1. preserve N20 as a sparse/non-identifiable boundary rather than changing the
   eligibility window or repeatedly adding seeds;
2. use the completed development evidence to specify one interpretable
   MAC-selective feedback rule rather than a fine-grained predictor;
3. freeze that rule before a disjoint validation block and do not refit it.

EXP14I subsequently completed step 3: the frozen CSMA-to-piggyback and
ALOHA-to-adaptive mapping passed 6/6 Holm-adjusted error/load hypotheses on a
new 100-seed block. This validates the categorical route selector, not a
fine-grained causal predictor and not an N20 per-decision effect.

The claim that survives is deliberately narrow: standalone ACK value is a
MAC- and state-dependent mediated effect; confirmation lead alone is neither a
freshness nor a control-value certificate.
