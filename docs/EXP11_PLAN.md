# EXP11 — Within-Run Network Switching / Fixed-Periodic Challenge

**Status:** pre-registered. Written and committed **before** any EXP11 run.
**Branch:** `exp11-dynamic-network`, cut from `simulation-v1.0 @ 32858b1`.
**Relation to the freeze:** EXP11 is the single additional experiment authorised
after `simulation-v1.0`. It is **supplementary evidence, not a revision**. The
`simulation-v1.0` tag is not moved, and no locked result is re-run or re-stated.

---

## 0. The one question EXP11 answers

> "Why not just use, or tune, a periodic rate such as P20?"

Every experiment through EXP10 held network quality **fixed for a whole run**.
Under that design a periodic rate can be selected with knowledge of the single
condition it will ever meet, and the objection is fair as stated.

EXP11 removes that knowledge. One mission passes through Clean → Moderate →
Stressed → Moderate → Clean. The five fixed periodic baselines are never told
which regime is active and their rates cannot change. Whether that matters is
the measurement.

EXP11 does **not** attempt to re-establish any claim that EXP07–EXP10 failed to
establish, and it does not revisit any locked limitation.

---

## 1. Scenario (locked)

| Item | Value | Source |
|---|---|---|
| Swarm size | N = 5 | EXP10 NOMINAL |
| Topology | `ring2` | EXP10 NOMINAL |
| Plant | 6-DOF followers, inner ratio 10 | EXP10 NOMINAL |
| Controller | original (not degree-normalised) | EXP10 NOMINAL |
| Outer step | 0.02 s | locked |
| Inner step | 0.002 s | locked |
| Mission length | **83 s** | new to EXP11 |
| Metric window | t ∈ [8, 83] | `computeSwarmMetrics` evalStart, unchanged |

Every trigger threshold, cooldown, max-silence bound, adaptive-scale parameter
and ACK setting is the frozen EXP10 NOMINAL value, copied verbatim in
`utils/applyExp11Config.m`.

### Timeline

| Interval | Regime | loss | delay |
|---|---|---|---|
| 0 – 23 s | Clean | 0.00 | 0.00 s |
| 23 – 38 s | Moderate | 0.20 | 0.08 s |
| 38 – 53 s | Stressed | 0.40 | 0.12 s |
| 53 – 68 s | Moderate | 0.20 | 0.08 s |
| 68 – 83 s | Clean | 0.00 | 0.00 s |

t ∈ [0, 8) is warm-up and enters **no** metric. The channel is Clean from t = 0;
the warm-up boundary and the first regime boundary are different things.

The three quality levels are the locked EXP05–EXP10 definitions. Jitter is zero,
as in every nominal frozen scenario. Reverse-channel semantics follow the frozen
nominal: zero ACK loss, ACK delay equal to the forward DATA delay at that
instant, no ACK jitter.

**Four switch instants: 23, 38, 53, 68 s.** All are integer multiples of the
0.02 s outer step, so a switch lands exactly on a tick and no transmission
straddles two regimes.

The schedule descends into degradation and returns. A one-way sweep would only
show that a policy notices a network getting worse; the return leg tests whether
it also gives the traffic back.

---

## 2. Methods

| id | family | period | note |
|---|---|---|---|
| `P5` | periodic | 0.20 s | fixed 5 Hz for all 83 s |
| `P10` | periodic | 0.10 s | fixed; H2a reference |
| `P12.5` | periodic | 0.08 s | fixed; fills the P10–P20 gap |
| `P20` | periodic | 0.05 s | fixed; H2b reference |
| `P25` | periodic | 0.04 s | fixed; high-rate end |
| `StateEvent` | event | — | locked state-error trigger, no freshness term |
| `Causal` | causal | — | Causal-AoI-v3, frozen. The proposed method |
| `OraclePeriodic` | oracle | schedule | **non-causal / regime-aware reference** |

**No fixed periodic method is told the regime, and none may change rate at a
switch.** Enforced structurally: a fixed method is given `cfg.net.commPeriod`
only. `cfg.net.periodSchedule` is absent, so `commPeriodAt` returns segment 0 for
the whole run and the transmission grid never re-anchors. Gate G5 checks the runs
that actually happened via `out.periodSwitchTimes`.

P5, P10, P12.5 and P25 have periods that are exact multiples of the outer step.
**P20 does not**: 0.05 s against a 0.02 s step fires on ticks 0.06, 0.10, 0.16,
0.20, …, alternating two- and three-tick gaps at exactly 20 Hz on average. That
is how every locked experiment ran P20, and EXP11 leaves it alone — rounding the
period to the step would turn P20 into a 25 Hz or 16.7 Hz method and break
comparability with the frozen results H2b is stated against.

