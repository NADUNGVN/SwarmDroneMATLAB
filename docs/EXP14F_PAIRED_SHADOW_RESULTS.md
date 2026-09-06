# EXP14F paired-shadow ACK-value results

## Status and provenance

EXP14F is complete. The development run
`results/exp14f_paired_shadow/2026-08-30_230947` contains all 160 simulations
(`20 seeds × 4 cells × 2 arms`) and 9,694 accepted standalone-confirmation
events. Runtime was 2 min 13 s. The registry hash is `20176987` over 25 leaves;
the plan, registry, matching code and source snapshot were written before the
first registered seed ran.

The complete repository suite passed 23/23 test files before seed opening. The
run passed 12/12 integrity gates: exact paired matrix, common absolute traces,
causal conservatism, bounded memory, terminal physical accounting, exact arm
semantics, one logged event per accepted confirmation and valid
generation/horizon matching. There were no divergence or protocol-invariant
violations. Performance was not an integrity gate and EXP14F permits no
confirmatory claim or threshold tuning.

## Generation-matched policy lead

For an accepted standalone confirmation at time (t_A), EXP14F finds the first
confirmation on the same directed link in a full piggyback-only run whose
generation time is at least the actual generation. It reports

\[
L_A=\max\{\min(t_P,H)-t_A,0\}.
\]

An unmatched shadow crossing is retained as horizon-censored. Event rows are
clustered within seed and may reuse a shadow crossing, so no event-level IID
confidence interval or additive sum of lead is reported.

| Cell | Runs with events | Events | Matched | Censored | Positive lead | Shadow already as fresh | Mean lead [s] | Median [s] | P95 [s] |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| N5 CSMA | 20/20 | 2,199 | 99.50% | 0.50% | 83.67% | 16.33% | 0.0707 | 0.054 | 0.197 |
| N10 ring2 | 20/20 | 2,632 | 99.09% | 0.91% | 78.53% | 21.47% | 0.0644 | 0.046 | 0.200 |
| N20 ring2 | 9/20 | 20 | 100% | 0% | 100% | 0% | 0.0994 | 0.002 | 0.544 |
| N5 ALOHA | 20/20 | 4,843 | 97.46% | 2.54% | 96.53% | 3.45% | 0.2512 | 0.160 | 0.806 |

The main mechanism result is therefore not “standalone ACKs usually have no
temporal effect.” Most delivered standalone confirmations do precede the
generation-equivalent piggyback confirmation. The stronger result is that a
positive information lead is not sufficient for useful policy-level value.

N20 is a sparse-support boundary: only 20 events occur in 9 of 20 runs. Its
100% positive fraction must not be compared at face value with the thousands
of events in the other cells or used to tune a rule.

## Policy-level value remains MAC-dependent

The table uses positive benefit = piggyback-only outcome minus ACK-assisted
outcome. Intervals are descriptive paired 95% t intervals over the 20 seeds;
they do not form a confirmatory family.

| Cell | RMSE benefit [m], 95% CI | True-AoI benefit [s], 95% CI | Net airtime benefit [s], 95% CI | Interpretation |
|---|---:|---:|---:|---|
| N5 CSMA | −0.000862 [−0.001335, −0.000390] | −0.002029 [−0.002855, −0.001204] | −0.06945 [−0.13358, −0.00532] | piggyback better on all three |
| N10 ring2 | −0.001376 [−0.002097, −0.000656] | −0.001888 [−0.002728, −0.001049] | −0.24225 [−0.33537, −0.14913] | piggyback better on all three |
| N20 ring2 | +0.000409 [−0.001865, +0.002683] | +0.000987 [−0.000923, +0.002896] | +0.03105 [−0.01403, +0.07613] | unresolved, ACK nearly inactive |
| N5 ALOHA | +0.013446 [+0.005388, +0.021503] | +0.025525 [+0.010292, +0.040757] | +0.67765 [+0.35783, +0.99747] | ACK-assisted better on all three |

At N5 CSMA, ACK airtime is 0.12005 s/run and the policy saves only 0.05060 s
of DATA airtime; the saving repays 42.1% of direct ACK cost. At N10, ACK costs
0.15845 s and induces 0.08380 s of additional DATA airtime plus 49.5 additional
collision frames on average. At N20, only 0.00195 s/run is spent on standalone
ACK and every continuous contrast crosses zero. Under ALOHA, 0.40735 s of ACK
airtime suppresses 1.0850 s of DATA airtime and 151.25 collision frames,
leaving 0.67765 s net benefit.

Thus lead magnitude alone cannot rank ACK value. ALOHA has a much longer mean
lead and converts it into lower DATA demand; CSMA often obtains a positive but
short lead that fails to repay direct feedback service, while N10 also incurs
an adverse collision-mediated response.

## Causal interpretation boundary

EXP14F compares two complete policies from (t=0). Before a selected event at
(t_A), earlier standalone ACKs may already have changed trigger, queue,
collision and plant histories relative to piggyback-only. Consequently the
matched (L_A) is a generation-matched **policy lead**, not the causal effect
of suppressing that individual ACK while holding the pre-decision history
fixed. Repeated actual events can also match the same shadow crossing.

This does not invalidate the policy comparison or the temporal-lead estimand,
but it prevents three stronger claims:

- the 9,694 rows are not 9,694 independent treatment effects;
- lead cannot be summed into DATA, AoI or RMSE benefit;
- the unique-lead transmit/discard certificate is not yet evaluable per
  decision.

The machine-readable readiness verdict therefore keeps
`perDecisionCausalLeadIdentified=false` and `predictiveCertificateReady=false`.

## Research decision and next study

Do not tune another scalar ACK-delay threshold from EXP14F. The next defensible
step is a branch-at-decision replay study:

1. snapshot the complete simulator state immediately before a candidate
   standalone-ACK admission decision;
2. run paired branches with identical future exogenous trace, differing only
   in admit versus suppress/defer for that one decision;
3. stop at the first generation-equivalent piggyback crossing or a fixed local
   horizon;
4. record direct ACK airtime, changed DATA generation/admission/service,
   collision externality, true AoI and control-loss integral;
5. cluster inference by parent seed and pre-register a causal-at-decision
   predictor before a new disjoint validation block.

Because 9,694 full branches are unnecessary and expensive, the branch study
should use a deterministic, preregistered event sample stratified by MAC cell,
causal local-busy bin, pending-obligation age and trigger branch. N20 needs
oversampling through additional development seeds, not reuse of its 20 sparse
events as if they were representative.

## Artifacts

- `lead_events.csv`: event-level generation matches and censor flags.
- `lead_summary.csv`: descriptive lead distribution by cell.
- `paired_policy_contrasts.csv`: run-paired policy outcomes.
- `gates.csv` and `integrity_verdict.json`: integrity evidence.
- `readiness.json`: claim/readiness boundary.
- `frozen_source/`: source snapshot captured before seed opening.
