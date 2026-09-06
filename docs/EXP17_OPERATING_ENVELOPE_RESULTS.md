# EXP17 preregistered operating-envelope robustness results

## Run identity

- Experiment: `exp17_operating_envelope`
- Run: `2026-08-31_110505`
- Registry: `EXP17-OPERATING-ENVELOPE-HOLDOUT-v1`
- Registry hash: `123727884` over 122 leaves
- Holdout seeds: `16023001:16023100`
- Frozen matrix: 4000/4000 simulations
- Core family: 48 one-sided tests under one Holm correction
- Boundary contexts: reverse-asymmetric and hidden-terminal, descriptive only
- Elapsed time: 23 min 04 s on 16 process workers

The continuation rule, contexts, multiplicity family, safety guards and source
snapshot were frozen before the first holdout simulation.

## Integrity verdict

All 14/14 integrity gates pass:

- complete, unique matrix with exactly four arms per seed/context;
- one absolute random/channel/estimator realization across both MAC levels
  within every seed/context;
- exact context, route, MAC and analytical `min(0.20,1/N)` access semantics;
- no standalone ACK in piggyback arms and adaptive actions only in adaptive
  arms;
- causal conservatism with zero protocol violations;
- maximum queue depth 2, maximum history depth 32;
- exact terminal physical accounting;
- zero divergences and finite eligible outcomes.

The negative performance result is therefore not caused by a failed execution
or incomplete pairing contract.

## Frozen verdict

Only 11/48 Holm-adjusted tests reject, and only 1/8 core contexts satisfies all
six outcome/simple-effect/interaction tests plus both observed safety guards.

- Claim verdict: `PARTIALLY_SUPPORTED_NO_CONTINUATION_GATE`
- Continuation verdict: `DO_NOT_PROCEED_WITH_GENERAL_SELECTOR`

The sole fully supported context is the original N5 Moderate, zero-background
cell. The preregistered requirement was at least 6/8 core contexts including
both N values, channel levels and background levels. That rule fails.

## Core operating-envelope map

The table reports the within-seed interaction

`(adaptive-piggyback)_ALOHA - (adaptive-piggyback)_CSMA`.

Negative is the registered direction, but a negative point estimate is not
enough: each context required both simple effects and the interaction for both
outcomes to survive the global 48-test Holm correction.

| Core context | RMSE interaction | Offered-util. interaction | Six-test context support | Safety guards |
|---|---:|---:|---:|---:|
| N5 Moderate, bg0 | −0.008857 | −0.041828 | Yes | 2/2 |
| N5 Moderate, bg0.30 | +0.000030 | −0.000206 | No | 2/2 |
| N5 Stressed, bg0 | −0.010330 | −0.008965 | No | 2/2 |
| N5 Stressed, bg0.30 | +0.000696 | −0.001485 | No | 2/2 |
| N10 Moderate, bg0 | +0.000980 | −0.017562 | No | 2/2 |
| N10 Moderate, bg0.30 | +0.005634 | −0.003547 | No | 2/2 |
| N10 Stressed, bg0 | −0.001780 | −0.000512 | No | 2/2 |
| N10 Stressed, bg0.30 | +0.001669 | −0.000133 | No | 1/2 |

### Supported partial mechanisms

The 11 rejections decompose as follows:

- N5 Moderate bg0: all 6/6 tests;
- N5 Stressed bg0: ALOHA RMSE simple effect and RMSE interaction;
- N10 Moderate bg0: both CSMA simple effects and the offered-utilization
  interaction.

This matters scientifically. Some pieces of the mechanism persist, but the
categorical selector does not retain simultaneous control-and-resource support
over the declared envelope.

## Why the generalization fails

### Background load removes the N5 interaction

At N5 Moderate with background 0.30, both interactions are essentially zero:
RMSE +0.000030 with 95% CI [−0.009652, 0.009711], and offered utilization
−0.000206 with CI [−0.004671, 0.004259]. The route distinction is swamped by
the loaded medium rather than merely losing significance by a small margin.

### N10 does not reproduce the ALOHA route advantage

At N10 Moderate bg0, piggyback remains better under CSMA for RMSE and offered
load, but adaptive-minus-piggyback RMSE under ALOHA is +0.002233 m with CI
[−0.004379, 0.008845]. The RMSE interaction is therefore positive and
unresolved. Offered-airtime interaction remains negative, so communication and
control conclusions separate.

### Stressed channels retain only fragments

At N5 Stressed bg0, ALOHA adaptive feedback improves RMSE and the RMSE
interaction remains negative, but the CSMA RMSE and both route simple effects
for offered utilization do not pass. At N10 Stressed bg0, the CSMA point
estimates favor piggyback, while ALOHA and both interactions remain unresolved.

## Safety boundary

Several high-load ALOHA/N10 cells enter an operational failure region even
though plant outputs remain finite:

- N5 Moderate bg0.30 ALOHA: 100/100 failures for both routes;
- N5 Stressed bg0.30 ALOHA: 100/100 for both routes;
- N10 Moderate bg0 ALOHA: 100/100 for both routes;
- N10 Moderate bg0.30 CSMA: 100/100 for both routes; ALOHA adaptive/piggyback
  87/89;
- N10 Stressed bg0 ALOHA: 100/100 for both routes;
- N10 Stressed bg0.30 CSMA: 100/100 for both routes; ALOHA adaptive/piggyback
  83/82.

The last cell fails the registered ALOHA safety guard because adaptive has one
more observed failure than piggyback. These are not population estimates of
safety superiority, but they show that the selector question is secondary once
the operating point is already unsafe.

## Boundary contexts

### Reverse-asymmetric ACK path

- CSMA piggyback-minus-adaptive RMSE becomes adverse: +0.000249 m, 95% CI
  [+0.000059, +0.000438].
- ALOHA adaptive improves RMSE by −0.006495 m, but worsens offered utilization
  by +0.019777, CI [+0.009678, +0.029875].
- The RMSE interaction remains negative; the offered-utilization interaction
  crosses zero.

Thus reverse asymmetry destroys the simple categorical resource/control rule.

### Hidden terminals

The RMSE and offered-utilization interaction estimates remain negative, but
the CSMA simple effects are unresolved; piggyback-minus-adaptive RMSE is
slightly positive. Hidden-terminal results are descriptive and do not support
the core envelope.

## Scientific conclusion

EXP16 remains a valid, replicated statement about the matched base cell.
EXP17 rejects its extension into a general MAC-only selector. The result should
be framed as a **bounded feedback-mediation phenomenon with an identified
operating boundary**, not as a deployable cross-MAC policy.

No post-hoc threshold or route retuning is authorized. EXP17 may become
development evidence for a separately defined next-generation selector that
uses observable load, swarm size and reverse-channel state, but that would be a
new method requiring new seeds and preregistration.

## Hardware decision

The frozen pre-hardware continuation rule fails. Therefore:

- do not purchase hardware to validate the current general selector;
- do not claim that measured CSMA validation is the next automatic step;
- retain EXP15's trace/bench interfaces for a future redesigned method or a
  deliberately narrow base-cell mechanism study;
- first decide whether the paper will pivot to a negative/boundary mechanism
  contribution or develop a new context-aware route policy.

