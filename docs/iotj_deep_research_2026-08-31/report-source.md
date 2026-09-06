# Deep-research source report: Study 2 readiness for IEEE Internet of Things Journal

**Research date:** 31 August 2026  
**Repository reviewed:** `D:\Research\Drone\SwarmDroneMATLAB`  
**Manuscript reviewed:** `paper/study2/study2_manuscript_draft.tex` and included section drafts  
**Intended venue:** regular paper, IEEE Internet of Things Journal (IoT-J)  
**Evidence cutoff:** public sources located through 31 August 2026

## Research question

Is the current Study 2 direction—causal receiver-confirmed semantic freshness, standalone/piggyback ACK routing, and MAC-selective feedback for UAV swarm coordination—already strong enough for IoT-J? If not, what is the smallest credible research program that closes the remaining gaps without committing to a flight platform now?

## Executive finding

IoT-J is the nearest natural destination. The subject is squarely within its published scope: IoT protocols/networking, constrained systems, sensing–communication–control co-design, and testbeds/trials. The journal has also explicitly solicited work on AoI, data semantics, networking/scheduling, control co-design, and proof-of-concept experiments. Hardware is not a universal formal requirement: IoT-J publishes analytical and simulation-centered work when the theoretical or algorithmic contribution is strong.

The current study is **promising but not submission-ready**. Its strongest assets are the causal accounting discipline, negative-result retention, preregistered paired holdouts, multiple communication-cost definitions, branch-at-decision replay, and a narrow but statistically clean MAC-selective result. Its main weakness is no longer experimental hygiene; it is the combination of:

1. an over-broad novelty perimeter that overlaps established ACK-aware event-triggered control, delayed-feedback AoI, MAC-aware AoI, and feedback-cost literature;
2. a final selector supported only over a narrow abstract operating envelope, with modest CSMA gains and one ALOHA reversal cell;
3. no measured network trace, named-stack MAC validation, live radio evidence, or measured radio energy;
4. theory that explains the mechanism but does not yet replace empirical validation with an optimizing theorem or a broad stability result.

The nearest credible submission package is therefore **not** “buy UAVs and fly.” It is: repair the literature/claims; preregister a factorial interaction and operating-envelope study; run a real sensitivity audit; execute EXP15 with measured 802.11 traces; and add a randomized 3–5-node radio bench plus two-node energy measurement. Flight can remain future work. Genuine ALOHA should remain a simulation boundary unless a controllable radio/SDR is added.

## What the repository already establishes

The current manuscript frames a receiver-confirmed broadcast protocol in which innovation and refresh are separated, cumulative ACK information can be piggybacked or sent standalone, and the sender maintains a causal estimate of what neighbors know. The analytical chain relates ACK integrity to conservative age, semantic error, stochastic age tails, and an input-to-state stability statement for formation error. It also gives an exact ACK-airtime identity and uses branch replay to separate confirmation lead from downstream receiver/control value.

The strongest confirmatory artifact is EXP14I: 100 paired seeds per cell, six Holm-controlled one-sided hypotheses, and success in all three registered cells. Relative to the opposite feedback route, piggyback-only under the tested CSMA cells lowers RMSE by 0.97% at N=5 and 1.22% at N=10, while lowering offered utilization by 2.94% and 2.64%. Under the tested N=5 ALOHA cell, adaptive standalone-plus-piggyback lowers RMSE by 11.84% and offered utilization by 4.51%. Zero candidate safety failures were observed, but the reported 95% Wilson upper bound is 3.70%, so the manuscript correctly avoids a population-safety claim.

The N=20 study is appropriately descriptive: only 11 of 300 trajectories satisfy the full post-transient branch-support window. The parameter study is also appropriately described as screening rather than global sensitivity: one default plus 12 Latin-hypercube points, with three paired seeds each. EXP15 already adopts the right counterfactual principle: a trace collected from one policy is policy-conditioned and cannot simply be replayed as if it were an exogenous channel; the admissible replay input is a policy-independent absolute-time calibration of DATA/ACK loss and background medium occupancy.

