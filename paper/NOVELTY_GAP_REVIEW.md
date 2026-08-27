# Near-neighbour novelty stress test

**Verdict: NO NOVELTY CONFLICT.** No verified prior work found combines
causal ACK-confirmed receiver freshness, state innovation, age-based
threshold adaptation, and event-triggered multi-agent communication in
essentially the same way. The reasoning, the evidence, and the limits of
that search are below.

This document is deliberately structured so that a reader can overturn the
verdict: each near neighbour is listed with what it *does* have, and the
specific element it lacks is named rather than asserted away.

---

## 1. The question being tested

Our mechanism is a four-way combination:

| # | Element | Where it lives in our method |
|---|---|---|
| E1 | **Causal ACK-confirmed receiver freshness** — the sender's freshness estimate advances *only* when a cumulative acknowledgement arrives | `ackGenTime`, advanced in exactly one place |
| E2 | **State innovation against the last *transmitted* state** | `sentPos/sentVel`, dual memory |
| E3 | **Age modulates the innovation threshold** multiplicatively, with a floor; age alone never triggers | adaptive scale `s(t)` |
| E4 | **Event-triggered multi-agent communication** over a formation neighbour graph | per-directed-channel trigger |
| E5 | **New information separated from refresh**, cooldown and in-flight suppression applied only to refresh | branch semantics |

The conflict test: *does a verified prior paper already do E1+E2+E3+E4 in
substantially the same way?*

E5 is treated separately. It is the element for which we found no prior
art at all, and we state that as "we did not find", not as "does not
exist".

## 2. Near-neighbour comparison

Legend: **Y** yes / present, **n** no / absent, **~** partial or
different-in-kind, **—** not applicable.

| Paper | AoI / freshness | Event trigger | ACK / feedback used | Receiver-state knowledge | Causal or oracle | Adaptive threshold | In-flight suppression | Loss + delay modelled | Multi-agent | UAV swarm | Comms cost priced | Physical dynamics | Real hardware | Key difference from our work |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Mamduhi et al. 2020 `10.3390/jsan9030043` | **Y** | **Y** | n | scheduler-side metric | oracle-ish (network-side) | ~ | n | Y | ~ multi-**loop** | n | ~ | Y (plants) | n | Closest AoI+event combination, but it co-designs a **network scheduler across independent control loops**; there is no sender that estimates its own receiver's freshness from ACKs, and no innovation-vs-refresh split |
| Tripathi et al. 2023 (WiSwarm) `10.1109/INFOCOM53939.2023.10228860` | **Y** | n | ~ (scheduler feedback) | centralised scheduler | — | n | n | Y | **Y** | **Y** | ~ | Y | **Y** | Closest on application. A **centralised AoI-based scheduler** allocates the channel; there is no distributed state-innovation trigger and no per-sender freshness memory. Has the hardware we lack |
| Ceran et al. 2019 `10.1109/TWC.2019.2899303` | **Y** | n | **Y** (ACK/NACK) | inferred from ACK | **causal** | n | ~ (HARQ) | Y | n | n | Y (resource constraint) | n | n | Has E1 in spirit: ACK-driven, causal, no oracle. But single source-destination **AoI-optimal scheduling**; no state innovation, no multi-agent, no control loop |
| Rajaraman et al. 2021 `10.1109/JSAC.2021.3065061` | **Y** | ~ | n | assumed | oracle | ~ | n | Y | n | n | Y | n | n | Goes beyond pure age by adding a **quality/content** term — conceptually adjacent to our innovation-times-age composition — but as a remote-estimation/scheduling formulation, not a multi-agent event trigger |
| Ayan et al. 2019 `10.1145/3302509.3311050` | **Y** | ~ | n | scheduler-side | oracle | n | n | Y | ~ multi-loop | n | Y | Y | n | Establishes that age alone is a poor control proxy and proposes value-of-information instead; **centralised cellular scheduling**, not a distributed sender policy |
| Tang et al. 2022 `10.1109/LCOMM.2021.3125669` | **Y** | n | n | assumed | oracle | n | n | Y | n | n | Y | n | n | Index-based centralised AoI scheduling; no trigger, no agents |
| Dimarogonas et al. 2012 `10.1109/TAC.2011.2174666` | n | **Y** | n | none | **causal** | n | n | ~ | **Y** | n | ~ | n | n | Canonical distributed event trigger on **local state error only**; entirely blind to receiver staleness — this is our baseline |
| Seyboth et al. 2013 `10.1016/j.automatica.2012.08.042` | n | **Y** | n | none | causal | ~ (time-dependent) | n | ~ | **Y** | n | Y (broadcast count) | n | n | Event-based broadcasting for consensus; threshold decays with time, not with receiver freshness |
| Girard 2015 `10.1109/TAC.2014.2366855` | n | **Y** | n | none | causal | **Y** | n | n | ~ | n | n | n | n | Dynamic threshold precedent, but driven by an **internal auxiliary variable**, not by any estimate of what a receiver holds |
| Yi et al. 2017 `10.1109/CDC.2017.8264666` | n | **Y** | n | none | causal | **Y** | n | ~ | **Y** | n | ~ | n | n | Dynamic triggering in the distributed setting; still no freshness term |
| Nowzari et al. 2019 `10.1016/j.automatica.2019.03.009` | n | **Y** | n | none | causal | ~ | n | ~ | **Y** | n | Y | n | n | Survey of the field we extend; documents that freshness is not a standard ingredient |
| Yin et al. 2023 `10.1016/j.isatra.2023.01.018` | n | **Y** | n | none | causal | ~ | n | Y (directed topology) | **Y** | **Y** | ~ | Y | n | Event-triggered **multi-UAV formation** — so our contribution is *not* the absence of event-triggered UAV work. No freshness estimate, no ACK channel |
| Ji et al. 2023 `10.1177/01423312221151193` | n | **Y** | n | none | causal | **Y** (dynamic) | n | **Y** (delay) | **Y** | **Y** | ~ | Y | n | Handles communication delay in ET UAV formation, but the trigger never asks how stale the receiver's copy is |
| Chen et al. 2024 `10.1016/j.jfranklin.2024.106997` | n | **Y** | n | none | causal | ~ | n | Y | **Y** | **Y** | ~ | Y | n | Recent ET multi-UAV formation tracking with disturbances; same structural gap |
| Yang et al. 2025 `10.1016/j.dt.2025.04.004` | n | **Y** | n | none | causal | ~ | n | Y | **Y** | **Y** | ~ | Y | n | ET UAV swarm with connectivity and collision constraints; no freshness, no reverse channel |
| Ramesh et al. 2013 `10.1109/TAC.2013.2251791` | n | ~ | n | scheduler-side | ~ | n | n | Y | ~ multi-loop | n | Y | Y | n | State-based scheduling is prior art for state-dependent transmission, but centralised and without freshness |
| Demirel et al. 2017 `10.1109/TAC.2016.2606590` | n | **Y** | n | none | causal | n | n | Y | n | n | **Y** | Y | n | Explicitly studies the communication-versus-control-cost trade-off, which supports our multi-cost-model reporting; single loop |

