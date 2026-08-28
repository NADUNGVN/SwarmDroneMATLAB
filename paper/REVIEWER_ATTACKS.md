# Reviewer-attack exercise

Eighteen criticisms a competent reviewer is likely to raise. Each is
classified honestly: **VALID** means the criticism lands and the paper must
concede it; **PARTIALLY VALID** means it lands against part of the claim;
**MISUNDERSTANDING** means the paper already answers it, and if a reviewer
still asks then the paper is not clear enough.

No defence is manufactured for a criticism that is valid. Where the correct
response is "you are right, and here is where we say so", that is the
response.

---

## A1 — "Why not simply tune P20, or a periodic rate in between?"

**Classification:** **PARTIALLY VALID** — and it is the strongest form of
the strongest objection.

**Evidence.** P20 has lower mean RMSE than our policy in **16 of 17** cells
of the final matrix. EXP11 supplies the more direct test: the network
changes during one mission, Causal-v3 is fixed and receives no regime label,
and all four adjacent DATA-rate differences have the expected sign. Yet
P12.5 retains **97.7% of Causal-v3 accuracy** at **89.6% of its
`Total_w025` cost** and **39.1% of its broadcast cost**.

**Response.** The criticism is correct as far as it goes, and the paper says
so in the introduction, results, discussion and conclusion. A periodic rate
cannot adapt its communication effort within a mission: it remains fixed as
the channel changes. Causal-v3 does adapt, with one parameterization and no
regime label. However, a well-selected fixed rate can remain highly
competitive on the aggregated mission, as P12.5 demonstrates. EXP11 thus
supports the **adaptivity mechanism**, not universal superiority. This is
the required distinction between mechanistic adaptivity and mission-level
Pareto superiority.

**Where addressed.** §1 "What we claim, and what we do not"; §6 EXP11;
§7 "Why not tune P20, P12.5, or another fixed periodic rate?"; Limitations.

**Remaining weakness.** EXP11 contains one five-segment mission design.
Different segment durations or regime mixtures could select a different
best fixed rate; EXP11 does not establish universal mission-level dominance.

---

## A2 — "ACK cost eliminates the claimed saving."

**Classification:** **VALID.**

**Evidence.** Against P20 at the nominal Stressed cell: DATA −16.73 Hz
(CI [−16.77, −16.68]) and ACK-inclusive total **+10.67 Hz**
(CI [+10.59, +10.76]). Both intervals exclude zero.

**Response.** Agreed, and the paper is built around agreeing. This is why
K2 was pre-registered as *two* undirected claims before the data existed,
why the abstract states "the reduction is DATA-only", and why Figure 5 draws
the reversal as an arrow. The contribution claimed is adaptivity and
accuracy, never total traffic reduction. An earlier experiment in this
campaign tested Pareto superiority under ACK-inclusive cost in the Stressed
condition and it was **rejected**; we did not re-open it.

**Where addressed.** Abstract; §6.3; §6.4; §7.6; Table VI; Limitations L2;
`RISK_REGISTER.md` R2.

**Remaining weakness.** None on honesty; a real one on impact. A method that
reduces no total traffic is a weaker practical proposition, and the fix —
aggregated or piggybacked acknowledgements — is future work.

---

## A3 — "Broadcast accounting favours periodic, so the result is an artifact of unicast accounting."

**Classification:** **VALID.**

**Evidence.** Moderate non-dominated fraction falls from 87.5 % under the
reference cost model to **25 %** under broadcast accounting; the Stressed
figure falls to 37.5 %.

**Response.** Correct, reported in the same table as the favourable number,
and given its own discussion subsection explaining the mechanism: periodic
senders fire on a clock so their unicast links collapse almost perfectly
into single broadcasts, an event-triggered sender's do not, and unicast
acknowledgements do not collapse at all. On a shared broadcast medium this
is a structural disadvantage of the approach and we do not argue it away.

**Where addressed.** §6.4 table; §7.7; Limitations L3.

