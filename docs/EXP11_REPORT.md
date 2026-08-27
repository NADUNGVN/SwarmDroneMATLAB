# EXP11 Report — Within-Run Network Switching / Fixed-Periodic Challenge

**Verdict: LOCKED SUPPLEMENTAL / REVIEWER-RESPONSE RESULT.**
Post-freeze supplementary evidence. No algorithm change, no EXP12, no rerun to
search for dominance.

**Tag:** `exp11-locked-supplemental` → `7b64af6`
**Branch:** `exp11-dynamic-network`
**Infrastructure commit:** `85ead26` (plan + code, committed before any run)
**Base:** `simulation-v1.0 @ 32858b1` — the tag was **not** moved and **not**
re-tagged. EXP11 is **not** imported back into the release boundary.
**Dataset:** `results/exp11_dynamic_network/2026-08-27_174026/tidy.csv`
(400 rows, 50 seeds × 8 methods, 123 columns)
**Debug pass:** `results/exp11_dynamic_network/2026-08-27_175335/` (24 rows)
**Tests:** `run_all_tests` **10 of 10 PASS** — confirmed twice: once on the
dataset commit `7b64af6`, and again after the documentation-only housekeeping
commit `e606cd3`.

| test | dataset commit `7b64af6` | after housekeeping `e606cd3` |
|---|---|---|
| test_rotation | PASS 0.4 s | PASS 0.4 s |
| test_formation_error | PASS 0.5 s | PASS 0.5 s |
| test_setpoint_interface | PASS 24.6 s | PASS 36.5 s |
| **test_lock_regression** | **PASS 405.0 s** | **PASS 413.2 s** |
| test_causal_invariants | PASS 30.7 s | PASS 33.1 s |
| test_blackout_semantics | PASS 27.0 s | PASS 28.7 s |
| test_mismatch_semantics | PASS 44.3 s | PASS 47.5 s |
| test_estimator_semantics | PASS 32.4 s | PASS 29.6 s |
| test_exp10_infrastructure | PASS 15.9 s | PASS 13.5 s |
| test_exp11_regime_semantics | PASS 78.4 s | PASS 29.2 s |
| **total** | **10/10 in 11.0 min** | **10/10 in 10.5 min** |

`test_lock_regression` passing with the EXP11 channel layer present is the check
that matters here: it reproduces every locked EXP05C / EXP06A / EXP07A value
bit-identically, which is what makes the EXP11 infrastructure additive rather
than a modification of the frozen campaign.
**Gates:** **7 of 7 PASS**
**Runtime:** 400 runs in 6.4 min (16 workers, N = 5)

---

## Formal verdicts, per pre-registration

Each verdict is the outcome of the statistic **as written in
`docs/EXP11_PLAN.md` before any run**. Nothing is reinterpreted after the fact:
where the pre-registration defined a support criterion, the verdict is
SUPPORTED or REJECTED against that criterion; where it explicitly declined to
set a gate, the verdict is CHARACTERIZATION.

| # | Pre-registered statement | Criterion | Verdict |
|---|---|---|---|
| **H1** | Causal-v3 adapts within a run in both directions: four adjacent segment DATA-rate differences with CIs excluding zero, signs `+ + − −` | all four CIs exclude zero on the required side | **SUPPORTED** |
| **H2a** | `RMSE(Causal − P10) < 0` | upper CI bound < 0 | **SUPPORTED** |
| **H2b** | `Total_w025(Causal − P20) < 0` | upper CI bound < 0 | **SUPPORTED** *(at w = 0.25 only — see scope limit)* |
| **H3** | Classify Causal-v3 against the fixed-periodic frontier by the EXP07C 1 % rule. *"It is not pre-registered that Causal must win."* | no gate — classification only | **CHARACTERIZATION** |
| **H4** | Gap to Oracle-periodic. *"No gate in either direction."* | no gate — reported only | **CHARACTERIZATION** |