## 3. Column-by-column novelty accounting

**E1 — causal ACK-confirmed receiver freshness.** *Precedented, but not in
our setting.* The AoI-ARQ literature (Ceran et al. 2019) already drives
transmission from ACK/NACK feedback without oracle knowledge. What we
did not find is that mechanism inside a **multi-agent formation trigger**,
where each sender maintains a per-directed-channel confirmed-freshness
memory.

**E2 — innovation against the last transmitted state.** *Standard* in
event-triggered control. Our specific point — that measuring innovation
against the last *acknowledged* state instead causes over-transmission
under a round trip — is, as far as we found, not documented; we present it
as a measured design failure of our own first iteration rather than as a
gap in the literature.

**E3 — age modulating the innovation threshold.** *Adjacent precedent
exists.* Dynamic and adaptive thresholds are well established (Girard
2015; Yi et al. 2017; Ji et al. 2023), and combining age with a content
term has been done (Rajaraman et al. 2021). We did not find a threshold
modulated specifically by an **ACK-derived estimate of receiver age**.

**E4 — event-triggered multi-agent communication.** *Thoroughly
precedented*, including for UAV formations with flight experiments. We
must not, and do not, claim novelty here.

**E5 — new information separated from refresh.** *No prior art found.*
Repetition-suppression and duplicate-suppression exist in networking, and
minimum inter-event times are standard in event-triggered control, but we
found no work that applies a repetition cooldown **only** to
retransmission traffic while exempting genuinely new information, and
identifies the conflation as the cause of lost adaptivity. This is the
element our design-evolution ablation isolates.

## 4. What we therefore may and may not claim

**May claim:** the combination E1+E2+E3+E4 as realised here, the E5
semantic separation, the quantified demonstration that an acausal oracle
is an information-efficiency reference rather than an accuracy bound, and
the pre-registered evaluation with a 50-seed holdout and preserved
negative results.

**May not claim:** novelty of event-triggered multi-agent control, of
AoI as a metric, of ACK-driven scheduling, of adaptive thresholds, or of
event-triggered UAV formation control. **Must not use "first" or
"first-ever" for anything in this paper** — the search below is not
exhaustive enough to support such a word, and the audit forbids it.

## 5. Limits of this search — stated so the verdict can be re-tested

1. **Coverage.** Crossref-indexed, English-language venues, reached via
   the queries logged in `LITERATURE_SEARCH_LOG.md`. Work published only
   in non-indexed proceedings, in other languages, or in patents was not
   systematically searched. One patent-family result surfaced incidentally
   and was not pursued.
2. **Query dependence.** A mechanism described in different vocabulary —
   for instance "retransmission-aware triggering", "duplicate suppression
   for networked control", or a scheduling paper that happens to contain
   the same branch logic — could have been missed.
3. **Recency.** Items posted very recently, or preprints not yet indexed,
   are under-covered. Several 2026 preprints appeared in the discovery
   searches and were **not** used as evidence because they are not
   peer-reviewed.
4. **Depth.** For most near neighbours the assessment rests on the
   abstract and the verified metadata rather than a full reading. Two
   entries (Mamduhi et al. 2020; Tripathi et al. 2023) were examined more
   closely because they are the closest.
5. **Asymmetry of evidence.** Absence of a matching paper in this search
   is weak evidence of absence. The verdict is "no conflict **found**",
   which is the strongest claim the method supports.

## 6. Re-test trigger

If any of the following turns up, this verdict must be revisited before
submission:

- a paper where a **sender in a multi-agent system** estimates receiver
  age from acknowledgements and uses it to scale a state-error threshold;
- a paper that separates new-information from refresh traffic and applies
  a rate limit only to the latter;
- a paper that reports an acausal-oracle freshness baseline being
  *outperformed on control error* by a causal policy.

The third would not conflict with our method, but it would remove the
novelty of our most surprising reported result.