**Remaining weakness.** Our broadcast model is an *accounting proxy*, not a
medium-access simulation — so the 25 % figure is itself approximate. It could
be better or worse with real contention. Roadmap phase H5 measures the
actual collapse.

---

## A4 — "The controller is degree-sensitive, so your topology results confound controller and policy."

**Classification:** **VALID**, and already our own finding.

**Evidence.** EXP08A's safety gate fails systematically at one condition of
the topology sweep. A follow-up diagnostic normalised the consensus gain by
in-degree and **removed both the degree trend and the safety failure**.

**Response.** Agreed. The consensus law sums relative terms without
normalising by in-degree, so a denser graph is a higher-gain system. We
attribute it to the controller, we do not claim topology-general safety, and
we report it as a rejected claim. It is not a communication result: none of
the four methods avoids it and ours neither causes nor cures it.

**Where addressed.** §6.6 "Topology and swarm size"; §7.8; Table VI row 2;
Limitations L7.

**Remaining weakness.** Because the controller was deliberately frozen, all
our non-ring results inherit the boundary. A co-designed version with a
normalised gain would be a different and probably better paper.

---

## A5 — "Mass mismatch destroys RMSE, so the method is not usable."

**Classification:** **MISUNDERSTANDING** of what fails, though the
observation is correct.

**Evidence.** At the combined mismatch arm, formation error rises to 0.7317 m
from 0.0892 m nominal — **+720 %** — for **every** method: P10 0.7330,
P20 0.7294, State-event 0.7494, ours 0.7317.

**Response.** The degradation is real and we report it as a rejected claim.
But it is not attributable to the communication policy: the position loop is
proportional-derivative with a gravity feedforward computed from the nominal
mass, so a heavier vehicle leaves a constant error that no transmission
schedule can supply a correction for. All four methods land within 3 % of
each other. Calling it a communication failure would misattribute it, and
the audit forbids that phrasing.

**Where addressed.** §6.6 "Plant mismatch"; §7.9; Table VI row 5;
Limitations L4 (controller-owned).

**Remaining weakness.** We did not implement integral action to prove the
attribution by removing the effect. The argument is mechanistic plus the
across-method uniformity, which is strong but not a demonstration.

---

## A6 — "Measurement noise causes a transmission explosion, which is fatal for a real sensor."

**Classification:** **VALID.**

**Evidence.** At the combined estimator arm, Clean-condition DATA rises by a
factor of **2.34** against the noiseless arm, breaching a pre-registered
factor-of-two bound. Accuracy does not improve correspondingly.

**Response.** Agreed, reported as a rejected claim with its mechanism: the
innovation norm has a noise floor of order σ√3 independent of motion, and
when that approaches the fixed threshold, noise alone crosses it. The Clean
condition is where it hurts most because there is no impairment to justify
the traffic. This is a genuine limitation of a *fixed-threshold* innovation
test under a noisy estimate.

**Where addressed.** §6.6 "Plant mismatch and estimator noise"; §7.10;
Table VI row 6; Limitations L5.

**Remaining weakness.** Substantial. The remedy — filter before the
innovation test, or inflate the threshold by the estimator's own noise level
— is obvious, and **we did not implement or evaluate it**. A reviewer is
entitled to say the paper identifies a defect it does not fix.

---

## A7 — "The transmission rate depends on Δt, so your rates are meaningless."

**Classification:** **PARTIALLY VALID.**

**Evidence.** Stressed DATA 202.89 / 182.91 / 133.03 Hz at Δt = 0.01 / 0.02 /
0.04 s. Formation RMSE is stable across the same range.

**Response.** The rates are not meaningless; they are *conditional*, and the
paper labels every rate as a rate at Δt = 0.02 s. The mechanism is structural:
the trigger is evaluated once per outer step and the refractory bound is one
step, so the attainable rate scales with 1/Δt by construction. That the
control behaviour is *not* Δt-sensitive while the traffic is, is itself the
useful finding, and the pre-registered invariance claim was rejected rather
than reinterpreted.

**Where addressed.** §6.6 "Timestep sensitivity"; §7.11; Table VI row 7;
Limitations L6.