**H2b — the distinction to preserve.** These two statements are not
interchangeable, and only the first is supported:

- **SUPPORTED:** at w = 0.25, Causal-v3 has a lower paired ACK-weighted total
  cost than P20 **for this EXP11 mission**. (mean −60.460, CI
  [−60.517, −60.402], n = 50.)
- **NOT SUPPORTED:** general ACK-inclusive communication superiority over P20 —
  because the conclusion is **cost-model dependent and reverses under
  broadcast**, where Causal-v3 is 59.7 % *more* expensive (mean +71.653, CI
  [+70.707, +72.599]).

The pre-registered statistic is met exactly as written; what it does not do is
generalise across cost models. See §4 and Appendix A.3.

**H3 outcome.** NON-DOMINATED under the registered cost model (`Total_w025`),
DOMINATED by P20 and P25 under broadcast. Both are reported; neither is a gate
failure, because H3 was registered as a classification.

**H4 outcome.** Causal-v3 is more accurate than the oracle and more expensive
than it; neither dominates the other. Reported as it stands.

---

## Locked interpretation

This is the reading EXP11 is licensed to support. It is fixed here so that later
writing cannot drift into a stronger claim than the data carries.

### SUPPORTED

- **Causal-v3 changes its communication effort in both directions** when network
  degradation and recovery occur inside one mission, **without receiving a regime
  label**.
- **Fixed periodic methods have no regime-adaptation mechanism at all.** Their
  rate is invariant by construction, not merely badly tuned.
- **State-event does not reproduce freshness-driven adaptation.** A state-error
  trigger without a freshness term does not respond to a channel getting worse.

### NOT SUPPORTED

- Causal-v3 **universally dominates** a tuned fixed periodic rate.
- Causal-v3 **guarantees** lower ACK-inclusive cost than P20.
- Causal-v3 has a **broadcast-medium communication advantage**.

### The sentence EXP11 licenses

> A fixed periodic scheduler cannot adapt its transmission effort to
> within-mission network changes because its rate is invariant by construction;
> however, an appropriately chosen fixed rate can still offer a competitive
> mission-level accuracy–cost trade-off.

The result is **stronger about mechanism and weaker about Pareto superiority**
than a naive reading of H1+H2 would suggest.

**EXP11 must not be used to write "periodic cannot perform well under changing
networks."** That sentence is false on this data: P20 and P25 achieve better
mission RMSE than Causal-v3, and P12.5 is within 2.3 % of it at 10.4 % less cost.
What periodic cannot do is *adapt* — which is a statement about mechanism, not
about performance.

**Oracle-periodic is a non-causal / regime-aware reference.** It is never called
a deployable baseline, an upper bound, or an accuracy bound.

---

## 0. Process deviation — read this first

**The pre-registered 3-seed debug pass did not run before the 50-seed sweep.**
Section 11 of `docs/EXP11_PLAN.md` requires three seeds first. What happened is
that the debug hook read `exp11SmokeSeeds` from the base workspace, but
`exp11_dynamic_network.m` is a *script* and therefore shares the caller's
workspace — so its own `clear` on line 1 deleted the hook before line 74 read it.
The selector silently evaluated to "absent" and all 50 seeds ran.

This was a defect in the harness hook, not in the measurement. It has been fixed
(the selector is now the `EXP11_SMOKE_SEEDS` environment variable, which `clear`
cannot touch), the debug pass was then run as specified, and its 24 rows were
compared against the corresponding rows of the 50-seed dataset:

    24 rows x 123 columns = 2952 values compared, 0 mismatches

So the 50-seed dataset is bit-identical to what the pre-registered order would
have produced, and every infrastructure gate the debug pass exists to catch
passed on the full run anyway. The order of evidence was wrong; the evidence is
not compromised. Nothing was re-tuned and no seed was added or dropped.

---

## 1. Gates

