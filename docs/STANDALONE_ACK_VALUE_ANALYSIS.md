# Standalone ACK marginal-value theory and EXP14E--H mechanism audit

## 1. Scope and claim status

This document is the first post-EXP14E mathematical closure step. It does not
change the frozen EXP14E registry, six-test Holm family or claim verdict. The
empirical comparison was already present in the seven-arm holdout, but the
airtime decomposition below is a post-hoc mechanism analysis. It has
`confirmatoryClaimPermitted=false` and `thresholdTuningPermitted=false`.

The analysis uses the completed, integrity-valid run
`results/exp14e_preregistered_holdout/2026-08-30_213957` and compares selected
adaptive standalone ACK with piggyback-only on the same 100 paired traces per
cell. All reported intervals are descriptive paired 95% t intervals.

## 2. Mathematical result

For policy \(S\) with standalone ACK and piggyback-only policy \(P\), let
\(D_H^\pi\) and \(A_H^\pi\) denote DATA and standalone-ACK airtime over horizon
\(H\). DATA airtime already includes piggyback-entry bytes. Define

\[
S_D=D_H^P-D_H^S,\qquad
C_A=A_H^S-A_H^P.
\]

The exact offered-airtime benefit of standalone ACK is

\[
M_{air}=S_D-C_A,\qquad
U_H^P-U_H^S=M_{air}/H.
\]

Thus standalone feedback lowers offered load if and only if the DATA airtime
it saves exceeds its direct ACK airtime. Adding `PIGGYBACK_AIRTIME` separately
would double-count bytes already included in `DATA_AIRTIME`.

An ACK cannot directly improve true receiver AoI or control state because it
updates sender belief \(C_{ij}\), not receiver truth \(G_{ij}\). Any positive
effect must arise through changed later DATA decisions, queue service or
collisions. The full derivation, unique-lead certificate and proof are in
`docs/STUDY2_MATHEMATICAL_FOUNDATION.md`, Section 7.

## 3. EXP14E accounting result

Positive values below favor standalone ACK. `DATA coverage` is
\(S_D/C_A\); it is not used as a tuned decision threshold.

| Cell | ACK airtime cost [s] | DATA airtime saved [s] | DATA coverage | Net airtime benefit [s], 95% CI | RMSE benefit [m], 95% CI | Descriptive classification |
|---|---:|---:|---:|---:|---:|---|
| N5 CSMA | 0.12134 | 0.05952 | 49.1% | −0.06182 [−0.08307, −0.04057] | −0.000423 [−0.000593, −0.000253] | piggyback dominates continuous outcomes |
| N10 ring2 | 0.16157 | −0.01220 | −7.6% | −0.17377 [−0.22045, −0.12709] | −0.000826 [−0.001184, −0.000467] | piggyback dominates continuous outcomes |
| N20 ring2 | 0.00196 | −0.00172 | −87.8% | −0.00368 [−0.02062, +0.01326] | −0.000142 [−0.001036, +0.000752] | inconclusive continuous outcomes |
| N5 ALOHA | 0.39545 | 0.97840 | 247.4% | +0.58295 [+0.44506, +0.72084] | +0.011824 [+0.008325, +0.015324] | ACK-assisted dominates continuous outcomes |

The accounting identity closes to numerical precision in every one of the 400
pairs. Dividing net airtime benefit by the 12 s horizon reproduces the paired
offered-utilization difference to numerical precision.

## 4. Mechanism interpretation

### N5 CSMA

Adaptive feedback sends 62.96 standalone ACK frames per run and costs 0.12134 s
of ACK airtime. Earlier confirmation suppresses 14.88 DATA attempts and saves
0.05952 s of DATA airtime, but this repays only 49.1% of the ACK cost. The net
load and RMSE signs both favor piggyback. Collision savings of 3.11 frames have
an interval that contains zero and do not repair the airtime deficit.

### N10 CSMA

Adaptive feedback sends 82.15 standalone ACK frames and costs 0.16157 s. It
does not suppress DATA: it induces 3.05 additional attempts and 0.01220 s of
extra DATA airtime. It also adds 27.2 collision frames on average, with the
paired interval entirely adverse. Both control and resource outcomes therefore
favor piggyback-only.

### N20 CSMA

