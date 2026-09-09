# SQ hostile-review simulation

**Scientific baseline:** **7c679610af2098acc2aa5e8f005e81a898435f29**  
**Review date:** 2026-09-08  
**Purpose:** adversarial internal review before submission QA. These reviews
assess the accepted scientific baseline; they do not authorize new theory,
policies, or experiments.

## Reviewer A — functional observability / systems theory

**Verdict:** **MAJOR**

1. The generic affine-value, row-space, finite-history, and coalition tests
   are direct consequences of established functional observability and sensor
   selection. The manuscript must present them as imported
   propositions/specializations and foreground the decision-regret,
   reachable-witness, multi-action, and economics synthesis.
2. “Functional observability” risks conflating instantaneous reconstruction
   with dynamic functional-observer theory. The current-value result should be
   called static or instantaneous reconstructibility, and the paper must say
   that it is not an observer-existence, detectability, order, or pole-placement
   result.
3. The fixed-response condition is vulnerable to overstatement. The ten-link
   audit uses a structural unit correction, whereas only two reachable
   witnesses use physical action responses. A state-dependent response must be
   augmented or fixed on the information fiber; a zero response is trivially
   identifiable.
4. The regret result should be stated for a possible net threshold
   \(v=q-\tau\), with the witnesses explicitly using \(\tau=0\), and should
   report normalization/units and boundary cases.
5. The \(r^\star\) result is only for instantaneous, noiseless,
   arbitrary-precision real-valued linear statistics. It must not be confused
   with observer order, sensor count, bits, packets, or data rate. The reduced
   history maps and full current maps also need to be distinguished.

## Reviewer B — networked control / value of information

**Verdict:** **MAJOR**

1. The paper's \(q\) is a conditional fixed-response finite-horizon marginal
   output-cost benefit, not a general Bellman VoI or state-action value
   function. The frozen controller, horizon, response, and no-action baseline
   must be stated.
2. Exact realized-value identifiability is not a prerequisite for a useful or
   even optimal Bayesian policy. The theorem only characterizes reproduction
   of the full-information fixed-response value/sign. Receiver-memory
   marginalization is not \(\mathbb E[q\mid\mathcal I_j]\) without a joint
   state prior.
3. The binary-regret threshold should be generalized by shifting the value;
   the numerical witnesses should state \(\tau=0\), units, and normalization.
4. Figure 4 and the economics table price an ACK-like stream, not an actual
   protocol that acquires the all-agent missing statistic. They are a
   necessary cost-sensitivity screen, not an acquisition-cost measurement.
5. The five-seed development results are illustrative mechanism evidence and
   cannot support population, dominance, or practical-generalization claims.

## Reviewer C — multi-agent / UAV systems

**Verdict:** **MAJOR**

1. The five-agent coalition result may be induced partly by the selected
   global performance output. It must remain conditional on that output
   weighting, horizon, graph, and information maps; localized objectives may
   require smaller coalitions.
2. The N=5 instance is too opaque without the exact adjacency/pinning
   structure, gains, and sender-information definition. It should be presented
   as an implementation-faithful counterexample, not a typicality or
   scalability result.
3. “Exact closed-loop action value” is broader than the fixed-response object
   that is actually derived. Use the narrower term at claims and decision
   boundaries.
4. Both dynamic witnesses use leader sender 1. They establish physical
   relevance for ordinary and pinned-memory payload classes, not sender
   diversity or prevalence across the graph.
5. There is no 6-DOF or hardware validation. The paper should position the
   example as a sampled formation-control case. The small regret values certify
   strict sign divergence, not engineering-scale mission loss; all empirical
   captions should identify development data.

## Author-response and change table

