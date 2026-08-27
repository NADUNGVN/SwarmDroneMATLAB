# Title and abstract options

## Selected working title

> **Causal ACK-Assisted, AoI-Aware Event-Triggered Communication for UAV
> Swarm Coordination**

In `paper/main.tex`. Twelve words. Carries the four terms that identify the
contribution — *causal*, *ACK-assisted*, *AoI-aware*, *event-triggered* —
and names the application without claiming a property the evidence does not
support.

### Words deliberately excluded

| Excluded | Why |
|---|---|
| **Optimal** | Nothing here is optimised or proved optimal |
| **Robust** | Absolute robustness was tested and **rejected** at three separate boundaries (plant mismatch, link fault, node blackout) |
| **Universal** | P20 has lower error in 16 of 17 cells |
| **Guaranteed** | There is no stability or safety guarantee in this paper |
| **Efficient** | Would imply the traffic claim that the ACK-inclusive cost reverses |

---

## The five candidates that were compared

**T1.** *Causal ACK-Assisted, Age-of-Information-Aware Event-Triggered
Communication for Multi-UAV Formation Control*
— Complete but 15 words, and "Age-of-Information-Aware" is heavy. This was
the v1 title.

**T2.** *Causal AoI-Aware Event-Triggered Communication for Resource-Aware
UAV Swarm Coordination*
— Good, but "resource-aware" twice-modifies and edges toward an efficiency
claim we cannot make unqualified.

**T3.** *ACK-Assisted Freshness Estimation for Event-Triggered Multi-UAV
Formation Communication*
— Foregrounds the estimator, which is the weakest novelty component: ACK-driven
freshness estimation is already established in AoI scheduling.

**T4.** *Separating New Information from Refresh: Causal AoI-Aware
Event-Triggered Swarm Communication*
— Foregrounds the element for which we found **no** prior art, which is
attractive. Rejected because a colon-led title buries the application, and
because the separation only makes sense once the reader knows the setting.

**T5 — SELECTED.** *Causal ACK-Assisted, AoI-Aware Event-Triggered
Communication for UAV Swarm Coordination*
— T1 shortened: "AoI" for the acronym (expanded on first use in the body),
"UAV Swarm Coordination" for the application. Keeps all four identifying
terms.

### Reconsider T4 if a venue wants a sharper hook

If a reviewer or editor finds the title generic, T4 is the fallback: the
new-information/refresh separation is the single most distinctive mechanism
in the paper, and `NOVELTY_GAP_REVIEW.md` records that we found no prior work
applying a repetition cooldown only to repetition.

---

## Abstract

The abstract in `main.tex` is **205 words** (target 180–230) and every
number in it is a generated macro, so it cannot drift from the data.

### Required content, and where it appears

| Required element | Sentence |
|---|---|
| Problem | "Fixed-rate inter-agent communication cannot adapt … while a conventional state-event trigger saves traffic but ignores how stale the receiver's copy has become." |
| Method | "We present a causal ACK-assisted, age-of-information-aware event-triggered communication policy for multi-UAV formation control." |
| Causal-feedback distinction | "estimates its receiver's freshness *only* from cumulative acknowledgements crossing a delayed and lossy reverse channel, never by reading receiver state" |
| One fixed parameterization | "A single fixed parameterization is used throughout." |
| 50-seed holdout accuracy result | "lowers formation error against a 10 Hz periodic baseline in the most impaired condition by −0.0288 m (95 % CI [−0.0294, −0.0283])" |
| Adaptive communication result | "adapts its DATA traffic monotonically with network quality (84.47, 134.84 and 182.94 Hz)" |
| ACK-inclusive cost caveat | "The reduction is *DATA-only*: … DATA falls by −16.73 Hz while the ACK-inclusive total rises by +10.67 Hz, both intervals excluding zero, so no reduction in total radio traffic is claimed." |
| 6-DOF validation scope | "with 6-DOF quadrotor followers" |
| One clear limitation | "Results are simulation only; no hardware validation is claimed." |

### What the abstract deliberately omits

Topology generalisation, link and node faults, plant mismatch, estimator
noise, timestep sensitivity, the design-evolution ablation, and the
oracle-comparison result. All are in the body. An abstract that listed every
experiment would obscure the one message and the one caveat that matter
most.

### The wording rule the abstract must keep

The phrase "communication saving" never appears unqualified. The abstract
says **"The reduction is DATA-only"** and then gives both signed
differences. `paper_audit` rule A6 enforces this mechanically across the
whole manuscript.