The adaptive rule sends only 1.1 standalone ACK frames per run. It has
effectively converged to piggyback-first operation under high local busy load.
All continuous differences are near zero and their paired intervals include
zero. The correct conclusion is equivalence unresolved at this pair count, not
proof that standalone ACK is beneficial. The observed safety count remains
1/100 for adaptive versus 2/100 for piggyback, without a population safety
claim.

### N5 ALOHA

Here 313.84 standalone ACK attempts cost 0.39545 s but suppress 244.6 DATA
attempts, save 0.97840 s DATA airtime and avoid 129.21 collision frames on
average. DATA savings cover 247.4% of direct ACK cost, leaving 0.58295 s net
airtime benefit. RMSE and true AoI improve at the same time. This is a strong
descriptive MAC reversal, but ALOHA was not in the confirmatory family.

The result refines the paper's mechanism story: ACK value is not monotone in
ACK rate, swarm size or nominal congestion. It depends on whether early sender
confirmation changes future DATA demand enough to repay feedback service in
that MAC regime.

## 5. Unique-lead certificate and why EXP14E could not evaluate it

Let \(\tau_A\) be successful standalone-confirmation time and \(\tau_P\) the
time the same entry would have reached the sender under the coupled
piggyback-only counterfactual. The unique information lead is

\[
\ell=[\min\{\tau_P,H\}-\min\{\tau_A,H\}]^+.
\]

If the early-information benefit rate lies in
\([\underline b,\overline b]\) and ACK contention externality lies in
\([\underline x,\overline x]\), the conditional ACK net value lies between

\[
\underline b\,\mathbb E[\ell]-(w_Uc_A+\overline x)
\quad\text{and}\quad
\overline b\,\mathbb E[\ell]-(w_Uc_A+\underline x).
\]

An upper bound at or below zero certifies discard; a lower bound above zero
certifies transmit; overlap is inconclusive. The executable implementation is
`utils/standaloneAckValueCertificate.m`.

EXP14E logs ACK attempts, airtime, delivery delay and aggregate policy
outcomes, but not the counterfactual \(\tau_P\) after the standalone action has
changed the subsequent trajectory. Therefore its predictive certificate is
correctly `NOT_EVALUATED`. Inferring \(\tau_P\), \(\underline b\) or
\(\overline b\) from the same favorable/adverse aggregate means would be
post-hoc model fitting, not a theorem check.

## 6. EXP14F measurement result

EXP14F implemented the passive event log and ran two complete policies on a
shared absolute trace for 20 new development seeds in each of four cells. The
run `results/exp14f_paired_shadow/2026-08-30_230947` passed 12/12 integrity
gates and recorded 9,694 accepted standalone-confirmation events.

Positive generation-matched lead occurred for 83.67% of N5 CSMA events,
78.53% of N10 events, 100% of the 20 sparse N20 events, and 96.53% of ALOHA
events. Mean horizon-capped leads were 0.0707, 0.0644, 0.0994 and 0.2512 s,
respectively. Nevertheless piggyback-only retained lower RMSE, true AoI and
airtime at N5/N10, N20 remained unresolved, and ACK assistance retained its
ALOHA advantage. A positive lead is therefore common but not sufficient to
repay the ACK's direct and collision-mediated cost.

The shadow arms run from (t=0), so their histories may differ before each
matched event. EXP14F identifies a generation-matched policy lead, not the
per-decision causal effect assumed by the strongest interpretation of the
certificate. The certificate remains `NOT_EVALUATED`; details and exact tables
are in `docs/EXP14F_PAIRED_SHADOW_RESULTS.md`.

## 7. EXP14G branch-at-decision result

EXP14G implemented the required state-cloned replay. For each locked focal
decision, the actual and shadow branches have identical pre-decision network,
plant and controller hashes and identical future exogenous inputs. The only
intervention is admit-target versus link-specific suppression until piggyback
over the 0.75 s local horizon.

N5 CSMA, N10 ring2 and N5 ALOHA each passed the frozen support minimum with 20
distinct parent seeds. Positive confirmation lead occurred for 89.74%, 80.49%
and 70.97% of target entries, respectively. The receiver-side results reject
lead as a value surrogate:

| Cell | Mean lead [s] | Net airtime benefit [s] | True-AoI integral benefit [s²] | Formation-loss integral benefit [m²s] |
|---|---:|---:|---:|---:|
| N5 CSMA | +0.02398 | +0.00240 | −0.001194 | −4.31e−6 |
| N10 ring2 | +0.04442 | +0.00175 | −0.000361 | −1.28e−5 |
| N5 ALOHA | +0.14441 | +0.03925 | +0.006916 | +4.44e−5 |