### Oracle-periodic

Pre-registered map, fixed before any run:

    Clean → P5 (0.20 s), Moderate → P10 (0.10 s), Stressed → P20 (0.05 s)

It may change rate **only** at the four regime boundaries (gate G6). It is
**non-causal**: the regime and the switch times are handed to it, which no
deployable controller has.

**Mandatory labelling wherever it appears: "non-causal / regime-aware
reference".** It is an information-efficiency reference for rate adaptation. It
is **not** an accuracy bound and **not** a performance upper bound — a rate
chosen per regime is not optimal even within the periodic family, let alone over
all policies. **It is never a gate for the proposed method.** If the oracle is
better on either axis, that stands as reported.

---

## 3. Common random numbers

The master realisation is indexed by `seed × physical-time slot × directed link`.
Each slot carries the underlying loss uniform, the delay-jitter primitive and the
ACK primitive, all pre-drawn from the seed before any simulation.

A regime change alters **only the threshold** a pre-drawn uniform is compared
against and the base delay added to a packet. **It generates no new stream and
consumes no draw.** All eight methods at one seed therefore meet the identical
realisation, which is what makes the paired differences paired. Gate G3 checks it
via the exact trace hashes; the negative-control test checks it directly by
comparing hashes across regimes.

Periodic transmission phase uses the EXP10 semantics: one deterministic offset
per (physical sender, payload class), drawn independently of the period so every
rate on the ladder shares one phase realisation. Never per directed link.

---

## 4. Seeds

    exp11Seeds = 26000001:26000050

Holdout. `utils/assertExp11Seeds.m` runs **before** anything is simulated and
raises rather than warns. It asserts disjointness from every seed EXP01–**EXP10**
ever used — including the EXP10 holdout block, enumerated in
`utils/exp11SeedFamilies.m` — and mutual independence of the derived streams.

The seed count is not changed after seeing a confidence interval.

---

## 5. Mission metrics, t ∈ [8, 83]

Formation RMSE, max formation error, min pairwise separation, SafeFail
(minSep < 0.25 m), DATA rate, ACK rate, `Total_w` for w ∈ {0.10, 0.25, 0.50},
airtime proxy (48 B DATA, 24 B ACK), broadcast proxy, true AoI, estimated AoI.

Counts are windowed by differencing the cumulative per-step logs, so the warm-up
is excluded after the fact and the run itself never needs to know where the
metric window starts.

Estimated AoI does not exist for a method without a reverse channel. NaN there
means "this method has no such quantity", not "the value was lost".

---

## 6. Segment metrics

Five 15 s segments: `Clean_1` [8,23), `Moderate_1` [23,38), `Stressed` [38,53),
`Moderate_2` [53,68), `Clean_2` [68,83]. Per segment: RMSE, DATA Hz, ACK Hz,
`Total_w025`, AoI, minSep.

**The two Clean segments and the two Moderate segments are never merged.**
Merging them would erase the return leg, which is half the adaptivity question.

The five segments partition the mission window exactly, so segment DATA counts
sum to the mission DATA count and a reader can check that they do. The cost is
that the final segment holds 751 samples against 750 (15.02 s vs 15.00 s); every
rate is divided by its own counted duration, so the extra sample cannot inflate
it.

Target ordering: `Clean_1 < Moderate_1 < Stressed` and
`Stressed > Moderate_2 > Clean_2`. **`Clean_1 == Clean_2` is not required** —
recovery need not be exact.

---

## 7. Transition diagnostics

DATA rate over 0–1 s, 1–3 s and 3–5 s after each switch, plus the remainder of
the segment the switch opened. Deltas in DATA rate, AoI and RMSE are reported
against the 5 s immediately before the switch.

**No response-time threshold is defined here or anywhere.** None was
pre-registered, and inventing one after seeing the traces is how a diagnostic
turns into a claim. These numbers are descriptive.

---

## 8. Hypotheses

Paired over the 50 seeds, 95 % CI, `nPairs` reported. A CI containing zero
downgrades the claim. Adding seeds after seeing a CI is forbidden.

**H1 — within-run adaptivity, both directions.** The four adjacent segment
DATA-rate differences for Causal-v3 have CIs excluding zero with signs
`+, +, −, −`.

**H2a** — `RMSE(Causal − P10) < 0`. Supported **only if the upper CI bound < 0**.

