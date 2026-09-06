# EXP17 preregistered operating-envelope robustness plan

## Objective

EXP16 confirms a feedback-route-by-configured-MAC interaction in one matched
N=5 Moderate cell. EXP17 asks whether that interaction is stable over a
declared operating envelope before radio hardware is purchased. The policy,
ACK scheduler, access rule, frame sizes, estimator and formation controller are
unchanged. This is a robustness study, not another development/tuning stage.

## Provenance and freeze

- Version: `EXP17-OPERATING-ENVELOPE-HOLDOUT-v1`.
- Design source ends at completed EXP16 run `2026-08-31_104551`.
- Holdout seeds: `16023001:16023100`.
- Development/smoke seed: `16022999`, excluded from the holdout.
- Every seed/context uses one absolute random/channel realization for all four
  MAC-by-route cells.
- Opening the holdout freezes the registry, source snapshot, 48-test family,
  safety rules and hardware-continuation rule.
- No policy parameter, context, hypothesis, exclusion or gate may change after
  the first holdout run.

## Core operating envelope

The eight confirmatory contexts form

`N ∈ {5,10} × channel ∈ {Moderate,Stressed} × background ∈ {0,0.30}`.

N=5 retains the frozen 6-DOF follower implementation. N=10 uses the declared
double-integrator ring2 scalability model. Moderate and Stressed are the frozen
Gilbert--Elliott regimes. Background load is exogenous per-slot occupancy.
Access remains `pAccess=min(0.20,1/N)`.

Each context contains the same four-cell factorial:

1. CSMA + adaptive standalone/piggyback;
2. CSMA + piggyback-only;
3. ALOHA + adaptive standalone/piggyback;
4. ALOHA + piggyback-only.

The core matrix contains `8 × 4 × 100 = 3200` simulations.

## Registered boundary contexts

Two N=5 Moderate, zero-background contexts are retained outside the
confirmatory family:

- reverse-asymmetric: standalone ACKs experience the frozen worse reverse
  Gilbert--Elliott process while piggyback entries follow DATA;
- hidden-terminal: global receiver interference with ring-neighbor carrier
  sensing.

They add `2 × 4 × 100 = 800` simulations and receive paired estimates and 95%
intervals only. They cannot rescue a failed core claim. Total frozen size is
4000 simulations.

## Core estimands and multiplicity

For outcome `Y` in context `c`, define

`D_c,m(Y)=Y(adaptive,c,m)-Y(piggyback,c,m)`

and

`I_c(Y)=D_c,ALOHA(Y)-D_c,CSMA(Y)`.

As in EXP16, registered alternatives are oriented below zero:

1. CSMA simple effect: `piggyback-adaptive < 0`;
2. ALOHA simple effect: `adaptive-piggyback < 0`;
3. formal interaction: `I_c < 0`.

The two outcomes are RMSE and offered airtime utilization. All
`8 contexts × 2 outcomes × 3 tests = 48` one-sided paired t-test p-values form
one Holm family at familywise `alpha=0.05`. Interactions are computed within
seed before inference. Report 95% paired t intervals and deterministic
10,000-resample paired bootstrap intervals.

A core context is supported only if all six associated tests reject after the
global Holm adjustment and both observed route-specific safety guards pass.
Partial and failed contexts remain in the report.

## Divergence and safety

Divergence is a safety failure and makes its continuous contrast incomplete.
No imputation is permitted. A context's continuous claim requires all 100
seed-level contrasts. Registered observed safety guards are:

- CSMA: piggyback failure count no greater than adaptive;
- ALOHA: adaptive failure count no greater than piggyback.

Wilson intervals are reported for every arm. These guards are not population
safety tests.

## Frozen pre-hardware continuation rule

The operating envelope is broad enough to justify the next policy-sensitivity
and measured-CSMA gates only if:

1. the base `n5-moderate-bg0` context is supported;
2. at least 6/8 core contexts are supported;
3. at least 2/4 N=5 and 2/4 N=10 core contexts are supported;
4. the supported set contains at least one context at each channel level and
   each background-load level;
5. every core observed safety guard passes.

This rule decides research continuation, not publication acceptance. Failure
does not authorize retuning; it narrows or closes the general selector claim.

## Integrity gates

- frozen registry hash and complete unique 4000-row matrix;
- exactly four arms per seed/context;
- seed disjointness from EXP14--16;
- common absolute trace/channel/estimator realization across both MAC levels
  within each seed/context;
- finite eligible outcomes and explicit divergence accounting;
- causal conservatism, bounded queue/history and terminal accounting;
- exact context, MAC, route and `1/N` access semantics;
- no standalone ACK in piggyback arms and adaptive decisions only in adaptive
  arms;
- core/boundary flags exactly match the registry.

Performance analysis opens only after all integrity gates pass.

## Claim ceiling

EXP17 can map a bounded abstract operating envelope. It cannot claim IEEE
802.11 behavior, genuine radio ALOHA, measured energy, hardware performance,
universal MAC optimality, or population safety. The two plant models are
interpreted within context; N=5-versus-N=10 differences are not a pure swarm-
size causal effect.