| Review criticism | Valid? | Response | Manuscript change / no-change justification |
|---|---|---|---|
| A1: generic tests are established functional observability | Yes | The core novelty is the control-decision consequence and system/economic closure, not the row-space identity. | Related Work and Sec. V now call the current/history tests classical specializations; the contribution ordering foregrounds minimax regret and simultaneous-action information. |
| A2: instantaneous versus functional-observer theory | Yes | Static reconstruction, dynamic observer construction, and sample-based observation are different questions. | Theorem 1 is renamed “Static fixed-response action-value identifiability”; explicit exclusions cover detectability, observer order, and pole placement. |
| A3: fixed-response and ten-link overreach | Yes | The affine theorem requires \(g\) fixed on the compatible fiber. The ten-link calculation is structural; the two trajectory witnesses are physical. | Secs. IV and VIII now state the unit \([1,0,0]^\top\) response, zero-response edge case, possible cancellation, and the narrower “structural unit-response functional” claim. |
| A4: threshold, boundary cases, and units | Yes | The regret theorem applies after the shift \(v=q-\tau\); the strict-straddle formula does not cover boundary endpoints. | Sec. V-C adds all zero/non-straddling/symmetric edge cases and the threshold shift; Sec. VIII gives \(\mathrm{m}^2\) units and \(\tau=0\). |
| A5: scope of \(r^\star\) and two map types | Yes | Statistic dimension is not a transport or observer metric. | Theorem 4 and its corollary now say instantaneous, noiseless, arbitrary-precision, real-valued, and linear. Sec. VIII distinguishes reduced history maps from current 99-state maps. |
| B1: \(q\) is not general VoI | Yes | The manuscript studies a fixed-decision marginal output-cost functional. | Sec. IV explicitly freezes baseline, controller, horizon, and action response and excludes Bellman values, \(Q\)-functions, and future reoptimization. |
| B2: Bayesian policies do not need clairvoyant realized value | Yes | Exact-value reconstruction is a narrower design question, not a necessary condition for all useful decisions. | Related Work, Sec. IV, and Limitations now state the distinction; no optimal Bayesian comparator is claimed or evaluated. |
| B3: regret threshold and units | Yes | Same response as A4. | Shifted-interval paragraph and revised witness-table caption. |
| B4: ACK economics is not actual global-statistic acquisition | Yes | The existing experiment can only support a cost-sensitivity screen. | Figure 4, abstract, contribution C4, and Sec. VIII-D use “ACK-like” and explicitly deny protocol acquisition-cost measurement. |
| B5: development evidence is non-inferential | Yes | The experiments motivate/falsify mechanisms; analytical results carry the paper. | Captions and Limitations now say five paired development seeds, descriptive/non-inferential, and no population claim. |
| C1: coalition depends on global output | Yes | Coalition ownership is objective- and topology-dependent. | Sec. VIII-C now conditions the result on the global stacked formation-error output, identity weighting, \(H=25\), graph, and maps, and notes localized objectives. |
| C2: implementation instance was opaque | Yes | A reader should be able to reconstruct the graph and gains without code. | Sec. III now gives the full adjacency matrix, pin vector, sampling period, and controller gains; sender information remains explicit in Sec. III-B. |
| C3: “exact action value” is too broad | Yes | Claims now use “conditional fixed-response finite-horizon marginal benefit” where scope matters. | Abstract, research question, Sec. IV, key captions, and conclusion were scrubbed. Symbol \(q\) remains concise after its definition. |
| C4: both witnesses use the leader | Yes | They cover payload-memory semantics, not sender diversity. | Sec. VIII-B and Fig. 6 now state this explicitly. |
| C5: practical/UAV overreach | Yes | No 6-DOF, hardware, or scalability inference is needed for the analytical paper. | Limitations preserve sampled double-integrator scope; witness regret is described as strict divergence rather than mission-scale loss. No new validation was added. |

## Post-response assessment

All three **MAJOR** verdicts identify presentation or scope risks rather than a
correctness failure. Every scientifically valid criticism has a corresponding
manuscript change. No reviewer requested evidence that is necessary to sustain
the frozen analytical claims once those claims are narrowed. The residual
editorial risk is that the control/communication synthesis may still be judged
incremental relative to functional-observability theory; it is retained in the
reviewer-risk register rather than hidden.
