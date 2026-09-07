# FB1 ACK-free novelty audit

**Audit date:** 2026-09-07  
**Decision:** `FB1_CONDITIONAL_PASS`  
**Exact-candidate collision found:** `NO`  
**Authorization:** proceed only to AF0--AF4; AF5 remains gated by exactness,
calibration, and counterfactual predictive validity.

## 1. Candidate audited

The candidate is deliberately narrower than an ACK-free event trigger or a
generic value-of-information (VoI) scheduler.  On a directed controller link
\(j\to i\), the sender maintains the exact probability mass function

\[
b_{ij}^k(s)=\Pr(R_{ij}(k)=s\mid\mathcal I_j^0(k))
\]

over packet identities that the receiver may currently hold, using only the
common initial condition, the sender's DATA transmission history, time, and
the frozen channel law.  It then evaluates the expectation of the exact
Gate-3 finite-horizon formation-impact quantity

\[
\bar q_{ij}(k)=\sum_s b_{ij}^k(s)q_{ij}(k;s),\qquad
q_{ij}(k;s)=\frac{p_s}{m}
\left(\lVert Z_s\rVert_F^2-
\lVert Z_s+G_{ij,s}\rVert_F^2\right).
\]

The audited combination therefore has three indispensable elements:

1. no explicit or implicit receiver feedback;
2. a packet-identity distribution for the receiver-held memory state; and
3. belief integration of an action-specific, sampled closed-loop,
   finite-horizon quadratic formation-impact cross-term.

Removing item 3 changes the candidate into known ACK-free multi-hypothesis
event-triggered formation control.  Replacing \(q(s)\) by a weighted AoI,
expected state error, static graph centrality, or an isolated response norm is
outside the audited novelty claim.

## 2. Search scope and method

The audit extended the repository's earlier literature matrices through
2026-09-07.  Searches covered combinations of ACK-free/no-feedback control,
receiver-memory uncertainty, packet-loss hypotheses, event-triggered
multi-agent formation, VoI/AoI formation scheduling, finite-horizon action
value, and delayed/lossy networked control.  Full text was inspected for the
closest overlaps.  Publisher, author-hosted, or archival primary sources were
used wherever available.

This is a scoped novelty audit, not a proof that no unpublished or
unindexed work exists.

## 3. Closest prior art and collision analysis

| Work | What is already covered | Missing relative to the exact candidate | Collision verdict |
|---|---|---|---|
| Viel et al., *Automatica*, 2022, DOI 10.1016/j.automatica.2022.110215 | Distributed nonlinear multi-agent formation under IID packet loss; no explicit ACK is needed for its packet-loss-hypothesis probabilities; each sender maintains multiple hypotheses for the state believed to be held by a neighbor; the trigger uses expected estimation-error moments and is supported by stochastic Lyapunov analysis. | No communication delay in the audited model; no exact Gate-3 sampled finite-horizon action-versus-no-action formation-cost cross-term; no communication/performance Pareto comparison with a charged feedback architecture. | **Highest threat.** It defeats novelty claims based on ACK-free receiver belief, multiple hypotheses, expected receiver error, or formation triggering under packet loss. It does not cover the complete audited combination. |
| Dolk and Heemels, *Automatica*, 2017, DOI 10.1016/j.automatica.2017.02.029 | Event-triggered control under packet losses with ACK and no-ACK implementations; auxiliary histories handle uncertainty about what the controller received; stability and performance guarantees. | Not distributed formation; not a probability distribution integrated with the Gate-3 action-specific finite-horizon formation impact. | Strong architectural precedent, no exact collision. |
| Garcia and Antsaklis, ACC 2021, DOI 10.23919/ACC50511.2021.9483412 | Model-based event-triggered control without ACK over a lossy channel, using dropout limits and sender/controller model-error bounds. | Set/bound-based rather than the audited exact packet-memory PMF and expected quadratic formation-action value; not multi-agent formation. | No exact collision. |
| Soleymani et al., *IEEE TAC*, 2023, DOI 10.1109/TAC.2022.3194125 | Globally optimal VoI threshold structure for finite-horizon Gauss--Markov LQG feedback control; VoI is the marginal regulation benefit of a packet minus its cost. | Different centralized LQG information structure; not a distributed receiver-held-packet PMF without feedback; not the implemented formation dynamics. | Establishes that marginal control value itself is not novel; no exact collision. |
| Soleymani et al., arXiv:2403.11932, 2024 | VoI consistency under packet loss and fixed delay. | Successful decoder reception is acknowledged to the encoder; therefore not ACK-free receiver-memory inference. | No exact collision, but relevant delayed/lossy VoI comparator. |
| Chiariotti and Fabris, IFAC-PapersOnLine, 2025, DOI 10.1016/j.ifacol.2025.12.071 | Signaling-free AoI/VoI-aware scheduling for multi-agent formation; expected localization error and graph-centrality weighting allocate a fixed resource budget. | No uncertain receiver-held DATA memory under packet delivery loss; no action-conditioned Gate-3 finite-horizon formation-cost difference. | Defeats claims of first signaling-free VoI scheduling for formation; no exact collision. |
| Garcia et al., *IET CTA*, 2016, DOI 10.1049/iet-cta.2016.0107 | Decentralized event-triggered double-integrator consensus with packet losses and delays. | No exact ACK-free receiver-memory PMF and no finite-horizon marginal formation value. | Domain overlap, no exact collision. |