| Gate | Result | Detail |
|---|---|---|
| G1 zero causal invariant violations | **PASS** | 0 across 400 runs |
| G2 no divergence, no unexplained NaN | **PASS** | 0 diverged, 0 non-finite RMSE outside divergence |
| G3 one channel realisation per seed, all methods | **PASS** | forward yes, reverse yes |
| G4 every seed present exactly once per method | **PASS** | 50 × 8 |
| G5 fixed periodic rates unchanged across switches | **PASS** | 0 rate changes across the five fixed methods |
| G6 oracle switched only at the four boundaries | **PASS** | exactly 4 per run, all on a boundary |
| G7 negative control: regime reaches the channel only | **PASS** | `test_exp11_regime_semantics` 24/24 |

G5 and G6 are the two that matter for the objection being answered: the fixed
rates provably never adapted, and the oracle provably adapted only where it was
licensed to.

---

## 2. H1 — within-run adaptivity, both directions: **SUPPORTED**

Adjacent segment differences in swarm DATA rate, paired over 50 seeds, n = 50 on
every interval.

**Causal-v3**

| difference | required | mean [Hz] | 95 % CI | verdict |
|---|---|---|---|---|
| Moderate_1 − Clean_1 | > 0 | **+39.965** | [+39.743, +40.188] | SUPPORTED |
| Stressed − Moderate_1 | > 0 | **+43.095** | [+42.870, +43.320] | SUPPORTED |
| Moderate_2 − Stressed | < 0 | **−41.404** | [−41.583, −41.225] | SUPPORTED |
| Clean_2 − Moderate_2 | < 0 | **−41.594** | [−41.771, −41.417] | SUPPORTED |

All four CIs exclude zero on the required side. Causal-v3 raises its rate as the
network degrades and gives the traffic back as it recovers, within one mission,
without ever being told the regime.

**Every fixed periodic method is flat**, as designed: all four differences are
0.000 Hz to three decimals for P10 and P20 (the residual ±0.01 Hz on the last
interval is the one extra sample in the closed final segment, not adaptation).

**State-event moves the wrong way.** Its four differences are −0.189, −0.284,
+1.333, +0.177 Hz — the rate *falls* slightly entering degradation and *rises*
leaving it, the opposite of what is needed, and all four CIs exclude zero on the
wrong side. A state-error trigger with no freshness term does not see a channel
getting worse; it only sees the error that has already happened.

**Oracle-periodic** switches by construction (+49.9, +99.9, −99.9, −49.9 Hz).
That is the schedule it was handed, not a discovery.

### Transition diagnostics (Causal-v3, descriptive only)

| switch | 0–1 s | 1–3 s | 3–5 s | remainder |
|---|---|---|---|---|
| 23 s Clean→Moderate | +40.3 | +35.2 | +38.1 | +40.8 |
| 38 s Moderate→Stressed | +38.4 | +42.3 | +42.0 | +42.4 |
| 53 s Stressed→Moderate | −34.4 | −40.0 | −41.2 | −42.8 |
| 68 s Moderate→Clean | −40.0 | −41.1 | −40.4 | −40.8 |

ΔDATA Hz against the 5 s before the switch. Most of the rate change is present
within the first second at every one of the four switches. **No response-time
threshold is defined**, here or anywhere: none was pre-registered, and defining
one now would convert a diagnostic into a claim.

---

## 3. H2 — against the two fixed rates the frozen results named

| | mean | 95 % CI | n | verdict |
|---|---|---|---|---|
| **H2a** RMSE(Causal − P10) | **−0.01081** | [−0.01106, −0.01057] | 50 | **SUPPORTED** |
| **H2b** Total_w025(Causal − P20) | **−60.460** | [−60.517, −60.402] | 50 | **SUPPORTED** |

Seed means: RMSE — Causal 0.08147, P10 0.09228, P20 0.07040.
Total_w025 — Causal 139.54, P10 100.00, P20 200.00.

