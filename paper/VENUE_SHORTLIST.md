# Venue shortlist

Five candidates, ranked. Every policy figure below was read from the
publisher's or society's own current pages during this pass; where a page
did **not** state something, that is recorded as *not stated* rather than
filled in from assumption.

**The decisive constraint is not acceptance probability. It is that this
work has no hardware validation.** Each entry therefore carries an explicit
assessment of how damaging that is at that venue.

**No manuscript reformatting has been done.** The paper is currently a
generic two-column `article`; conversion to a venue template is deliberately
deferred until a venue is chosen.

---

## Summary ranking

| Rank | Venue | Why this rank |
|---|---|---|
| **PRIMARY** | IEEE Trans. on Control of Network Systems (TCNS) | Scope names "control with communication constraints" and multi-agent systems explicitly; simulation-based contributions are normal; our lack of hardware is least damaging here |
| **BACKUP 1** | IEEE Trans. on Control Systems Technology (TCST) | Scope explicitly spans "simulation and hardware"; generous page limit; values implementation realism, which our 6-DOF and protocol-invariant work supplies |
| **BACKUP 2** | IEEE Trans. on Aerospace and Electronic Systems (TAES) | UAV/aerospace systems audience, no formal page limit; but a systems venue where reviewers may expect flight data |
| **BACKUP 3** | IEEE Robotics and Automation Letters (RA-L) | Fast, high visibility, conference-presentation option; but 6 pages is a severe cut and robotics reviewers weigh hardware heavily |
| **FALLBACK** | IEEE Access | Broad scope, fast, fully open access; costs an APC and carries less prestige |

---

## PRIMARY — IEEE Transactions on Control of Network Systems

| | |
|---|---|
| **Scope fit** | Stated scope covers decision and control systems with distributed or networked architecture, including multi-agent systems, distributed estimation, dynamical systems over graphs, and **control with communication constraints** |
| **Why this manuscript fits** | The contribution *is* a communication-constraint result for a multi-agent system: what a sender may know, what it may infer from acknowledgements, and what that costs in traffic. The five cost models and the ACK-inclusive reversal are exactly this venue's subject matter |
| **Theory expectation** | Moderate to high. TCNS publishes analysis-led work; we have **no stability theorem** and no Zeno-freedom proof beyond the refractory bound. This is our main scope risk here, not the hardware |
| **Hardware-experiment expectation** | Low. Simulation-based contributions are normal in this venue |
| **Simulation-only risk** | **LOW** — the least damaging of the five |
| **Page/word limits** | 12 pages maximum, double-column IEEE Transactions 10-point, including figures, tables, references and biographies |
| **Supplement / artifact policy** | Not stated on the pages consulted; IEEE supports supplementary material generally. Verify before submission |
| **Open-access model** | Hybrid: subscription with optional open access (IEEE-wide) |
| **Current APC if applicable** | Only if open access is elected; not stated on the TCNS pages consulted |
| **Review format** | Single-blind peer review, PDF-only submission |
| **Current template** | IEEE Transactions double-column, 10 pt |
| **Likely manuscript changes** | Cut to 12 pages — the largest single edit. Candidates: fold the design-evolution ablation into a compact table, move the reviewer-facing statistical conventions to a short paragraph, and relocate parts of §7 to supplementary material. Add at least a formal statement bounding the inter-event time, to meet the theory expectation |
| **Major rejection risk** | **No theoretical guarantee.** A TCNS reviewer may reasonably ask for a stability or performance bound. Our answer is empirical and pre-registered, which is a strength but not a substitute |

## BACKUP 1 — IEEE Transactions on Control Systems Technology

| | |
|---|---|
| **Scope fit** | Publishes technological advances in the design, realisation and operation of control systems, and states that it bridges theory and practice "from analysis and design through **simulation** and hardware" |
| **Why this manuscript fits** | Simulation is named in scope. The 6-DOF follower model, the actuator-saturation accounting, the runtime protocol invariants and the reproduction machinery are implementation-realism contributions of the kind this venue rewards |
| **Theory expectation** | Moderate — lower than TCNS; implementation evidence carries more weight |
| **Hardware-experiment expectation** | Present but not absolute; many TCST papers are simulation-plus-analysis |
| **Simulation-only risk** | **LOW–MEDIUM** |
| **Page/word limits** | Paper up to 16 pages; Brief Paper up to 8; Letter up to 4. Double-column IEEE format, single-spaced, figures counted. **Over-length or out-of-scope submissions are rejected without review** |
| **Supplement / artifact policy** | Not stated on the page consulted; verify |
| **Open-access model** | Hybrid |
| **Current APC if applicable** | Only if open access elected; not stated on the page consulted |
| **Review format** | Single-blind; bi-monthly publication |
| **Current template** | IEEE Transactions double-column |
| **Likely manuscript changes** | 16 pages is comfortable — the current draft fits with room for the ablation. Strengthen the implementation framing: lead with the protocol specification and invariants, and foreground the H0–H2 hardware plan as concrete next steps |
| **Major rejection risk** | "Technology" venue with no technology demonstration. Mitigated by the roadmap and by the fact that the artifact is executable and reproduces bit-identically |

## BACKUP 2 — IEEE Transactions on Aerospace and Electronic Systems