Primary full-text checks:

- Viel et al.: <https://w3.onera.fr/copernic/sites/default/files/2022_automatica_event_triggered.pdf>
- Dolk and Heemels: <https://doi.org/10.1016/j.automatica.2017.02.029>
- Garcia and Antsaklis: <https://arxiv.org/abs/2007.15181>
- Soleymani et al.: <https://ieeexplore.ieee.org/document/9842327>
- Chiariotti and Fabris: <https://arxiv.org/abs/2507.06392>

## 4. What may and may not be claimed

The audit supports only this provisional differentiator:

> An ACK-free sender-side distribution over receiver-held packet identities is
> integrated with the exact sampled finite-horizon, action-specific quadratic
> formation-impact cross-term derived from the implemented closed-loop model.

It does **not** support any of the following claims:

- first ACK-free/no-feedback event-triggered controller;
- first receiver-state multi-hypothesis estimator under packet loss;
- first expected receiver-error trigger;
- first communication-aware or signaling-free formation scheduler;
- first VoI metric for control or formation;
- first multi-agent formation controller under packet loss/delay.

If the project reaches an active comparison, Viel et al. 2022 is a mandatory
direct baseline or mechanism ablation, not merely a citation.

## 5. Scientific distinction still at risk

### Risk FB1.1 -- algebraic collapse

If \(\sum_s b(s)q(s)\) reduces, under the implemented assumptions, to the
same expected state-error moments used by Viel et al., the remaining novelty
is insufficient.  This must be checked explicitly in AF3.

### Risk FB1.2 -- sender-local identifiability

Receiver-memory uncertainty is only one missing variable.  The exact Gate-3
identity also contains

\[
-2\langle Z_s,G_{ij,s}\rangle_F,
\]

where \(Z_s\) includes the no-action closed-loop response, other-link inputs,
and leader/receiver residuals.  The earlier
`LOCAL_VALUE_SIGN_NOT_IDENTIFIED` checkpoint established that the sender's
ordinary local information does not currently identify this cross-term.
AF3 may not silently read centralized plant or receiver truth.  If the exact
quantity cannot be expressed using the declared no-feedback sender
information set, the track must stop before AF5.

### Risk FB1.3 -- generic VoI framing

Finite-horizon marginal regulation value is established prior art.  Any later
claim must be tied to the implemented distributed formation degradation
dynamics, the receiver-memory uncertainty, and the measured frontier under
unreliable communication, rather than to the word “VoI.”

## 6. Frozen FB1 decision

`FB1_CONDITIONAL_PASS` means only that no inspected source covers all three
indispensable elements of Section 1.  It authorizes the smallest falsification
sequence:

1. AF0--AF1: derive and test the exact no-ACK receiver-memory PMF;
2. AF2: passive calibration under the matched S2/S6 channel;
3. AF3: prove sender-local computability of the expected Gate-3 value and
   test for algebraic prior-art collapse;
4. AF4: forced-action predictive validation.

Any failure invokes the Research Lead's mandatory stop.  This audit does not
authorize AF5, held-out evaluation, scalability experiments, parameter
tuning, or expanded manuscript claims.