Both hypotheses are supported as written. **They are not a joint claim of
superiority, and should not be read as one:** H2a beats P10 on accuracy while
spending 39 % more, and H2b beats P20 on cost while being 16 % worse on accuracy.
Causal-v3 sits *between* P10 and P20 on both axes. Anyone quoting H2a and H2b
together as "better and cheaper" would be selecting a different comparator per
axis.

---

## 4. H3 — the fixed-periodic Pareto frontier

Seed means, n = 50.

| method | RMSE | Total_w025 | broadcast [Hz] |
|---|---|---|---|
| P5 | 0.13766 | 50.00 | 30.00 |
| P10 | 0.09228 | 100.00 | 60.00 |
| P12.5 | 0.08342 | 125.01 | 75.00 |
| P20 | 0.07040 | 200.00 | 120.00 |
| P25 | 0.06573 | 249.99 | 150.00 |
| State-event | 0.16454 | 38.51 | 23.11 |
| **Causal-v3** | **0.08147** | **139.54** | **191.65** |
| Oracle-periodic *(non-causal / regime-aware reference)* | 0.08931 | 99.86 | 59.92 |

**Registered verdict (RMSE vs Total_w025): NON-DOMINATED.** No fixed rate reaches
both RMSE ≤ 0.99 × 0.08147 and cost ≤ 0.99 × 139.54. All five fixed rates are
themselves non-dominated, so the frontier is a clean monotone accuracy-for-cost
trade with no wasted rate.

Causal-v3 does not dominate anything either. "Non-dominated" here means "on the
frontier", not "ahead of it".

### 4.1 P12.5 — the counterexample, stated up front

**A single appropriately chosen fixed rate gets within 2.3 % of Causal-v3's
accuracy for 10.4 % less cost.** This is not an appendix detail; it is the
strongest argument *against* reading EXP11 as a superiority result, and it
belongs in the main text of anything EXP11 supports.

| Causal-v3 − P12.5, paired, n = 50 | mean | 95 % CI | relative to P12.5 |
|---|---|---|---|
| RMSE | **−0.00195** | [−0.00213, −0.00177] | **−2.3 %** |
| Total_w025 | **+14.532** | [+14.474, +14.589] | **+11.6 %** |
| DATA Hz | −8.734 | [−8.795, −8.672] | −7.0 % |
| broadcast Hz | **+116.649** | [+115.702, +117.596] | **+155.5 %** |

Read as accuracy per unit cost: P12.5 delivers **97.7 %** of Causal-v3's accuracy
for **89.6 %** of its `Total_w025` cost — and for **39.1 %** of its broadcast cost.
Every one of those CIs is tight and excludes zero, so this is not a marginal
sampling artefact.

P12.5 survives the 1 % dominance rule only because it is 2.3 % *worse* on RMSE.
The rule is doing real work here, and a reader is entitled to know that the
"NON-DOMINATED" verdict rests on a 2.3 % accuracy margin bought with an 11.6 %
cost premium — a trade a system designer might well decline.

What P12.5 cannot do is adapt. Its rate is 125.0 Hz in Clean, in Moderate, in
Stressed, in Moderate again and in Clean again (see §6). That is the distinction
EXP11 actually establishes, and it is a statement about mechanism, not about
mission-level performance.

### The cost model changes the answer — and one model reverses it

The pre-registration fixed H3 on `Total_w025`. Reporting only that would be
misleading, so the same 1 % rule was applied under every cost model EXP07C
defined:

| cost model | Causal cost | verdict | dominated by |
|---|---|---|---|
| DATA only | 116.27 | NON-DOMINATED | — (Causal dominates P12.5) |
| Total w=0.10 | 125.58 | NON-DOMINATED | — |
| **Total w=0.25 (registered)** | **139.54** | **NON-DOMINATED** | — |
| Total w=0.50 | 162.80 | NON-DOMINATED | — |
| airtime (48 B / 24 B) | 7814.59 | NON-DOMINATED | — |
| **broadcast** | **191.65** | **DOMINATED** | **P20, P25** |