**H2b** — `Total_w025(Causal − P20) < 0`. Supported **only if the upper CI
bound < 0**.

If one of H2a/H2b fails, **the experiment is not modified.** The failure is
reported.

**H3 — fixed-periodic Pareto frontier.** RMSE against `Total_w025`, seed means,
over P5/P10/P12.5/P20/P25. Causal-v3 is classified NON-DOMINATED or DOMINATED by
the **same 1 % rule EXP07C used**: dominated if some fixed rate achieves
RMSE ≤ 0.99 × its RMSE **and** cost ≤ 0.99 × its cost.

**It is not pre-registered that Causal must win.**

**H4 — oracle gap.** Reported with paired CIs for both RMSE and `Total_w025`.
**No gate in either direction.** If the oracle is better, that is kept as
reported.

---

## 9. Gates

Infrastructure gates. They ask whether the experiment is a valid measurement,
not whether the result is favourable. A gate failure means STOP. An unfavourable
hypothesis outcome does not.

| Gate | Requirement |
|---|---|
| G1 | Zero causal invariant violations |
| G2 | Zero divergence, no unexplained NaN |
| G3 | One channel realisation per seed, identical across all methods |
| G4 | Every seed present exactly once for every method |
| G5 | Fixed periodic rates unchanged across all four switches |
| G6 | Oracle switched only at the four pre-registered boundaries |
| G7 | Negative control passes: a regime reaches the channel only |

---

## 10. Negative control

`tests/test_exp11_regime_semantics.m`. Changing the current network regime must
modify **only** channel loss and delay behaviour. It must **not** modify:

- the Causal trigger threshold
- adaptive-scale parameters
- `maxSilence`
- cooldown / minimum inter-transmission times
- any periodic rate (**except** Oracle-periodic)
- any controller gain

Checked four ways:

1. `netParamsAt` / `ackParamsAt` return channel fields only.
2. Configs built at two very different constant regimes are compared field by
   field across `cfg.aoiEvent`, `cfg.event`, `cfg.causal`, `cfg.sixdof` and the
   whole of `cfg.swarm` — so a gain added later is covered without anyone
   remembering to extend the test.
3. **Source-level guard**: `cfg.net.regime` and `cfg.ack.regime` are read only by
   the allow-listed channel-layer files. Comments are stripped before the scan,
   so channel-layer files that merely *discuss* the regime in their headers stay
   in scope for real reads.
4. A degenerate (constant) regime reproduces a static-channel run **bit for bit**
   — trajectory, DATA count, ACK count and trace hash — which is what licenses
   comparing EXP11 against the frozen fixed-channel results.

Plus: two runs on one seed under different regimes must meet the same
realisation (equal exact trace hashes), while the worse regime does drop more
packets — proving the threshold is live and the stream is not.

---

## 11. Execution policy

1. Run **3 seeds** first as an internal debug pass.
2. **If a technical or infrastructure bug appears → STOP.** Fix it, re-run the
   debug pass.
3. If clean, run the **full 50 seeds unchanged**.
4. **Do not tune.** A bad scientific result is a result. Only the failures listed
   below are grounds to stop.

STOP conditions: CRN or phase mismatch across methods; a locked regression
failure; a gate failure; a missing or duplicated seed; paired-data ambiguity.

**Not** STOP conditions: H2a or H2b unsupported; Causal dominated under H3; the
oracle beating Causal under H4; any segment ordering not matching the target.

---

## 12. Report contents

Commit and branch; test-suite result; run count; H1 ordering with all four CIs;
H2a and H2b means with CIs; the fixed-periodic Pareto table and whether Causal is
dominated; the oracle comparison with CIs and its mandatory label; the
five-segment table; transition diagnostics; safety counts; all invariant
counters.

**If H2 or H3 come out negative, the negative result is kept as it is.**

---

## LOCKED LIMITATIONS — NOT RE-TESTED AWAY

EXP11 changes nothing about the following, and no EXP11 result should be read as
revisiting them:

- The EXP09B/EXP09C **LOCKED PARTIAL** verdicts stand.
- The EXP07C rejection of a **Stressed Pareto superiority** claim stands. EXP11's
  H3 is a separate question asked on a different (time-varying) scenario and is
  not a re-run of that gate.
- The two rate normalisations (EXP07 per-channel Hz vs EXP08+ swarm totals)
  remain as documented. EXP11 reports **swarm totals**.
- EXP11 is N = 5, one topology, one plant configuration, simulation only. It is
  not a scalability, topology, or hardware result.