| | |
|---|---|
| **Scope fit** | Organisation, design, development, integration and operation of complex systems for space, air, ocean or ground, including guidance and control, navigation, sensor network management, and large-scale systems/systems-of-systems |
| **Why this manuscript fits** | A multi-UAV formation with a constrained radio is squarely a complex aerospace system; sensor-network management and large-scale systems are named interest areas |
| **Theory expectation** | Low to moderate |
| **Hardware-experiment expectation** | **Moderate to high** — a systems-engineering readership tends to expect measured platform data |
| **Simulation-only risk** | **MEDIUM–HIGH.** Our airtime and energy numbers are proxies, and this is the audience most likely to press on that |
| **Page/word limits** | No formal limit for regular papers, but over-long manuscripts are warned against; **$200 per printed page beyond 10** for regular papers (beyond 6 for correspondence) |
| **Supplement / artifact policy** | Not stated on the pages consulted; TAES does publish a separate preprint policy, so check both |
| **Open-access model** | Hybrid |
| **Current APC if applicable** | Only if open access elected; page charges above apply regardless |
| **Review format** | Peer review under an Editor-in-Chief with technical-area editors |
| **Current template** | IEEE Transactions double-column |
| **Likely manuscript changes** | Reframe toward the system: airtime, duty cycle, neighbour-count scaling, and the N = 50 anchor. Move the design-evolution ablation to a supporting role. Budget the page charge deliberately |
| **Major rejection risk** | "Where is the flight data?" — the hardest version of this question, from the audience most entitled to ask it |

## BACKUP 3 — IEEE Robotics and Automation Letters

| | |
|---|---|
| **Scope fit** | Robotics and automation letters; short-format, rapid publication |
| **Why this manuscript fits** | Multi-UAV coordination is core robotics; the adaptivity result is a clean single-message contribution suited to the format |
| **Theory expectation** | Low |
| **Hardware-experiment expectation** | Not stated as a requirement on the page consulted, **but robotics reviewers in practice weigh physical validation heavily.** Treat as high in expectation, unverified in policy |
| **Simulation-only risk** | **HIGH** |
| **Page/word limits** | **6 pages**, with at most two extra pages at a charge |
| **Supplement / artifact policy** | Electronic-only journal; video and supplementary material are customary. Verify current specifics |
| **Open-access model** | Open access available to authors who require it; extra pages incur charges |
| **Current APC if applicable** | Not stated on the page consulted; verify |
| **Review format** | Senior Editor plus Associate Editor plus at least two reviewers; target decision within 6 months, average submission-to-e-publication about 4 months; a fast revise-and-resubmit path exists |
| **Current template** | IEEE conference/letters double-column |
| **Likely manuscript changes** | **Severe.** Six pages cannot hold the design-evolution ablation, five cost models, seven robustness axes and the negative-results table. The honest version would be one message — adaptivity with a causal ACK-derived freshness estimate, plus the ACK-inclusive caveat — with everything else in supplementary material. There is a real risk that cutting to fit produces the over-claiming this campaign has worked to avoid |
| **Major rejection risk** | Simulation-only in a hardware-oriented community, compounded by a length limit that fights against reporting the caveats |
| **Bonus** | Accepted papers may be presented at one of ICRA/IROS/CASE/Humanoids/RoboSoft within 270 days of acceptance |

## FALLBACK — IEEE Access

| | |
|---|---|
| **Scope fit** | Broad multidisciplinary IEEE scope; accepts application and systems work |
| **Why this manuscript fits** | No scope obstacle, no theory expectation, and length is not a binding constraint |
| **Theory expectation** | Low |
| **Hardware-experiment expectation** | Low |
| **Simulation-only risk** | **LOW** |
| **Page/word limits** | Not a binding constraint for this manuscript |
| **Supplement / artifact policy** | Supports supplementary material; verify current specifics |
| **Open-access model** | **Fully open access** |
| **Current APC** | **USD 2,160.** A 20 % discount applies to members of an IEEE society or council; 5 % for IEEE members not in a society |
| **Review format** | Rapid peer review with a binary accept/reject emphasis |
| **Current template** | IEEE Access template |
| **Likely manuscript changes** | Minimal — the current structure is publishable close to as-is |
| **Major rejection risk** | Low. The cost is the APC and the lower selectivity signal, not rejection |

---

## Recommendation and reasoning

**Submit to TCNS first.** It is the only venue on this list whose stated
scope contains the exact subject of the paper — control under
communication constraints in a networked multi-agent system — and it is
the venue where having no hardware costs us least. The binding work is a
12-page cut and adding a formal statement about inter-event time.

**If TCNS rejects on theory grounds, go to TCST, not down the list.** A
theory-grounds rejection is an argument for the venue that explicitly
names simulation in its scope and gives 16 pages to make an
implementation case.

**Do not start at RA-L.** The six-page limit is in direct tension with
this paper's central discipline: seven rejected claims, a cost-model
reversal and five robustness boundaries all have to stay visible. A
version that fits six pages is a version that has quietly dropped
something, and this campaign spent its whole effort making sure nothing was
quietly dropped.

## Verification status of this file

| Venue | Read from | Items not stated on the source |
|---|---|---|
| TCNS | IEEE CSS society pages | supplement policy; APC |
| TCST | IEEE CSS society page | experimental-vs-simulation expectation; APC |
| TAES | IEEE AESS author-information pages | supplement policy; APC |
| RA-L | IEEE RAS publication page | hardware requirement; APC specifics |
| IEEE Access | IEEE Access / IEEE Open APC pages | supplement specifics |

Every "not stated" must be checked against the venue's current author
instructions immediately before submission. Nothing in this file should be
treated as a substitute for the author kit in force on the submission date.
