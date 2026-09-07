# True branch-at-decision value diagnostic result

**Technical verdict:** `PASS`

**Scientific verdict:** `BRANCH_SIGNAL_VALID`

**Accepted run:**
`results/tcns_true_branch_value_diagnostic/2026-09-07_121250`

**Source commit:** `84849c3`; MATLAB R2025a.

## Technical evidence

All 200 preregistered paired actions completed: 100 each in S2 and S6 over
five development seeds. Exactly 170 actions were delivered and accepted,
giving a success fraction of 0.85 within the frozen [0.65, 0.95] interval.

Every branch retained the exact baseline channel hash, phase hash, and
periodic sender-fire log. Every injected action added exactly one DATA
attempt and one broadcast-accounting action. Plant state was identical
through the decision sample in all branches. All 30 dropped actions left the
complete \(P,V,A\) trajectory bit-identical to baseline. Every non-dropped
action was accepted. The maximum candidate-time shift was one outer sample
(0.02 s), below the allowed 0.18 s. No baseline or branch saturated in the
evaluation interval.

## Frozen scientific decision

All correlations use the 85 accepted actions in each scenario.

| Scenario | Cross-term correlation | Isolated correlation | Increment | Top-quartile mean benefit | Bottom-quartile mean benefit | Top-quartile positive |
|---|---:|---:|---:|---:|---:|---:|
| S2 Formation switching | 0.6677 | 0.3771 | +0.2906 | 0.001399 | -0.000443 | 1.000 |
| S6 Dynamic excitation | 0.5645 | 0.2850 | +0.2796 | 0.001690 | 0.000379 | 1.000 |

The preregistered prediction threshold was 0.50 and the required correlation
increment over isolated energy was 0.10. Both pass in both scenarios. Every
action in the top cross-term-predicted quartile has positive realized
benefit, exceeding the frozen 0.75 threshold. Its mean realized benefit also
exceeds the bottom quartile in both scenarios. Therefore every frozen
scientific gate passes and the decision is `BRANCH_SIGNAL_VALID`.

Across all successful actions, 76.5% are beneficial in S2 and 100% in S6.
This further exposes why an unconditioned “send whenever novelty is large”
rule is unsafe in formation switching: a nontrivial subset of real extra
updates increases the finite-horizon formation cost, while the cross-term
projection separates the high-value subset substantially better.

## What this establishes

The fixed-input cross-term score is not merely an algebraic artifact. Despite
later periodic packet replacement, state-dependent future payloads, and full
closed-loop evolution, it retains moderate predictive correlation with true
one-action returns and contributes roughly 0.28--0.29 correlation beyond the
isolated response-energy score.

Together with the identifiability proposition, the evidence establishes a
coherent mechanism chain:

1. the sender-local isolated score omits a mathematically necessary cross
   term;
2. that term materially reorders candidate actions in logged trajectories;
3. its score predicts realized paired branch value better than isolated
   novelty in two distinct nonstationary scenarios.

This is stronger than the stopped AoI/state-error trigger direction, but it
is still an oracle mechanism diagnostic.

## Strict scope boundary

The result does not show an adaptive communication frontier or superiority
to periodic communication. It adds one transmission to a P10 baseline and
uses centralized receiver/global-state information. Actions are evaluated
one at a time, so simultaneous-action cross terms and endogenous repeated
scheduling are absent. The sample uses development seeds only.

Accordingly, no distributed or causal contribution is yet claimed, and Gate
7, scalability, and held-out evaluation remain closed.

## Authorized next step

The next step is a small, preregistered centralized online-oracle sanity
frontier. Its purpose is a necessary action-space test: can repeated greedy
use of total predicted marginal benefit create any budget/performance
headroom over the periodic frontier when all oracle DATA transmissions are
charged?

Only a positive oracle result would justify designing a receiver-side
residual/adjoint message. That later implementation must remove receiver
truth and charge its reverse-channel traffic. An oracle failure stops the
rich-VoI mechanism family despite the present branch-prediction result.
