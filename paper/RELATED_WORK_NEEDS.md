# Related-work needs

The manuscript's related-work section contains **no citations**. This file
is why, and what has to happen before it does.

**Rule for this file and for the section it feeds:** no citation is added
until it has been read and verified to support the specific claim it is
attached to. A plausible-looking reference inserted to fill a slot is not a
placeholder — it is an error that survives review and that a reader cannot
distinguish from a real one. An empty section is honest; a fabricated
bibliography is not.

For each group below: what we need the literature to establish, how our
work differs, and what evidence is still missing on our side.

---

## G1. Age of information in networked control

**Claim needing support.** That AoI is an established freshness metric
distinct from throughput or rate, that its use in *control* (as opposed to
status-update monitoring) is an active thread, and that the mismatch
between minimising average age and minimising control cost is known.

**How we differ.** In our policy age never triggers a transmission. It
scales the state-change threshold that does, multiplicatively, with a
floor. A policy driven by age alone will transmit when nothing has changed;
ours cannot, because both branches that fire require a state change.

**Still missing on our side.** We report true AoI and estimated AoI but do
not prove any bound relating either to formation error. The relationship is
empirical throughout.

**Search terms.** age of information; AoI-based scheduling; freshness-aware
control; remote estimation with age constraints; AoI versus MSE.

---

## G2. Event-triggered and self-triggered multi-agent control

**Claim needing support.** The standard state-error trigger form we use as
a baseline; the accepted role of a minimum inter-event time in excluding
Zeno behaviour; standard results for event-triggered consensus and
formation control.

**How we differ.** Our trigger reads an *estimate of what the receiver
holds*, which a purely local error trigger cannot access. Our comparison is
against exactly that conventional local trigger, and the measured gap is
large (state-event 0.2576 m against 0.1188 m at Stressed on the holdout
matrix).

**Still missing on our side.** We make no stability or Zeno-freedom proof.
Zeno behaviour is excluded by construction through the refractory bound
τ_min, which is an implementation guarantee, not a theorem about the closed
loop.

**Search terms.** event-triggered consensus; self-triggered control;
distributed event-triggered formation; minimum inter-event time; Zeno-free
triggering.

---

## G3. AoI-aware / event-triggered wireless control

**Claim needing support.** That combining freshness with triggering is an
existing line of work, and — critically — that the *oracle freshness*
assumption (the sender knows the receiver's age exactly) and the *ideal
acknowledgement* assumption are common in it. Removing those assumptions is
only a contribution if they are actually prevalent.

**How we differ.** We remove both and measure the cost. Our ablation
includes a non-causal ideal-feedback policy as an explicit reference, and the result is
worth citing against: the causal policy reaches **lower** Stressed error
than the oracle (0.1170 m vs 0.1306 m) while transmitting **more**
(18.24 vs 15.80 Hz per channel). The oracle bounds efficiency, not
accuracy.

**Still missing on our side.** No comparison against a *different* causal
freshness estimator (e.g. a model-based predictor of receiver age rather
than an ACK-driven one). Our open-loop ablation is a degenerate case, not a
competing design.

**Search terms.** AoI-aware event-triggered control; freshness-aware
scheduling wireless control; remote estimation with acknowledgements;
transmission scheduling under partial feedback.

---

## G4. UAV swarm communication constraints

**Claim needing support.** Realistic airtime, duty-cycle and energy figures
for radios such a swarm would carry; evidence on how neighbour count limits
sustainable update rates; the practical motivation for trading accuracy
against traffic at all.

**How we differ.** We price communication under five models including an
airtime proxy and a broadcast proxy, and we report the model dependence
rather than the best case.

**Still missing on our side — and this is our weakest point.** We measure
no physical airtime, no energy and no medium contention. The airtime model
uses assumed frame sizes (48 B DATA, 24 B ACK) and the broadcast model is
an accounting proxy, not a MAC simulation. This is the first thing the
hardware roadmap addresses (`docs/HARDWARE_ROADMAP.md`, phases H0–H2).

**Search terms.** UAV swarm communication constraints; multi-UAV networking
duty cycle; airtime-limited swarm coordination; scalability of wireless
formation control.

---

## G5. ACK / feedback-aware scheduling

**Claim needing support.** Standard cumulative-acknowledgement semantics;
prior treatment of the *cost* of the reverse channel in control-oriented
scheduling; existing approaches to retransmission in control-relevant
protocols.

**How we differ.** Our loss recovery introduces no retransmission timeout,
no RTT estimator and no window. An unacknowledged packet stays outstanding,
outstanding packets forbid refresh, and the max-silence backstop fires.
Whether that semantic arrangement suffices was the question the third
design iteration existed to answer.

**Still missing on our side.** We do not compare against an explicit
ARQ/RTO scheme, so "no timer is needed" is demonstrated for our setting
rather than shown superior to a timer.

**Search terms.** cumulative acknowledgement; ACK-aware scheduling;
ARQ for networked control; feedback-aware transmission policy.

---

## G6. Resource-aware formation control and communication/control co-design

**Claim needing support.** The framing that separates
communication-attributable from controller-attributable degradation, since
several of our rejected claims are control limitations.

**How we differ.** We attribute explicitly, and in three cases the
attribution is *not* to our contribution: the degree-dependent safety
boundary, the steady offset under mass mismatch, and safety failures under
link and node faults that are identical across all four methods.

**Still missing on our side.** No co-design: the controller is frozen
throughout and was deliberately never retuned per condition, because
retuning would have measured the quality of the retuning instead of the
robustness of the communication policy. A genuine co-design study is future
work.

**Search terms.** communication-control co-design; resource-aware
formation control; joint scheduling and control design;
control-aware networking.

---

## Positioning risks to resolve during the citation pass

| Risk | What to check |
|---|---|
| The oracle-freshness assumption may be *less* common than we assume, weakening the framing of our main contribution | Sample recent AoI-aware triggering papers and record whether receiver age is assumed known |
| A published policy may already separate new information from refresh under another name | Search retransmission-suppression and duplicate-suppression framings, not just AoI ones |
| Our state-event baseline may be weaker than the standard form | Verify the baseline trigger against the canonical formulation before claiming the margin |
| Cumulative ACK may make our reverse-channel cost unusually low or high relative to prior art | Check whether comparable studies count reverse traffic at all |
