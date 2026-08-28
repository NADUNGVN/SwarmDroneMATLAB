# EXP11 Report — Within-Run Network Switching / Fixed-Periodic Challenge

**Branch:** `exp11-dynamic-network`
**Infrastructure commit:** `85ead26` (plan + code, committed before any run)
**Base:** `simulation-v1.0 @ 32858b1` — the tag was **not** moved
**Dataset:** `results/exp11_dynamic_network/2026-08-27_174026/tidy.csv`
(400 rows, 50 seeds × 8 methods, 123 columns)
**Debug pass:** `results/exp11_dynamic_network/2026-08-27_175335/` (24 rows)
**Tests:** `run_all_tests` 10 of 10 PASS, `test_lock_regression` included
**Gates:** **7 of 7 PASS**
**Runtime:** 400 runs in 6.4 min (16 workers, N = 5)

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

Causal-v3 does not dominate anything either, and the margin is thin: **P12.5 buys
97.7 % of Causal's accuracy for 89.6 % of its cost** (paired: Causal − P12.5 is
−0.00195 RMSE, CI [−0.00213, −0.00177], and +14.53 cost, CI [+14.47, +14.59]).
"Non-dominated" here means "on the frontier", not "ahead of it".

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

---

## LOCKED LIMITATIONS — NOT RE-TESTED AWAY

- EXP09B and EXP09C remain **LOCKED PARTIAL**. EXP11 does not revisit them.
- The EXP07C rejection of a **Stressed Pareto superiority** claim stands. H3 is a
  different question on a time-varying scenario, not a re-run of that gate — and
  its broadcast-model result points the same way EXP07C did.
- Rate normalisation is **swarm totals** (EXP08+ convention), not per-channel Hz.
- `simulation-v1.0` is unchanged. EXP11 is supplementary evidence on a separate
  branch.