The N5 true-AoI effect is significantly adverse and the N10 integrated
formation-loss effect is significantly adverse over the local window. ALOHA
has favorable mean signs but heterogeneous intervals containing zero. Thus a
standalone ACK can advance sender knowledge and still worsen receiver
freshness or control by suppressing or reshaping later DATA. Proposition 4's
lead term is necessary to describe the information advance, but positive lead
alone does not establish a positive benefit-rate bound.

The original EXP14G verdict remains `FAIL-selection-support` because N20
supplied only four distinct eligible seeds. This does not invalidate the three
support-limited cell descriptions, but it forbids a four-cell or confirmatory
claim.

## 8. EXP14H support closure and identifiability boundary

EXP14H retained the exact N20 policy, eligibility interval, intervention and
minimum while adding 240 disjoint pilot seeds. Only seven distinct seeds
contained an eligible event, so its preflight stopped before any replay
outcome. Across EXP14G and EXP14H, 11/300 N20 seeds supplied at least one
eligible event: 3.67%, with a 95% Wilson interval of [2.06%, 6.45%].

This is a practical positivity/overlap failure for the registered finite
design. It does not identify the sign of an N20 ACK effect. Instead it shows
that the selected N20 policy almost never invokes the action whose marginal
value was to be estimated after the transient. The defensible response is to
retain N20 as a sparse boundary, not relax the estimand or fit a predictor from
seven events.

The combined mechanism evidence supports an interpretable policy family rather
than another scalar ACK threshold: piggyback-only under CSMA and adaptive
standalone feedback under ALOHA.

## 9. EXP14I disjoint validation

EXP14I froze that two-branch mapping before opening 100 new seeds per cell. Its
1,600-run matrix passes 15/15 integrity gates, including exact candidate-route
aliasing, with zero divergence and zero protocol violations. All 6/6
Holm-adjusted hypotheses pass:

- at N5/N10 CSMA, piggyback routing lowers RMSE by 0.97%/1.22% and offered
  utilization by 2.94%/2.64% relative to adaptive standalone feedback;
- at N5 ALOHA, adaptive routing lowers RMSE by 11.84% and offered utilization
  by 4.51% relative to piggyback-only.

N20 remains outside the confirmatory family. Candidate/piggyback and adaptive
differ by only +0.000105 m RMSE and −0.000257 offered utilization on average,
with both intervals crossing zero; adaptive emits only 0.77 standalone ACK
attempts per run. The later full-policy validation therefore reinforces, but
does not repair or replace, the EXP14G/H event-support boundary.

EXP14I validates the categorical MAC selector. It does not calibrate A8's
state-conditional benefit-rate envelope, identify effects in unsupported N20
states, or justify a universal-MAC claim.

## 10. Artifacts

- Machine-readable accounting:
  `posthoc_ack_value_accounting.csv` in the EXP14E run directory.
- Post-hoc manifest:
  `posthoc_ack_value_manifest.json` in the EXP14E run directory.
- Executable certificate: `utils/standaloneAckValueCertificate.m`.
- Contract test: `tests/test_standalone_ack_value_certificate.m`.
- Post-hoc analyzer: `experiments/analyzeExp14EAckValue.m`.
- EXP14F plan/results: `docs/EXP14F_PAIRED_SHADOW_PLAN.md` and
  `docs/EXP14F_PAIRED_SHADOW_RESULTS.md`.
- EXP14F event matcher: `utils/matchAckValueEvents.m`.
- EXP14G plan/results: `docs/EXP14G_BRANCH_AT_DECISION_PLAN.md` and
  `docs/EXP14G_BRANCH_AT_DECISION_RESULTS.md`.
- EXP14G replay analyzer: `utils/analyzeAckBranchPair.m`.
- EXP14H plan/results: `docs/EXP14H_N20_SUPPORT_CLOSURE_PLAN.md` and
  `docs/EXP14H_N20_SUPPORT_CLOSURE_RESULTS.md`.
- EXP14I plan/results: `docs/EXP14I_MAC_SELECTIVE_VALIDATION_PLAN.md` and
  `docs/EXP14I_MAC_SELECTIVE_VALIDATION_RESULTS.md`.