**Remaining weakness.** Cross-paper comparison of our rates requires
matching Δt, which limits reusability of the numbers. A Δt-invariant
formulation is future work.

---

## A8 — "The leader is kinematic, so this is not a 6-DOF swarm."

**Classification:** **VALID.**

**Evidence.** The leader follows its reference exactly and is never selected
for a blackout; only followers are 6-DOF vehicles. The 6-DOF results are at
N = 5, with a secondary characterisation at N = 10.

**Response.** Agreed, and stated as a scope choice from the campaign's
outset rather than discovered afterwards. The paper does not describe itself
as a fully 6-DOF swarm. A dynamic leader, and a leader-blackout experiment,
are separate experiments — blacking out the leader removes the formation's
only absolute reference, which changes the problem rather than stressing it.

**Where addressed.** §3.2; Limitations L "Leader model and swarm scale";
`RISK_REGISTER.md` R8.

**Remaining weakness.** No 6-DOF result at large N. The N = 50 anchor is
double-integrator, so scalability and physical realism are demonstrated
separately and never together.

---

## A9 — "Why call this AoI when the sender only estimates freshness?"

**Classification:** **MISUNDERSTANDING**, but a fair terminological
challenge.

**Response.** We use both quantities and keep them distinct in notation and
in text. The true age A_ij(t) = t − g_ij(t) is defined as an
*omniscient-observer* metric which we log and report; the sender's estimate
Â(t) = t − g_ack + Δt/2 is a different quantity, and §3.4 states explicitly
that any policy reading A_ij inside a sender's decision is acausal. The gap
between them is a modelling consequence of the reverse channel, not an
approximation error to be minimised. "AoI-aware" describes the quantity the
policy is *about*; "causal" and "ACK-assisted" in the title describe what it
is actually allowed to see.

**Where addressed.** §3.4 including the boxed causality requirement; §4.2;
Table of logged metrics (true AoI and estimated AoI reported separately).

**Remaining weakness.** If reviewers still find "AoI-aware" overreaching,
"freshness-aware" is an acceptable substitute throughout and costs nothing.

---

## A10 — "Why does the causal policy beat the oracle on RMSE? That suggests a bug."

**Classification:** **MISUNDERSTANDING**, and the most likely
misunderstanding in the paper.

**Evidence.** Oracle 15.80 Hz per channel, RMSE 0.1306 m; ours 18.24 Hz,
RMSE 0.1170 m. Both measured on identical channel realisations at the same
20 seeds.

**Response.** It is not a bug and not a contradiction, because the oracle is
not a maximiser of accuracy — it is a *policy* with the same trigger
structure and better information. Perfect freshness knowledge is mostly
useful for deciding when **not** to transmit: an oracle knows immediately
when a packet has landed and can go quiet with confidence. A causal sender
cannot distinguish "delivered, ACK still in flight" from "lost", so it errs
toward transmitting, and in a lossy network that pessimism buys accuracy.
  The oracle-information result characterizes attainable efficiency; it is
  not treated as a bound on attainable accuracy.

**Where addressed.** §6.1 final paragraph; §7.2; §9; and the wording rule
enforced across the manuscript.

**Remaining weakness.** We did not construct an oracle variant *tuned to
match our transmission rate*, which would be the cleanest way to separate
"more information" from "more traffic". That is a one-experiment gap and we
name it rather than paper over it.

---

## A11 — "Are the negative results cherry-picked to look rigorous?"

**Classification:** **MISUNDERSTANDING**, and answerable with artifacts
rather than assertion.

**Response.** The gates, operating points, statistical procedure and seed
policy were committed in writing *before each experiment ran*, each
amendment carries a timestamp and a stated reason, and the amendment log is
in the repository. The selected robustness points are the points that
**already exposed a limit** in their source experiments — the link fraction
where safety failed, the arm where the RMSE gate failed, the arm where the
bandwidth gate failed — not the most flattering cells. The final validation
used 50 seeds proven disjoint from every development seed. Two of the seven
rejections concern our own performance claims, not just robustness
boundaries.