**Under the broadcast cost model Causal-v3 is dominated by both P20 and P25.**
This is a genuine negative result and is not defended away.

The mechanism is not subtle. On a broadcast medium one radio transmission serves
every listener, so a periodic sender pays once per tick regardless of how many
neighbours hear it — P20's broadcast cost is 120 Hz against its 200 Hz of
directed DATA. Causal-v3 triggers **per directed link**, so its senders fire on
more distinct ticks (98.6 Hz of broadcasts for 116.3 Hz of DATA), and every
accepted DATA packet draws a **unicast ACK** that no broadcast can share
(+93.1 Hz). The reverse channel that makes the freshness estimate causal is
precisely what makes the method expensive when the forward channel is free to
share.

Consistent with that: the saving against P20 shrinks monotonically as the ACK
weight rises — DATA-only −41.9 %, w=0.10 −37.2 %, w=0.25 −30.2 %, w=0.50 −18.6 %,
airtime −18.6 % — and then flips to **+59.7 % (worse)** under broadcast. Every one
of those CIs excludes zero.

---

## 5. H4 — gap to Oracle-periodic (reported, no gate)

Oracle-periodic is a **non-causal / regime-aware reference**: the regime and the
four switch times are handed to it, which no deployable controller has. It is an
information-efficiency reference for rate adaptation — **not** an accuracy bound
and **not** a performance upper bound. Its rate map (Clean→P5, Moderate→P10,
Stressed→P20) was fixed before any run and was not optimised, so a better
regime-aware schedule certainly exists.

| | mean | 95 % CI | n |
|---|---|---|---|
| RMSE(Causal − Oracle) | **−0.00784** | [−0.00798, −0.00770] | 50 |
| Total_w025(Causal − Oracle) | **+39.675** | [+39.617, +39.732] | 50 |

**Causal-v3 is more accurate than the oracle and more expensive than it.** Neither
dominates the other under the registered cost model. Under the broadcast model the
oracle is far cheaper (59.9 vs 191.7) while still 9.6 % less accurate, so it does
not dominate there either.

The more informative comparison is the oracle against fixed P10 at essentially
equal cost (99.86 vs 100.00): RMSE 0.08931 vs 0.09228, a **3.2 %** improvement.
Perfect regime knowledge, spent only on choosing a rate per regime, buys very
little. Causal-v3's 11.7 % improvement over P10 at 39.5 % higher cost comes from
responding *within* a regime, not from knowing which regime it is in. That is the
substantive finding of H4, and it cuts both ways: it supports the value of
per-link responsiveness, and it undercuts any suggestion that the gain here is
mainly about rate scheduling.

---

## 6. Five-segment table (seed means, n = 50)

DATA Hz / RMSE per segment. Full table for all eight methods is in the run log;
the four arms the hypotheses name:

| method | Clean_1 | Moderate_1 | Stressed | Moderate_2 | Clean_2 |
|---|---|---|---|---|---|
| **Causal DATA Hz** | 83.33 | 123.30 | **166.39** | 124.99 | 83.40 |
| **Causal RMSE** | 0.04142 | 0.08555 | 0.11558 | 0.09250 | 0.04734 |
| P10 DATA Hz | 100.00 | 100.00 | 100.00 | 100.00 | 100.01 |
| P10 RMSE | 0.03620 | 0.09199 | 0.14136 | 0.10419 | 0.04441 |
| P20 DATA Hz | 200.00 | 200.00 | 200.00 | 200.00 | 199.99 |
| P20 RMSE | 0.02546 | 0.07114 | 0.10820 | 0.07971 | 0.03189 |
| State-event DATA Hz | 38.27 | 38.08 | **37.79** | 39.13 | 39.30 |
| State-event RMSE | 0.08217 | 0.16191 | 0.24809 | 0.17960 | 0.09227 |

