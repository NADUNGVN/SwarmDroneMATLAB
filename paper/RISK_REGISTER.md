# Paper risk register

Risks to the publication claim set, with the evidence behind each, the
mitigation already in place, the **wording the paper must use**, and what
would resolve it.

The wording column is the operative one. Several of these risks are not
removable before submission; what is controllable is whether the
manuscript states them accurately. `paper/scripts/paper_audit.m` enforces
the wording rules mechanically where they can be expressed as a rule.

Severity: **HIGH** — a reviewer could reasonably reject on it;
**MEDIUM** — weakens a contribution; **LOW** — needs a caveat.

---

## R1 — No hardware validation

| | |
|---|---|
| **Severity** | HIGH |
| **Evidence** | The entire campaign is simulation. No timing, airtime, energy or radio measurement exists. |
| **Mitigation** | Pre-registered protocol, 50 holdout seeds, bit-identical reproduction, clean-clone check, and a staged hardware plan in `docs/HARDWARE_ROADMAP.md` naming the assumption each phase tests. |
| **Paper wording** | Title, abstract and contributions must not imply hardware. Say *simulation study*. Limitations §"No hardware validation" states it first. Never "validated on"; use "evaluated in simulation". |
| **Resolution** | Hardware phases H0–H2 address the assumptions most in need of measurement without a vehicle. |

## R2 — ACK cost removes the Stressed Pareto advantage

| | |
|---|---|
| **Severity** | HIGH |
| **Evidence** | K2a DATA −16.73 Hz vs P20; K2b DATA+0.25·ACK **+10.67 Hz**; both 95 % intervals exclude zero. Causal is cheapest in **0 / 17** cells at w = 0.25. A pre-registered Stressed ACK-inclusive Pareto superiority claim was tested and **rejected** (EXP07C). |
| **Mitigation** | K2 was pre-registered as *two* undirected claims precisely so this could not be reported as a saving. Stressed carries no acceptance gate. Table VI lists the rejection. Figure 5 draws the reversal. |
| **Paper wording** | **Never** "reduces communication" without qualification. Permitted: "reduces DATA-packet traffic while increasing ACK-inclusive total cost". **Forbidden**: any unqualified "communication saving", "traffic reduction", or "more efficient". The contribution is adaptivity and accuracy. |
| **Resolution** | Protocol work: aggregate or piggyback acknowledgements. Not a tuning fix. |

## R3 — Broadcast proxy exposes a synchronisation disadvantage

| | |
|---|---|
| **Severity** | HIGH |
| **Evidence** | Moderate non-dominance falls from **87.5 %** (w = 0.25) to **25.0 %** (broadcast). Stressed falls to 37.5 %. |
| **Mitigation** | All five cost models reported in the results table, not just the favourable ones. Discussion has a dedicated subsection explaining *why* periodic wins under broadcast. |
| **Paper wording** | The 87.5 % figure must always appear with the cost model named, and the broadcast figure must appear in the same table. Never present the Moderate Pareto result as model-independent. |
| **Resolution** | Cross-sender transmission alignment, or aggregated acknowledgements. H5 measures the actual broadcast collapse. |

## R4 — Controller degree sensitivity creates safety boundaries

| | |
|---|---|
| **Severity** | MEDIUM |
| **Evidence** | EXP08A safety gate fails systematically at one sweep condition; EXP08A-D diagnostic removed both the degree trend and the failure by normalising the consensus gain. |
| **Mitigation** | Attributed to the controller, not the policy, with a diagnostic that isolates it. Reported as a limitation and a rejected claim (R2 in the ledger). |
| **Paper wording** | Say "a controller property that the communication policy neither causes nor cures". Do **not** describe topology generalization as achieved. Do not silently restrict the paper to ring topology without saying the sweep found the boundary. |
| **Resolution** | Degree-normalised consensus gain — a controller change, outside this study's scope. |

## R5 — Mass mismatch, no integral disturbance rejection

| | |
|---|---|
| **Severity** | MEDIUM |
| **Evidence** | Holdout Moderate RMSE 0.0892 → 0.7317 m (+720 %) at arm B7, for **every** method. Pre-registered ≤ 25 % degradation claim rejected. |
| **Mitigation** | Attribution stated: proportional-derivative position loop with nominal-mass gravity feedforward and no integral term leaves a constant error. Reported in Table VI with the attribution. |
| **Paper wording** | **Must not** be called a communication failure. Required framing: "a controller limitation that no transmission schedule can remove". State that all four methods degrade comparably. |
| **Resolution** | Integral action or explicit disturbance estimation. Controller work. |