**Where addressed.** §5.1; §5.4; Table VI; `docs/FINAL_CLAIMS.md`;
`docs/EXP10_PLAN.md` §17 amendment log.

**Remaining weakness.** Pre-registration is internal to the project; it was
not deposited with a third-party registry, so a determined sceptic must
trust the git history. Committing the plan before the results exists in the
commit graph, which is checkable but not independently timestamped.

---

## A12 — "Why is the ACK cumulative rather than per-packet?"

**Classification:** **MISUNDERSTANDING** — a design-rationale question.

**Response.** Three reasons, all in §4.6. It bounds reverse traffic at one
frame per link per tick regardless of how many DATA packets arrived in that
tick, which matters because we *price* the reverse channel. It makes
recovery from a lost ACK automatic, since the next ACK covers everything the
lost one would have. And it retires every outstanding sequence number up to
its own, which is what lets the outstanding set act as the in-flight
suppression signal without extra bookkeeping. Cumulative ACK semantics are
standard in the ACK-driven AoI scheduling literature.

**Where addressed.** §4.6 "Cumulative acknowledgement"; Algorithm 2 Part B.

**Remaining weakness.** We did not compare against per-packet ACK, so the
choice is justified by reasoning and precedent rather than by an ablation.

---

## A13 — "Why is there no explicit retransmission timeout?"

**Classification:** **MISUNDERSTANDING** — deliberate design, and it was the
question an iteration existed to answer.

**Response.** Recovery is a consequence of the branch semantics rather than
of a timer: a lost packet is never acknowledged so it stays outstanding, a
non-empty outstanding set forbids refresh, the frozen acknowledged time
makes the freshness estimate grow which drives the adaptive scale to its
floor and makes the new-information branch progressively easier to satisfy,
and if the state is genuinely static the max-silence backstop fires. Whether
that arrangement *alone* suffices was precisely the question the third
iteration was built to test, and the answer is measured: recovery times are
reported under a 5 s node blackout.

**Where addressed.** §4.5; §4.7 "What is deliberately absent"; Figure 8.

**Remaining weakness.** "Sufficient in our setting" is not "better than an
RTO". We ran no comparison against an explicit ARQ scheme, and a reviewer
could fairly ask for one.

---

## A14 — "How general is ring2? One topology is not a generalisation."

**Classification:** **VALID.**

**Evidence.** The final validation ran ring topology only. The earlier
topology sweep covered four topologies at N ∈ {10, 20, 50}, and its safety
gate **failed** at one condition.

**Response.** Agreed, and stated twice: the communication ranking was
preserved across the sweep, absolute safety generalisation was **rejected**,
and the holdout validation deliberately carries no evidence about other
topologies, so the earlier rejection stands untouched rather than being
narrowed. We do not claim topology generality.

**Where addressed.** §6.6 "Topology and swarm size"; §8 "Scope of the final
validation"; Table VI row 2.

**Remaining weakness.** Real. The strongest claims in the paper are
ring-topology claims at one formation geometry, and the safety numbers in
particular are geometry-dependent because the threshold is a property of the
lattice spacing.

---

## A15 — "There is no stability proof or Zeno-freedom guarantee."

**Classification:** **VALID.** This is the most likely rejection ground at a
control-theory venue.

**Response.** Correct: the paper contains no stability theorem and no
Lyapunov argument. Zeno behaviour is excluded by construction through the
refractory bound τ_min, which is an implementation guarantee rather than a
theorem about the closed loop, and we say so in the related-work section
rather than implying otherwise. The evidence offered is empirical and
pre-registered: 3400 holdout runs with zero divergences and zero
protocol-invariant violations.

**Where addressed.** §2.1 (explicitly, in the "still missing on our side"
framing carried into the manuscript); §4.4 refractory bound.

**Remaining weakness.** A minimum inter-event-time bound and a
stability-under-bounded-staleness result are both plausible and absent. See
`VENUE_SHORTLIST.md`: for TCNS the recommended pre-submission work is to add
at least a formal inter-event-time statement.