The pre-registered ordering target holds for Causal-v3 in both directions:
`Clean_1 (83.3) < Moderate_1 (123.3) < Stressed (166.4)` and
`Stressed (166.4) > Moderate_2 (125.0) > Clean_2 (83.4)`.

Recovery is close to exact but not required to be: Clean_2 DATA is 83.40 against
Clean_1's 83.33 Hz (+0.08 %), while Clean_2 RMSE is 0.04734 against 0.04142
(+14 %) — the formation carries residual error out of the disturbed segments that
the restored channel does not immediately erase. The two Clean segments and the
two Moderate segments were never merged, which is what makes that visible.

---

## 7. Safety

Minimum pairwise separation over t ∈ [8, 83]; failure is minSep < 0.25 m.
Reported as counts over the seed block, not as a t interval: a failure rate is a
proportion, not a mean.

| method | failures | minSep mean | minSep worst |
|---|---|---|---|
| P5 | **1 / 50** | 0.326 | 0.233 |
| P10 | 0 / 50 | 0.415 | 0.381 |
| P12.5 | 0 / 50 | 0.432 | 0.421 |
| P20 | 0 / 50 | 0.460 | 0.451 |
| P25 | 0 / 50 | 0.469 | 0.463 |
| **State-event** | **18 / 50** | 0.254 | 0.183 |
| **Causal-v3** | **0 / 50** | 0.451 | 0.436 |
| Oracle-periodic | 0 / 50 | 0.460 | 0.450 |

This is the clearest separation in the experiment, and it is not about cost. The
two cheapest methods are the two that fail: State-event at 38.5 Hz fails on 36 %
of seeds, P5 at 50.0 Hz on one. Causal-v3 has zero failures with a worst-case
separation (0.436 m) statistically indistinguishable from P20's (0.451 m) at
30 % less `Total_w025` cost. State-event's mean minSep (0.254 m) is barely above
the failure threshold itself.

---

## 8. Counters

| method | invariant violations | drops | rate changes | diverged |
|---|---|---|---|---|
| P5 | 0 | 29 951 | 0 | 0 |
| P10 | 0 | 59 698 | 0 | 0 |
| P12.5 | 0 | 74 993 | 0 | 0 |
| P20 | 0 | 119 967 | 0 | 0 |
| P25 | 0 | 149 386 | 0 | 0 |
| State-event | 0 | 22 700 | 0 | 0 |
| Causal-v3 | 0 | 86 985 | 0 | 0 |
| Oracle-periodic | 0 | 89 884 | **200** | 0 |

Oracle rate changes = 50 seeds × 4 boundaries, exactly. Every other method: zero.

---

## 9. What EXP11 does and does not establish

**Establishes, on this scenario:**

1. Causal-v3 tracks a network that changes within a run, **in both directions**,
   with no regime knowledge (H1, four CIs excluding zero).
2. A fixed periodic rate cannot do this at all — not because it is badly tuned,
   but because the mechanism does not exist. Every fixed rate is flat to three
   decimals across all four switches.
3. A state-error trigger without a freshness term does not do it either, and
   moves slightly the *wrong* way.
4. Causal-v3 is on the fixed-periodic Pareto frontier under DATA-only, all three
   `Total_w` models and airtime; it is more accurate than P10 and cheaper than
   P20; and it is the only sub-100 Hz-DATA method with zero safety failures.

**Does not establish, and the report says so:**

1. **Any claim of dominating a tuned fixed rate.** Causal-v3 dominates nothing
   under the registered cost model, and P12.5 gets 97.7 % of its accuracy for
   89.6 % of its cost.
2. **A communication saving under a broadcast medium.** Under the broadcast cost
   model Causal-v3 is *dominated* by P20 and P25, driven by per-link triggering
   plus the unicast ACK channel. This is reported, not defended.
