# Hardware transition roadmap

**Status: PLAN ONLY. No hardware work has been done, and nothing in the
frozen campaign is a hardware result.**

This document stages the transition from `simulation-v1.0` to a hardware
validation. Its organising principle is that each phase must **test a
named simulation assumption** — not merely demonstrate that something
flies. Phases that only produce a video are excluded.

Two rules apply throughout:

1. **No phase may claim hardware validation of a simulation claim until
   its acceptance gate passes.** A partial hardware result is a partial
   hardware result.
2. **A hardware measurement that contradicts a simulation assumption is a
   finding, not a bug to be tuned away.** The precedent is set: this
   campaign already carries seven rejected claims, and hardware
   rejections get the same treatment.

---

## Phase overview

| Phase | Name | Hardware | Validates |
|---|---|---|---|
| H0 | Protocol emulation | none (desktop) | protocol logic in a real runtime, off the simulator |
| H1 | One-node embedded timing | 1 flight controller / SoC | trigger cost, memory, serialisation latency |
| H2 | Two-node radio and ACK | 2 radios | packet sizes, airtime, ACK RTT distribution, real PDR |
| H3 | One UAV, network-in-loop | 1 UAV + 2 radios | the setpoint interface and controller under real timing |
| H4 | Two-UAV coordination | 2 UAVs | relative formation control over a real link |
| H5 | Three-to-five UAV swarm | 3–5 UAVs | the swarm claims at the smallest scale that is a swarm |

---

## H0 — Protocol emulation

Re-implement the sender and receiver algorithms (Algorithms 1 and 2 of the
manuscript) in the target language and runtime, outside MATLAB, and drive
them with the **frozen channel traces** from the campaign.

**Hardware needed.** None. Desktop or a container.

**Software interface.** Replay `results/exp10a_final_validation/<run>/`
trace realisations; expose the same per-channel state
(`sentPos/sentVel/sentGenTime/sentSeq`, `ackGenTime/ackSeq`, outstanding
set, `lastTxTime`).

**Measurement outputs.** Per-seed DATA count, ACK count, branch histogram
(hard / adaptive-new / refresh / max-silence), invariant-violation counts.

**Acceptance gate.**
- branch histogram and DATA/ACK counts match the MATLAB run for the same
  seed to within re-implementation rounding, stated explicitly;
- all nine protocol invariants zero;
- no reliance on any quantity a real sender cannot have (checked by code
  review against the causality requirement).

**Failure modes.** A language port that accidentally reads receiver state;
a floating-point difference in the adaptive-scale computation that shifts
branch selection at the threshold; integer overflow in sequence numbers.

**Simulation assumption validated.** That the policy as specified is
implementable at all without oracle access — currently supported only by
our own implementation.

---

## H1 — One-node embedded timing benchmark

Run the H0 implementation on the target processor and measure what it
costs.

**Hardware needed.** One flight-controller-class board or companion SoC of
the intended class.

**Software interface.** Bare trigger-evaluation loop at the intended outer
rate, with synthetic state input; no radio.

**Measurement outputs (all required).**

| Metric | Why it matters |
|---|---|
| CPU time per trigger evaluation | the policy runs per channel per step; cost scales with neighbour count |
| CPU time per outer step, all channels | must fit inside the control period |
| memory footprint (static + per channel) | dual memory plus outstanding set is per channel |
| DATA packet size in bytes | our airtime model assumes 48 B |
| ACK packet size in bytes | our airtime model assumes 24 B |
| packet serialisation latency | not modelled at all in simulation |
| worst-case jitter of the evaluation loop | the trigger is assumed to run once per step exactly |

**Acceptance gate.**
- total per-step trigger cost at the intended neighbour count is under
  20 % of the outer control period, with the margin reported;
- measured DATA and ACK sizes are recorded, and the airtime cost model of
  the paper is **recomputed** with them;
- memory per channel is bounded and reported.

**Failure modes.** Trigger cost scaling worse than linearly in neighbour
count; serialisation dominating the trigger cost; dynamic allocation in
the outstanding set causing jitter.

**Simulation assumptions validated.** That trigger evaluation is free
(never modelled), and the 48 B / 24 B frame sizes behind the airtime cost
model. **If the measured ACK/DATA size ratio differs materially from
24/48, the paper's airtime column must be recomputed, and the conclusion
that the method is unfavourable under ACK-inclusive cost may become
stronger or weaker.**

---

## H2 — Two-node radio and ACK test

The first phase that can contradict the campaign's central cost claim.

**Hardware needed.** Two radios of the intended type, plus the H1 boards.

**Software interface.** H0 protocol over the real link, with the
cumulative-ACK receiver of Algorithm 2. Static nodes; no vehicle.

**Measurement outputs (all required).**

| Metric | Simulation counterpart |
|---|---|
| measured packet delivery ratio versus distance and rate | assumed loss probability |
| ACK round-trip-time distribution | assumed reverse delay + jitter |
| radio airtime per DATA and per ACK frame | airtime cost proxy |
| radio duty cycle at each policy rate | never modelled |
| energy proxy (current draw × time in transmit) | never modelled |
| maximum sustainable neighbour count | never modelled |
| behaviour under a genuine collision | not modelled (no MAC in simulation) |

