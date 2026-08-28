# Contribution — one page

For a reader with five minutes: what the paper does, what the evidence is,
and what it does not establish.

---

## The problem in two sentences

A UAV formation holds its shape by exchanging state, and how often it does
so sets the radio budget and, through information staleness, the formation
accuracy. Fixed-rate communication cannot adapt to a network whose quality
is unknown, and a conventional event trigger — which fires on the sender's
own state error — is blind to a receiver whose copy has gone stale because a
packet was lost.

## The mechanism

A sender cannot observe the age of information at a receiver. It can only
infer it from what comes back. Our policy makes that inference the only
source of freshness knowledge, and keeps two memories per directed channel:

| Memory | Advanced by | Governs |
|---|---|---|
| last **transmitted** state | every transmission | **innovation** |
| last **acknowledged** generation time | arriving cumulative ACKs only | **estimated freshness** |

Estimated freshness scales the innovation threshold downward, toward a
floor, as the receiver's copy ages. **Age never triggers on its own** — it
only lowers the bar a genuine state change must clear.

Four branches, differing in which timing gate applies:

| Branch | Fires when | Cooldown | In-flight block |
|---|---|---|---|
| hard new information | innovation exceeds the fixed threshold | no | no |
| adaptive new information | receiver stale **and** innovation exceeds the scaled threshold | no | no |
| refresh / retransmission | receiver stale, nothing new to say | **yes** | **yes** |
| max-silence backstop | silence exceeds the bound | no | no |

**Only the third branch repeats information, so only the third is rate
limited.** That distinction is the contribution. Loss recovery follows from
it with no retransmission timer: an unacknowledged packet stays
outstanding, outstanding packets forbid refresh, and the backstop fires.

## The design evidence

An ablation on common random numbers shows each element is load-bearing
(per-channel Hz, Stressed condition):

| Variant | Clean | Mod. | Str. | Str. RMSE | What it shows |
|---|---|---|---|---|---|
| fixed threshold, open loop | 7.42 | 7.47 | 7.47 | 0.1719 | does not adapt |
| adaptive, open loop | 8.41 | 8.29 | 8.16 | 0.1612 | adapts the **wrong way** |
| dual memory, no split | 8.41 | 9.07 | 9.07 | 0.1545 | rate **pinned**: cannot see a worse network |
| **proposed** | **8.44** | **13.35** | **18.24** | **0.1170** | adaptivity restored |
| ideal-feedback reference | 8.41 | 11.20 | 15.80 | 0.1306 | cheaper **and less accurate** |

No parameter value differs between the pinned variant and the proposed one.
The reference result is why we use it for *information efficiency*, not as
a bound on attainable accuracy.

## The holdout evidence

Pre-registered, 50 seeds never used in development, 3400 runs, 6-DOF
quadrotor followers, paired confidence intervals:

- **Adaptivity:** DATA 84.47 → 134.84 → 182.94 Hz across Clean, Moderate,
  Stressed, one fixed parameterization.
- **Accuracy:** lower RMSE than a state-event trigger in **17 of 17** cells;
  against 10 Hz periodic at Stressed, **−0.0288 m**, CI [−0.0294, −0.0283].
- **Integrity:** 0 divergences, 0 protocol-invariant violations, every
  realisation hash matching a registry fixed before the sweep.

## What this does **not** establish

| Not established | Evidence against over-claiming |
|---|---|
| Any reduction in total radio traffic | DATA −16.73 Hz but ACK-inclusive **+10.67 Hz** vs P20, both intervals excluding zero; cheapest method in **0 of 17** cells |
| Superiority over well-resourced periodic | P20 has lower RMSE in **16 of 17** cells |
| Advantage under broadcast accounting | Moderate non-dominance falls 87.5 % → **25 %** |
| Robustness to plant mismatch | +720 % RMSE at the combined arm — **controller** has no integral action |
| Safety under link or node fault | ~18 % unsafe, **identical across all four methods** |
| Bounded traffic under estimator noise | Clean DATA ×2.34, breaching a pre-registered ×2 bound |
| A rate that is a property of the policy | DATA rate varies 202.9 / 182.9 / 133.0 Hz with Δt = 0.01/0.02/0.04 s |
| Anything on hardware | Simulation only; airtime and broadcast costs are proxies |

Seven pre-registered claims were tested and rejected. All seven are in the
manuscript's Table VI.

## Why the evidence should be believed

Pre-registration before each run; a 50-seed holdout proven disjoint from
every development seed; common random numbers so methods meet the identical
channel; nine runtime protocol invariants; bit-identical serial-versus-parallel
execution; a clean-clone reproduction; and every manuscript number generated
from a persisted result file rather than typed.

## EXP11: the decisive scope refinement

EXP11 changes the network inside one mission while keeping Causal-v3 fixed
and withholding the regime label. All four adjacent DATA-rate differences
have the expected sign. Whole-mission RMSE is lower than P10, and
`Total_w025` is lower than P20 at the pre-registered `w=0.25`.

This supports **mechanistic adaptivity**: one policy changes effort when the
network changes. It does not establish **mission-level Pareto superiority**.
P12.5 remains highly competitive, retaining **97.7% of Causal-v3 accuracy**
at **89.6% of its `Total_w025` cost** and **39.1% of its broadcast cost**.

The contribution after EXP11 is therefore adaptivity under unknown and
changing network conditions with one fixed causal policy, not universal
dominance over tuned periodic communication. EXP11 is supplemental evidence
frozen at `exp11-locked-supplemental`, outside the `simulation-v1.0`
boundary.