3. **That regime knowledge is worth little in general.** The oracle's rate map was
   pre-registered, not optimised; a better regime-aware schedule exists.
4. Anything about N > 5, other topologies, other plants, or hardware. EXP11 is
   N = 5, ring2, 6-DOF, simulation only.
5. **That periodic scheduling performs badly under a changing network.** It does
   not. P20 and P25 achieve better mission RMSE than Causal-v3, and P12.5 comes
   within 2.3 % of it for 10.4 % less cost. The claim EXP11 supports is about the
   absence of an adaptation *mechanism*, not about poor performance.

The one sentence that carries all of this without overreaching is the licensed
statement at the top of this report: a fixed periodic scheduler cannot adapt its
transmission effort to within-mission network changes because its rate is
invariant by construction; however, an appropriately chosen fixed rate can still
offer a competitive mission-level accuracy–cost trade-off.

---

## Appendix A — Exact 50-seed statistics

All from `results/exp11_dynamic_network/2026-08-27_174026/tidy.csv`.
Paired over the 50 holdout seeds `26000001:26000050`.
`t(0.975, 49) = 2.0095752`. Every interval below has `nPairs = 50`,
`nDropped = 0`, `complete = true` — no run diverged, so no pair was lost.

### A.1 H1 — Causal-v3 adjacent segment DATA-rate differences [Hz]

| difference | mean | std | SE | CI95 lo | CI95 hi | required | verdict |
|---|---|---|---|---|---|---|---|
| Moderate_1 − Clean_1 | **+39.9653** | 0.7835 | 0.1108 | +39.7427 | +40.1880 | > 0 | SUPPORTED |
| Stressed − Moderate_1 | **+43.0947** | 0.7912 | 0.1119 | +42.8698 | +43.3195 | > 0 | SUPPORTED |
| Moderate_2 − Stressed | **−41.4040** | 0.6314 | 0.0893 | −41.5834 | −41.2246 | < 0 | SUPPORTED |
| Clean_2 − Moderate_2 | **−41.5939** | 0.6218 | 0.0879 | −41.7706 | −41.4171 | < 0 | SUPPORTED |

Same four differences for the other arms (mean [Hz], for contrast):

| method | Mod_1−Cln_1 | Str−Mod_1 | Mod_2−Str | Cln_2−Mod_2 |
|---|---|---|---|---|
| P10 | +0.000 | +0.000 | +0.000 | +0.011 |
| P20 | +0.000 | +0.000 | +0.000 | −0.008 |
| State-event | **−0.189** | **−0.284** | **+1.333** | **+0.177** |
| Oracle-periodic | +49.856 | +99.885 | −99.885 | −49.923 |

State-event's four CIs are [−0.213, −0.166], [−0.345, −0.223], [+1.244, +1.423],
[+0.121, +0.232] — all exclude zero on the **wrong** side.

### A.2 H2a and H2b

| statistic | mean | std | SE | CI95 | verdict |
|---|---|---|---|---|---|
| **H2a** RMSE(Causal − P10) | **−0.010813** | 0.000851 | 0.000120 | [−0.011055, −0.010571] | SUPPORTED |
| **H2b** Total_w025(Causal − P20) | **−60.459811** | 0.202172 | 0.028591 | [−60.517267, −60.402354] | SUPPORTED (w = 0.25 only) |

### A.3 H3 — full fixed-periodic Pareto table, all cost models

Seed means, n = 50.