**Acceptance gate.**
- ACK RTT distribution recorded and compared against the symmetric-delay
  assumption; asymmetry reported rather than averaged away;
- duty cycle at the policy's Stressed rate is within the radio's regulatory
  and thermal limits, or the limit is reported as a constraint on the
  method;
- the **ACK-inclusive cost conclusion is recomputed** with measured airtime
  and duty cycle.

**Failure modes.** ACK traffic saturating the channel at the Stressed DATA
rate; asymmetric reverse delay invalidating the freshness estimate;
collisions between unsynchronised event-triggered senders — the failure the
broadcast-accounting result already predicts.

**Simulation assumptions validated.** Symmetric reverse-channel delay;
independent per-link loss with no medium contention; the broadcast and
airtime cost proxies. **This is the phase most likely to produce a negative
result, and the broadcast-accounting figure in the paper (25 % Moderate
non-dominance) is the prediction it tests.**

---

## H3 — One real UAV with network-in-loop

**Hardware needed.** One UAV with the target autopilot, two radios, a
ground node emulating neighbours, safety tether or netted volume.

**Software interface.** The swarm policy computes a setpoint from received
neighbour state; the setpoint enters the autopilot through the same
interface the simulation's `setpointFromAccel` models. Emulated neighbours
are driven from frozen trajectories.

**Measurement outputs.** Setpoint tracking error; controller saturation
fraction; CPU utilisation with the policy running; AoI measured at the
receiver; DATA/ACK rates; battery draw with and without the policy active.

**Acceptance gate.**
- the vehicle tracks emulated-neighbour formation setpoints with error
  attributable to the controller, not to the communication layer, and the
  attribution is argued from the saturation and AoI logs;
- no loss of control at the Stressed-equivalent link condition;
- CPU headroom consistent with H1.

**Failure modes.** The analytic command-consistent reference used in
simulation not matching the autopilot's actual setpoint semantics;
attitude saturation at commanded accelerations the simulation allowed.

**Simulation assumptions validated.** The setpoint interface and the
cascaded-controller model; the claim that the 6-DOF transition preserves
the communication ranking.

---

## H4 — Two-UAV coordination

**Hardware needed.** Two UAVs, radios, netted volume or open range with
geofence.

**Software interface.** Both vehicles run the policy; each is the other's
neighbour. Leader role either assigned to one vehicle or supplied by a
ground reference.

**Measurement outputs.** Formation RMSE against commanded offset; minimum
separation; AoI at both receivers; DATA/ACK rates; measured PDR in flight;
RTT in flight; controller saturation; energy per vehicle.

**Acceptance gate.**
- minimum separation stays above the safety threshold for the whole
  evaluation window across all trials, with trials counted and reported as
  `unsafe / eligible` in the same form the simulation uses;
- the adaptivity ordering is observed: DATA rate rises as measured link
  quality falls, over at least three distinguishable link conditions;
- no in-flight invariant violation.

**Failure modes.** Multipath and body shadowing producing loss patterns
correlated with vehicle attitude — a correlation the simulation's
independent-loss model does not contain; wind acting as a real disturbance
where the simulation used a proxy.

**Simulation assumptions validated.** Independent per-link loss; the
external-force proxy as a stand-in for wind; the adaptivity claim itself,
which is this campaign's primary positive result.

---

## H5 — Three-to-five UAV swarm

**Hardware needed.** Three to five UAVs, radios, range with adequate
separation volume.

**Software interface.** Full policy on every vehicle, ring topology to
match the simulated graph, leader pinning as configured.

**Measurement outputs.** All H4 metrics per vehicle, plus: per-sender
broadcast collapse actually achieved on the shared medium; channel
occupancy; scaling of DATA/ACK rate with neighbour count; degradation with
swarm size.

**Acceptance gate.**
- formation RMSE and minimum separation within the bounds the simulation
  predicts for the same N and link condition, **or** the discrepancy
  characterised and attributed;
- measured broadcast collapse compared against the simulation's broadcast
  accounting proxy;
- the safety boundary predicted by the degree-dependent consensus gain is
  either observed or shown absent.

**Failure modes.** Medium contention between unsynchronised senders
dominating at N ≥ 3; the degree-dependent safety boundary appearing in
flight; ACK traffic scaling worse than the simulation's per-link model.

**Simulation assumptions validated.** The broadcast proxy; the scalability
anchor; the degree-dependent safety boundary, which is currently a
controller attribution supported only by a simulation diagnostic.

---

## What hardware cannot validate

Stated so that no phase is mistaken for covering it:

- the **rejected** claims stay rejected — hardware cannot un-reject a
  simulation claim that failed, it can only test whether the same failure
  occurs;
- the **mass-mismatch steady offset** is a controller property and will
  reproduce on hardware unless the controller gains integral action;
- **topologies other than ring** are untested in the final validation and
  H5 does not add them;
- **timestep sensitivity** is a property of the trigger's evaluation
  schedule and must be addressed in the formulation, not on hardware.

## Sequencing note

H0–H2 require no vehicle and address the assumptions most in need of
measurement: packet sizes, serialisation, airtime, duty cycle, ACK RTT and
contention. Those are also the assumptions behind the one cost model under
which the method is clearly unfavourable. Doing them first means the
weakest part of the paper's cost argument is tested before any flight risk
is taken.