These choices are unusually disciplined. They improve credibility, but they do not by themselves close the venue-level novelty and network-realism gaps.

## Literature map: the story the paper must tell

### 1. Event-triggered control reduced communication, then packet loss made the sender's information state important

Distributed event-triggered control established that agents can transmit on state-dependent events instead of periodically. Packet loss and delay then created a mismatch between a transmitter's local model and the state actually held by a neighbor. Wang and Lemmon studied distributed event triggering with network delays and packet loss. Garcia, Cao, and Casbeer addressed decentralized double-integrator consensus under packet loss and delay, including receiver-specific acknowledgement/retransmission ideas for inconsistent broadcast reception. Dolk and Heemels explicitly studied event-triggered control both with and without acknowledgements. Viel and co-authors later used estimates of an agent's own state as evaluated by neighbors under packet loss in distributed formation control.

**Implication:** neither “ACK-aware event trigger,” “receiver-specific confirmed state,” nor “event-triggered formation control under loss” is a safe novelty claim. The manuscript must treat these as foundations.

Primary sources: [Wang and Lemmon, IEEE TAC 2011](https://doi.org/10.1109/TAC.2010.2057951); [Garcia, Cao, and Casbeer, IET Control Theory & Applications 2016](https://ietresearch.onlinelibrary.wiley.com/doi/10.1049/iet-cta.2016.0107); [Dolk and Heemels, Automatica 2017](https://doi.org/10.1016/j.automatica.2017.02.029); [Viel et al., Automatica 2022](https://doi.org/10.1016/j.automatica.2022.110215).

### 2. AoI made freshness explicit, then delayed feedback made scheduling partially observable

AoI research separated freshness from throughput and delay, while semantic and goal-oriented variants recognized that equal-age updates need not have equal task value. Two-way delay and delayed ACK work then treated the source's knowledge of receiver freshness as uncertain or delayed. Pan and co-authors studied unreliable transmissions with random forward and backward delay; Wang characterized AoI with queueing delay in both directions; Tahir and co-authors used delayed acknowledgements and particle-filter beliefs under partial observability in a capacity-limited duplex setting.

**Implication:** causal sender belief under delayed ACKs is well motivated, but delayed-feedback belief estimation itself is not the novelty. The existing Tahir-like delayed-belief baseline is therefore important and should remain.

Primary sources: [Pan et al., IEEE/ACM Transactions on Networking](https://arxiv.org/abs/2201.02929); [Wang, IEEE/ACM Transactions on Networking 2024](https://docs.lib.purdue.edu/ecetr/764/); [Tahir et al., IFIP Networking 2024](https://dl.ifip.org/db/conf/networking/networking2024/1570998329.pdf); [AoI survey by Yates et al.](https://user.eng.umd.edu/~ulukus/papers/journal/aoi-survey.pdf).

### 3. Shared-medium AoI work showed that access rules change freshness

AoI under random access has been analyzed for slotted ALOHA and CSMA. Mena and Núñez explicitly developed a MAC perspective for IoT networked control, deriving AoI behavior for CSMA/CA and TDMA and using it for MAC selection. Peng and co-authors used piggybacked collaboration information to optimize an AoI-aware V2X sidelink MAC.

**Implication:** “MAC changes AoI” and “piggybacking can support freshness-aware access” are not new. The manuscript's contribution must be the *specific feedback-route mechanism* in semantic broadcast control, not the generic fact that MAC matters.

Primary sources: [Kadota et al., IEEE INFOCOM 2020](https://www.mit.edu/~kadota/PDFs/INFOCOM_2020.pdf); [Mena and Núñez, Automatica 2023](https://doi.org/10.1016/j.automatica.2022.110652); [Peng et al., IEEE Transactions on Wireless Communications 2021](https://arxiv.org/abs/2002.10242).

### 4. Feedback has value, but it also consumes transmission opportunities

Munari and Badia directly study when feedback is worth its cost for AoI under limited transmission opportunities. Their analysis identifies operating regions where feedback helps and where its resource cost makes no-feedback preferable. Standard transport practice also already includes delayed and piggybacked acknowledgements.

**Implication:** “standalone ACKs sometimes help and sometimes do not” is too close to existing work to carry novelty alone. The current title risks signaling that overly broad claim. What remains distinctive is the pathwise causal mediation in a broadcast control loop: an ACK changes the transmitter's belief, this changes later DATA decisions, and therefore earlier confirmation need not improve actual receiver freshness or control performance. The targeted search found no prior work that directly establishes this exact chain in a semantic UAV-swarm broadcast setting. That absence is evidence of a plausible gap, not proof of global priority; the paper should avoid an unqualified “first.”

Primary sources: [Munari and Badia, IEEE Transactions on Communications 2025](https://elib.dlr.de/216423/); [conference version, IEEE GLOBECOM 2022](https://www.dei.unipd.it/~badia/papers/2022_12_Globecom2022151866.pdf); [IETF RFC 9006, TCP usage guidance for IoT](https://www.rfc-editor.org/info/rfc9006/); [IETF RFC 4340, DCCP acknowledgement/piggyback mechanisms](https://www.rfc-editor.org/info/rfc4340/).

### 5. UAV-swarm networking raises the empirical bar

WiSwarm is the closest systems reference: an AoI-oriented Wi-Fi middleware for UAV swarms that addresses collisions, stale packets, and relevance, and reports flight experiments. A recent IoT-J swarm-consensus paper combines an event-triggered protocol and theory with board-based Wi-Fi experiments. These do not make hardware mandatory for every IoT-J paper, but they define what a systems-facing swarm claim will be compared against.

**Implication:** the present study can remain hardware-agnostic at the control layer, yet needs at least a measured networking bridge if it wants to make communication/IoT claims rather than an idealized-channel claim.

Primary sources: [WiSwarm, IEEE INFOCOM 2023](https://ieeexplore.ieee.org/document/10228860/); [Privacy-Preserving Average Consensus for Swarm Systems Subject to DoS Attacks, IEEE IoT-J 2025](https://ieeexplore.ieee.org/abstract/document/11192496/).

## Venue fit and the hardware question

The [IoT-J author guidelines](https://ieee-iotj.org/guidelines-for-authors/) describe a broad scope that includes architecture, protocols/networking, constrained networks, applications, testbeds, and trials. An official [IoT-J AoI special-issue call](https://ieee-iotj.org/wp-content/uploads/2020/03/CFP_AoI_IoTJ.pdf) explicitly includes data semantics, sensing–communication–control co-design, networking/scheduling, and proof-of-concept experiments. The [IEEE Communications Society issue digest](https://www.comsoc.org/system/files/2021-10/Publications_Contents_Digest_2021_Oct.pdf) shows analytical/simulation AoI and control-aware transmission papers in IoT-J. A recent decentralized event-triggered quantized-control article is another example of simulation-centered work accepted on the strength of its method and stability analysis ([DOI 10.1109/JIOT.2025.3634081](https://doi.org/10.1109/JIOT.2025.3634081)).

Therefore, hardware is **not a formal universal gate**. It becomes the economically sensible gate for this manuscript because the current analytical result is conditional and conservative, while the selector is deliberately simple and the CSMA effect size is small. There are two viable routes:

- **Empirical route (recommended):** measured trace replay plus 3–5-node live-radio validation and measured energy. This preserves the current mechanistic contribution and requires no committed flight platform.
- **Theory route:** replace much of the empirical burden with a substantially stronger optimization/stability result over a well-defined class of access and feedback policies. This is closer to a TCNS-style project and is likely more work than a bench experiment.

## Collision audit: current story versus defensible story

| Tempting claim | Why it is unsafe | Defensible replacement |
|---|---|---|
| ACK-aware event triggering is novel | Explicit ACK/no-ACK ETC and receiver-specific acknowledgement protocols predate this work | We study how causal receiver confirmation enters a semantic broadcast trigger and mediate its downstream value through future DATA decisions |
| Delayed ACK creates a new causal freshness problem | Two-way delay, delayed-feedback AoI, and delayed-ACK belief estimation are established | We integrate causal confirmed-age/semantic belief with broadcast formation control and distinguish confirmation lead from receiver/control value |
| The MAC layer changes whether feedback helps | MAC-dependent AoI and feedback-cost regions are established | We expose and preregister a feedback-route-by-access interaction in a shared-medium semantic control loop |
| Piggyback/standalone ACK selection is itself novel | Piggybacking and delayed ACK are established protocol mechanisms | The contribution is the causal selection criterion and its control/network evidence, not either packet format |
| The selector generalizes across swarm networks | It is confirmed only in two CSMA cells and one ALOHA cell; N=20 is support-limited | We identify a bounded operating envelope and report outside-envelope failures/indeterminacy |
| Zero observed safety failures establishes safety | With 100 runs per cell, the Wilson upper bound remains 3.70% | No candidate failure was observed in the registered sample; this is not a population-safety guarantee |

## What must be added before submission

### Gate A — repair the literature perimeter and claims (mandatory, low cost)

Add and directly compare against the ACK-aware ETC, delayed-feedback AoI, MAC-perspective, feedback-cost, and WiSwarm streams above. Rewrite the novelty paragraph so that individual ingredients are explicitly non-novel. Avoid “first” unless a systematic-review protocol supports it. Consider retitling away from the generic question “when standalone ACKs help” because Munari–Badia already own that broad framing.

A safer contribution sentence is:

> We jointly expose and quantify a causal feedback-mediation effect in shared-medium semantic broadcast control: standalone ACKs modify the sender's receiver-state belief, which can suppress or redirect future DATA transmissions, so earlier confirmation is not equivalent to fresher receiver state or better closed-loop performance; the sign of this effect changes across a declared access/load envelope.

### Gate B — confirm the interaction, not only three directional contrasts (mandatory)

Preregister a factorial holdout, provisionally EXP16, with feedback route × access mechanism as the primary interaction. Use matched operating points and shared seeds, and test a difference-in-differences contrast for RMSE and offered airtime. The current six directional hypotheses show that selected policies win within their cells; they do not, by themselves, constitute a formal interaction test.

Map an operating envelope over at least two offered-load levels, two forward/reverse loss or burst levels, N=5 and N=10, and at least one reverse-asymmetry or hidden-terminal condition. The objective is not to retune the selector. It is to identify where the sign is stable, where it reverses, and where the data are indeterminate. Keep N=20 descriptive unless branch support is deliberately increased without post-hoc conditioning.

### Gate C — replace parameter screening with a robustness/sensitivity study (mandatory)

The 12-point, three-seed LHS is useful development screening, not a venue-level sensitivity analysis for a multi-threshold policy. Freeze the final policy and use a larger Morris/Sobol-style design, or a preregistered structured robustness grid if computational cost dominates. At minimum vary confirmed-age threshold, ACK maximum deferral, refresh cooldown, access scaling, ACK entry/frame size, load, forward/reverse burstiness, and reverse delay. Report sign stability and failure regions; do not select the best configuration after viewing the holdout.

### Gate D — build a measured-network bridge (strongly recommended; likely decisive)

Execute EXP15 using policy-independent absolute-time calibration traces and maintain separate DATA/ACK models. Then add a live randomized crossover bench:

1. two nodes for packet airtime and radio-energy calibration;
2. three nodes for protocol correctness, ACK causality, and contention smoke tests;
3. five nodes for the main CSMA validation, repeated over randomized time blocks, days, and at least two geometries/load levels;
4. packet capture plus synchronized application logs, queue delay, PDR, RTT/ACK delay, channel busy fraction, DATA/ACK airtime, and energy.

Do not claim that the current p-persistent CSMA simulator implements IEEE 802.11 DCF/EDCA. Calibrate a distinct measured-802.11 layer. The proposed Raspberry Pi 5 plus AR9271/ath9k_htc stack is reasonable for a Linux/mac80211 testbed; official Linux Wireless documentation confirms AR9271 support and IBSS/monitor capabilities ([ath9k_htc documentation](https://wireless.docs.kernel.org/en/latest/en/users/drivers/ath9k_htc.html)).

Scheduling application transmissions over Wi-Fi does **not** create genuine ALOHA because the underlying 802.11 clear-channel assessment remains active. The least-cost honest choice is to validate the CSMA branch on Wi-Fi and label ALOHA as a simulation boundary. Genuine ALOHA requires a radio/SDR stack with controllable channel access.

### Gate E — energy, runtime, and reproducibility (mandatory but compact)

Replace the current power proxy with measured radio energy for the two-node bench. Report trigger/ACK-scheduler computation time and memory on the selected companion computer; the expected complexity should be stated in terms of out-degree and ACK entries/queue. Publish a one-command reproduction path, generated tables/figures, environment metadata, a frozen release tag, and an archival DOI if possible.

### Gate F — threat model, not a security detour (required scope statement)

State that ACKs are honest but can be delayed, lost, duplicated, or reordered. Explain that sequence numbers and cumulative confirmation protect protocol invariants but do not authenticate a sender. Briefly state how authenticated frames or message authentication codes would prevent spoof/replay within the assumed keying model. Full jamming/spoofing experiments are optional unless security becomes a claimed contribution.

## Minimum IoT-J submission package

The following is the minimum package I would recommend sending to an IoT-J editor/reviewer:

- literature and novelty rewritten around causal feedback mediation rather than ACK-aware triggering generally;
- one close ACK-aware ETC baseline plus the existing delayed-belief, periodic, state-trigger, piggyback-only, adaptive, and ideal-information references;
- preregistered factorial interaction test and bounded operating-envelope map;
- meaningful sensitivity/robustness analysis of the frozen policy;
- EXP15 calibrated trace replay;
- 3–5-node measured 802.11 CSMA bench and two-node energy calibration;
- explicit abstraction ladder and honest ALOHA boundary;
- public, one-command reproduction artifact.

Not required for this nearest submission: purchasing a final UAV platform, flight trials, a full adversarial-security study, or a TCNS-level general stability theorem. Each would strengthen the work, but none is the shortest path to a credible IoT-J manuscript once the measured networking bridge exists.

## Readiness scorecard

| Dimension | Current assessment | Submission gate |
|---|---:|---|
| IoT-J topical fit | High | Passed |
| Experimental discipline/statistics | High | Preserve |
| Novelty framing | Medium/high collision risk | Gate A |
| Closest-baseline coverage | Insufficient | Gates A–B |
| Breadth of selector evidence | Insufficient | Gates B–C |
| Communication realism | Insufficient | Gate D |
| Hardware/energy evidence | Missing | Gates D–E |
| Theory | Useful explanatory support; not a substitute for validation | Keep claims conditional |
| Security scope | Acceptable if honest-ACK model is explicit | Gate F |
| Reproducibility | Strong internal provenance; public artifact incomplete | Gate E |

## Final verdict

**Yes: IoT-J is the nearest sensible target. No: the present evidence is not yet enough for submission.** The central idea remains worth pursuing, but the paper should no longer sell “ACK-assisted AoI-aware event triggering” as the novelty. It should sell a narrower and more defensible discovery: in semantic broadcast control, ACK value is causally mediated by future DATA decisions, and the preferred feedback route changes over a declared shared-medium operating envelope. The research program should now optimize evidence, not add more algorithmic knobs.

The recommended order is: Gate A → preregister Gates B/C → execute B/C → execute EXP15 and the CSMA bench → Gate E/F → rewrite and internal review. A go/no-go submission decision should be made only after the measured layer confirms the qualitative mechanism and the factorial interaction survives without post-hoc retuning.

## Search limitations

The search prioritized primary papers, official venue material, publisher pages, author repositories, and standards. IEEE Xplore indexing and publisher access can omit full text or newly indexed papers, so absence of an exact “early ACK suppresses later DATA and worsens closed-loop receiver value” match is not proof that none exists. The manuscript should therefore use qualified novelty language and repeat a final backward/forward citation search immediately before submission.