---

## A16 — "Two rate conventions appear in the paper; are the tables comparable?"

**Classification:** **MISUNDERSTANDING**, and a real trap we defused.

**Response.** They are not comparable and the paper says so. EXP07 tables
report DATA rate **per channel** (P10 reads exactly 10.00 Hz); EXP08 onward
report **swarm totals** (P10 reads 99.67 Hz at N = 5). The two eras also use
different channel counts at the same N, because the later graph convention
removes in-links to the leader. Every caption states its normalisation, §5.6
explains both, and an audit rule checks that both labels are present.

**Where addressed.** §5.6; captions of Tables II, III, IV; audit rule A11.

**Remaining weakness.** It remains a reader hazard. If a venue's format
forces tables apart from their captions, the risk rises.

---

## A17 — "50 seeds is a small sample."

**Classification:** **MISUNDERSTANDING** of what the sample is doing.

**Response.** The comparisons are **paired** under common random numbers:
every method meets the identical channel realisation, fault realisation and
noise realisation at a given seed, so the seed-to-seed variance largely
cancels. The resulting intervals are tight — K1 is −0.0288 m with a
half-width of about 0.0006 m — and the pre-registration forbade adding seeds
after inspecting an interval, because choosing a sample size by the result
is how a confidence interval stops meaning anything.

**Where addressed.** §5.3 common random numbers; §5.5 statistical
conventions; Figure 11 per-seed differences.

**Remaining weakness.** Tight intervals reflect low *realisation* variance,
not low *modelling* uncertainty. They say the difference is reproducible in
this simulator; they say nothing about transfer to hardware.

---

## A18 — "Novelty: is this not just AoI plus event triggering, both known?"

**Classification:** **PARTIALLY VALID** — every ingredient is precedented.

**Response.** Correct, and we say it plainly: AoI is a mature field,
event-triggered multi-agent control is mature and has already been applied
to UAV formations, ACK-driven freshness estimation exists in AoI scheduling,
and adaptive thresholds are established. The claim is the *combination* — a
distributed sender in a formation estimating its own receiver's freshness
only from cumulative acknowledgements, using it to scale a state-innovation
  threshold — plus the new-information/refresh separation and in-flight
  suppression. We did not identify prior work combining all of those
  elements. The re-audit specifically accounts for Tahir et al. (2024),
  which already uses delayed ACKs to infer receiver AoI in decentralized
  multi-agent scheduling; Kesper et al. (2023), which appends age timers to
  last-broadcast states in learned distributed multi-agent control; Lin et
  al. (2023), a direct AoI-aware event-triggered power-control precedent;
  and Onozuka et al. (2024), which triggers both forward and feedback
  communication. None adds the complete physical state-innovation,
  cumulative-ACK confirmation and new-versus-refresh in-flight split. Near
  neighbours are compared element by element, and
the search boundary and the conditions that would overturn the assessment
are recorded. No priority claim is made.

**Where addressed.** §2.5; `NOVELTY_GAP_REVIEW.md`;
`RELATED_WORK_MATRIX.md`.

**Remaining weakness.** A negative search result is weak evidence of
absence, and our search was DOI-indexed and English-language. A
reviewer who knows the field may produce the paper we missed — which is why
the re-test trigger is written down.

---

## Summary of classifications

| Class | Count | Items |
|---|---|---|
| **VALID** — must be conceded | 7 | A2, A3, A4, A6, A8, A14, A15 |
| **PARTIALLY VALID** | 4 | A1, A7, A18, (A5 observation) |
| **MISUNDERSTANDING** — paper answers it | 7 | A5, A9, A10, A11, A12, A13, A16, A17 |

**The two most dangerous are A15 (no theory) at a control venue and A1
(why not tune periodic) anywhere.** A15 is addressable before submission by
adding a formal inter-event-time statement. A1 is addressable only by an
experiment we have not run — a network whose quality changes *within* a run
— and that is the single highest-value item for the next campaign.
