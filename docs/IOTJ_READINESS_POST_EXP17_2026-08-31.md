# IEEE IoT-J readiness after EXP16--EXP17

**Date:** 31 August 2026  
**Canonical EXP17 run:** `2026-08-31_110505`  
**Decision:** not ready for IoT-J as a general feedback-route selector; do not
advance the current selector to hardware.

## What was executed

The pre-hardware recommendation was converted into two frozen, new-seed
studies rather than another informal parameter sweep.

1. EXP16 tested a matched route-by-access `2 x 2` interaction on 100 new seeds.
   It passed all 6/6 Holm-adjusted RMSE/offered-airtime hypotheses in the N5
   Moderate, zero-background cell.
2. EXP17 expanded the same estimand to eight core contexts formed by
   `N={5,10}`, `channel={Moderate,Stressed}`, and
   `background={0,0.30}`, plus reverse-asymmetric and hidden-terminal
   descriptive boundaries. It completed 4000/4000 runs and passed 14/14
   integrity gates.

The canonical EXP17 performance verdict is
`PARTIALLY_SUPPORTED_NO_CONTINUATION_GATE`: 11/48 globally adjusted tests and
only 1/8 complete context rules pass. The frozen continuation verdict is
`DO_NOT_PROCEED_WITH_GENERAL_SELECTOR`.

## Interpretation

EXP16 is not invalidated. It identifies a local feedback-mediation interaction:
piggyback is favored in the matched base CSMA cell, whereas adaptive standalone
feedback is favored in the matched base ALOHA cell. EXP17 shows that configured
MAC type is not enough to turn that local phenomenon into an operating policy.

Three mechanisms explain the boundary:

- background load nearly removes the N5 Moderate route interaction;
- at N10, the ALOHA RMSE advantage does not reproduce even when a communication
  effect remains;
- reverse-path asymmetry separates control and resource signs: adaptive
  feedback can improve RMSE while worsening offered airtime.

Several envelope cells are already in an operational failure region for both
routes. In those cells, feedback-route selection is secondary to service
feasibility and admission/access control.

## Claims now permitted

- The sender-side confirmed-age construction is causal and conservative under
  the declared honest-feedback model.
- Confirmation lead is not sufficient to establish receiver-freshness or
  closed-loop benefit.
- A formal route-by-access interaction exists in the matched N5 Moderate base
  cell and is replicated there by EXP17.
- The interaction is bounded: it does not generalize to a MAC-only selector
  over load, loss and swarm-size variation.
- The negative continuation result is an experimental contribution because it
  identifies which omitted state variables govern feedback value.

## Claims now prohibited

- a deployable CSMA-versus-ALOHA feedback selector;
- robustness over the declared operating envelope;
- hardware readiness of the current policy;
- population safety, named-standard MAC behavior, or measured energy;
- a universal claim that standalone ACK or piggyback is preferable.

## Hardware decision

No UAV or radio hardware should be purchased to validate the current general
selector. This is a scientific stop, not a budget delay: live validation would
measure a claim that the simulation envelope has already rejected.

The EXP15 trace contract and proposed Raspberry Pi/radio bench remain reusable
after either (a) a new policy passes an independent simulation gate, or (b) the
paper is deliberately scoped to validate only the base-cell mechanism. Flight
hardware remains unnecessary for either nearest step.

## Submission consequence

The manuscript is internally stronger and more honest, but it is not ready for
IoT-J as an IoT solution paper. Its strongest current identity is a
causal/mechanism-and-boundary study. That can be retained as a complete research
artifact, but an IoT-J submission would still need either substantially stronger
theory or a redesigned context-aware communication policy followed by fresh
validation and then a measured trace/radio bridge.

## Recommended research continuation

Freeze the current paper and all EXP14--EXP17 results as the non-overwritable
mechanism record. If IoT-J remains the target, start a separate method cycle
whose selector uses observable operating state rather than a MAC label alone.
The design should be hierarchical:

1. a service-feasibility/congestion gate decides whether the operating point
   can safely support either feedback route;
2. only in feasible states, a causal marginal-value rule compares predicted
   DATA suppression/control benefit against ACK airtime, collision and
   reverse-path cost;
3. load, swarm size, reverse-delivery state and burst state enter explicitly;
4. EXP17 may be used only as development evidence;
5. all thresholds, primary estimands and continuation gates are frozen before
   opening a disjoint new-seed holdout;
6. hardware begins only if the new envelope gate passes.

This is a new method, not a post-hoc repair of EXP17. A lower-risk alternative
is to stop algorithm development and submit a deliberately bounded
mechanism/negative-results paper, but that route is less aligned with IoT-J's
expectation of a validated IoT communication contribution.

## Artifact pointers

- EXP16 protocol and result: `EXP16_FACTORIAL_INTERACTION_PLAN.md`,
  `EXP16_FACTORIAL_INTERACTION_RESULTS.md`
- EXP17 protocol and result: `EXP17_OPERATING_ENVELOPE_PLAN.md`,
  `EXP17_OPERATING_ENVELOPE_RESULTS.md`
- canonical machine verdicts:
  `results/exp17_operating_envelope/2026-08-31_110505/claim_verdict.json` and
  `continuation_verdict.json`
- manuscript claim boundary: `paper/study2/STUDY2_CLAIM_LEDGER.md`