| method | RMSE | w=0.10 | w=0.25 | w=0.50 | airtime [B/s] | broadcast [Hz] | DATA [Hz] | ACK [Hz] |
|---|---|---|---|---|---|---|---|---|
| P5 | 0.13766 | 50.003 | 50.003 | 50.003 | 2400.17 | 30.001 | 50.003 | 0.000 |
| P10 | 0.09228 | 100.002 | 100.002 | 100.002 | 4800.10 | 60.001 | 100.002 | 0.000 |
| **P12.5** | **0.08342** | **125.007** | **125.007** | **125.007** | **6000.33** | **75.003** | **125.007** | **0.000** |
| P20 | 0.07040 | 199.998 | 199.998 | 199.998 | 9599.92 | 119.999 | 199.998 | 0.000 |
| P25 | 0.06573 | 249.995 | 249.995 | 249.995 | 11999.78 | 149.998 | 249.995 | 0.000 |
| State-event | 0.16454 | 38.514 | 38.514 | 38.514 | 1848.66 | 23.114 | 38.514 | 0.000 |
| **Causal-v3** | **0.08147** | **125.579** | **139.539** | **162.804** | **7814.59** | **191.652** | **116.273** | **93.061** |
| Oracle-periodic *(non-causal / regime-aware reference)* | 0.08931 | 99.864 | 99.864 | 99.864 | 4793.47 | 59.919 | 99.864 | 0.000 |

Causal-v3 classified by the EXP07C 1 % rule under each cost model:

| cost model | Causal cost | classification | dominated by | Causal dominates |
|---|---|---|---|---|
| DATA only | 116.273 | NON-DOMINATED | — | P12.5 |
| w = 0.10 | 125.579 | NON-DOMINATED | — | — |
| **w = 0.25 (registered)** | **139.539** | **NON-DOMINATED** | — | — |
| w = 0.50 | 162.804 | NON-DOMINATED | — | — |
| airtime | 7814.59 | NON-DOMINATED | — | — |
| **broadcast** | **191.652** | **DOMINATED** | **P20, P25** | — |

Paired Causal-v3 − P20 under every cost model, n = 50:

| cost model | mean | CI95 | relative to P20 | direction |
|---|---|---|---|---|
| DATA only | −83.725 | [−83.786, −83.665] | −41.9 % | lower |
| w = 0.10 | −74.419 | [−74.477, −74.362] | −37.2 % | lower |
| w = 0.25 | −60.460 | [−60.517, −60.402] | −30.2 % | lower |
| w = 0.50 | −37.195 | [−37.262, −37.127] | −18.6 % | lower |
| airtime | −1785.335 | [−1788.596, −1782.074] | −18.6 % | lower |
| **broadcast** | **+71.653** | **[+70.707, +72.599]** | **+59.7 %** | **HIGHER** |

The monotone decay and then sign reversal is the whole story: the advantage is a
function of how cheaply the reverse channel is priced, and a broadcast medium
prices it at full cost while making the forward channel nearly free.

### A.4 H4 — Causal-v3 versus Oracle-periodic

Oracle-periodic is a **non-causal / regime-aware reference**, not a deployable
baseline. Its rate map (Clean→P5, Moderate→P10, Stressed→P20) was fixed before
any run and was not optimised.

| statistic | mean | std | SE | CI95 |
|---|---|---|---|---|
| RMSE(Causal − Oracle) | **−0.007841** | 0.000480 | 0.000068 | [−0.007978, −0.007705] |
| Total_w025(Causal − Oracle) | **+39.674553** | 0.203319 | 0.028754 | [+39.616771, +39.732336] |

Reference point, oracle against fixed P10 at essentially equal cost
(99.864 vs 100.002): RMSE 0.08931 vs 0.09228, a **3.2 %** improvement. Perfect
regime knowledge spent only on selecting a rate per regime buys very little.

---

## LOCKED LIMITATIONS — NOT RE-TESTED AWAY

- EXP09B and EXP09C remain **LOCKED PARTIAL**. EXP11 does not revisit them.
- The EXP07C rejection of a **Stressed Pareto superiority** claim stands. H3 is a
  different question on a time-varying scenario, not a re-run of that gate — and
  its broadcast-model result points the same way EXP07C did.
- Rate normalisation is **swarm totals** (EXP08+ convention), not per-channel Hz.
- `simulation-v1.0` is unchanged. EXP11 is supplementary evidence on a separate
  branch.