## R6 — Noise-driven false triggers

| | |
|---|---|
| **Severity** | MEDIUM |
| **Evidence** | Clean-condition DATA rises **×2.34** against the noiseless arm at the combined estimator arm, breaching the pre-registered ×2 bound. Accuracy does not improve correspondingly. `ESTIMATOR/Moderate` is the single dominated Moderate cell. |
| **Mitigation** | Mechanism explained: the innovation norm has a noise floor of order σ·√3 independent of motion, so noise alone crosses a fixed threshold. Remedy identified as future work, not claimed. |
| **Paper wording** | Report as a rejected bandwidth bound with the mechanism. Do not claim noise robustness. Do not present the noise-aware remedy as evaluated — it is not implemented. |
| **Resolution** | Filter before the innovation test, or inflate the threshold by the estimator's noise level. Unevaluated. |

## R7 — dt-dependent communication rate

| | |
|---|---|
| **Severity** | MEDIUM |
| **Evidence** | Stressed DATA 202.89 / 182.91 / 133.03 Hz at dt = 0.01 / 0.02 / 0.04 s. RMSE stable across the same range. Pre-registered invariance claim rejected. |
| **Mitigation** | Mechanism stated: the trigger is evaluated once per outer step and τ_min is one step, so the attainable rate scales with 1/dt by construction. |
| **Paper wording** | Every quoted rate must be identified as a rate **at dt = 0.02 s**. Never present a rate as a property of the policy. |
| **Resolution** | Decouple trigger evaluation from the control step, or express τ_min in physical time. Formulation change. |

## R8 — Leader remains kinematic in the 6-DOF study

| | |
|---|---|
| **Severity** | LOW-MEDIUM |
| **Evidence** | The leader follows its reference exactly and is never blacked out; only followers are 6-DOF vehicles. |
| **Mitigation** | Stated as a scope choice in the campaign's own documentation from the outset, not discovered afterwards. |
| **Paper wording** | State it in the problem formulation and the limitations, not only in a figure caption. Do not describe the study as "fully 6-DOF swarm". |
| **Resolution** | A dynamic leader, and a leader-blackout experiment — which is a different experiment, since it removes the formation's only absolute reference. |

## R9 — Estimator and sensor models are synthetic

| | |
|---|---|
| **Severity** | MEDIUM |
| **Evidence** | σ_p, σ_v and latency are parameter assumptions. The external forcing is a nominal-mass-equivalent acceleration proxy with no airspeed dependence, drag coefficient or frontal area. |
| **Mitigation** | Labelled as assumptions everywhere in the frozen code and documentation, including in the generator function headers. |
| **Paper wording** | Never "sensor model" or "wind model". Use "synthetic estimator noise with assumed parameters" and "world-frame external-force proxy". State that the sigmas are not measurements. |
| **Resolution** | Sensor characterisation on the target airframe. |

## R10 — Physical airtime and energy not measured

| | |
|---|---|
| **Severity** | HIGH (given R2 and R3 depend on cost accounting) |
| **Evidence** | Airtime cost uses assumed 48 B DATA and 24 B ACK frames; the broadcast model is an accounting proxy; no MAC, contention, duty cycle or energy is modelled. |
| **Mitigation** | Five cost models reported so the conclusion's model-dependence is visible rather than hidden behind one number. |
| **Paper wording** | Call them **cost models** and **proxies**, never measurements. State that the airtime figures follow from assumed frame sizes. |
| **Resolution** | H1 measures real frame sizes and serialisation; H2 measures airtime, duty cycle and ACK RTT. Both may change the sign of the cost argument, and the paper should not be written as though they cannot. |

---

## Cross-cutting risk: over-claiming by omission

| | |
|---|---|
| **Severity** | HIGH |
| **Evidence** | The campaign carries seven rejected claims and twelve conditional ones. Each is individually easy to drop from an abstract. |
| **Mitigation** | Table VI is a dedicated negative-results table; the claim ledger has a REJECTED group; `paper_audit` fails if a rejected claim appears as supported, if an unqualified saving claim appears, or if the ACK-impairment result appears without its saturation qualification. |
| **Paper wording** | The abstract itself names the reversal and the two non-claims. A reader who reads only the abstract must not come away with a stronger impression than the data supports. |
| **Resolution** | Not resolvable — permanent discipline, enforced by the audit on every rebuild. |
