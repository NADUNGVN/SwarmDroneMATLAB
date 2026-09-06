# EXP14G branch-at-decision causal ACK replay plan

## Motivation and estimand

EXP14F established that a full ACK-assisted policy usually confirms a
generation before a full piggyback-only policy, but the two histories may have
already diverged before a focal event. EXP14G closes that causal gap. For one
registered adaptive standalone-ACK admission, two simulations replay the same
absolute trace and are identical through the complete pre-decision state. The
actual branch admits the target aggregate. The shadow branch protects only its
directed-link obligations from standalone aggregates until generation-
equivalent piggyback confirmation or the local horizon; unrelated feedback is
unchanged.

For target entry (q), decision time (t_0), branch confirmations
\(\tau_A^q,\tau_P^q\), and local end (H_q), the causal lead is

\[
L_q=\max\{\min(\tau_P^q,H_q)-\min(\tau_A^q,H_q),0\}.
\]

Missing confirmations are retained as censored at (H_q). The decision—not an
ACK entry—is the sampling unit. Aggregate-frame airtime is counted once.

## Frozen registry

- Version: `EXP14G-BRANCH-AT-DECISION-DEVELOPMENT-v1`.
- Registry hash: `52831592` over 31 leaves.
- Pilot seeds: `16019001:16019060`, disjoint from all earlier blocks.
- Cells: N5 CSMA, N10 ring2, N20 ring2 and N5 ALOHA.
- Pilot: selected adaptive/scaled policy only, 240 full 12 s runs.
- Local branch horizon: at least 0.75 s, ending at the first outer control tick
  at or after 0.75 s.
- Eligible decision time: from 8 s through the latest decision whose complete
  local window lies inside 12 s.
- Sample cap: 20 decisions per cell; minimum analyzable support 12.
- At most one decision per parent seed/cell.
- No confirmatory claim, threshold tuning or predictor fitting is permitted.

## Outcome-blind selection

The pilot records only causal information available before each permitted ACK
decision: node, pending age, local busy estimate, queue depth, forced flag,
aggregate entry count and state hashes. Candidates are assigned fixed busy bins
`[0,.25,.50,.75,Inf]`, pending-age bins `[0,.05,.15,.35,Inf]`, entry-count
class and forced class. A deterministic priority from seed, candidate ordinal,
cell and salt `14017001` is used.

Selection first admits the lowest-priority candidate that adds both a new
stratum and a new parent seed, then fills by priority using new parent seeds.
No delivery, lead, airtime, collision, AoI, control or safety outcome enters
selection. The selected-event table and hash are locked before replay.

## Intervention semantics

`observe` and `admit-target` are required to be physically identical to the
uninstrumented selected policy. `suppress-target` changes only target
directed-link entries: while unresolved, they remain eligible for DATA
piggyback but are removed from standalone aggregates. Other ACK entries in the
same aggregate may still transmit. The intervention expires at the local end.

The pilot and both branches hash the complete network state excluding passive
logs/replay metadata, plus plant, controller, estimator, policy and outer-loop
context. Actual and shadow target hashes and entry identity must match exactly.

## Outcomes and claim boundary

Positive benefit means shadow minus actual for DATA airtime, total airtime,
DATA attempts, collisions, integrated true/estimated AoI and integrated squared
formation error. ACK airtime cost is actual minus shadow. The exact identity

\[
M_{air}=(D_P-D_A)-(A_A-A_P)
\]

must close for every pair. Entry leads, censoring and confirmation route are
reported, but inference is by decision/parent seed, never by treating entries
as independent.

All intervals are descriptive. EXP14G may expose candidate covariates and
causal labels, but may not fit a decision rule. Any predictor or lead-benefit
envelope must be frozen afterward and evaluated without refitting on a new
disjoint seed block.
