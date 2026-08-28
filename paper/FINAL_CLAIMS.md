# Final claims after EXP11

This is the canonical post-EXP11 claim ledger. Scientific results from the
main campaign remain frozen at `simulation-v1.0` (`32858b1`). EXP11 is
separately frozen supplemental evidence at `exp11-locked-supplemental`
(`7b64af6`), outside that release boundary; the paper may cite and use it.

## Central claim

> The contribution is adaptivity under unknown and changing network
> conditions with one fixed causal policy, not universal dominance over a
> tuned fixed periodic communication rate.

Two levels of evidence must remain distinct:

- **Mechanistic adaptivity:** communication effort changes within a mission
  as network quality changes, without a regime label or retuning. EXP11 H1
  supports this claim at all four adjacent transitions.
- **Mission-level Pareto superiority:** an aggregated operating point
  dominates alternatives in error and a selected communication-cost model.
  EXP11 does not establish this generally; P12.5 is the key counterexample.

## Locked EXP11 verdicts

| ID | Status | Claim and boundary | Generated evidence |
|---|---|---|---|
| H1 | **SUPPORTED** | A fixed Causal-v3 policy changes DATA effort when network quality changes within the same mission, without receiving the regime label. | All four adjacent paired rate-difference CIs have the expected sign. |
| H2a | **SUPPORTED** | For the EXP11 mission, Causal-v3 has lower RMSE than P10. | `exp11.h2a.rmse_causal_minus_p10` |
| H2b | **SUPPORTED only at pre-registered `w=0.25`** | For the EXP11 mission, Causal-v3 has lower ACK-weighted total cost than P20 at `w=0.25`. | `exp11.h2b.total_w025_causal_minus_p20` |
| H3 | **CHARACTERIZATION** | Periodic-rate frontier, including P12.5. | Table VIII and Figure 13. |
| H4 | **CHARACTERIZATION** | Regime-aware oracle-periodic information gap. | EXP11 oracle comparison; not a performance bound. |

All headline values above are generated from
`results/exp11_dynamic_network/2026-08-27_174026/tidy.csv`; the source hash
and verdict checks are in `paper/generated/exp11_verification.json`.

## Prominent counterexample

P12.5 must remain in the main text, not an appendix. Relative to Causal-v3
over the complete EXP11 mission, it retains:

- **97.7% of Causal-v3 accuracy**;
- **89.6% of `Total_w025` cost**;
- **39.1% of broadcast cost**.

These ratios are generated from the frozen persisted result. They show why
mechanistic adaptivity cannot be promoted into universal mission-level
dominance.

## Claims not supported

- Universal superiority over a tuned fixed periodic rate.
- General ACK-inclusive communication superiority over P20; H2b is tied to
  the single pre-registered weight `w=0.25`.
- A broadcast-medium communication advantage. EXP11 reverses the P20
  comparison under broadcast accounting.
- Any hardware result, measured sensor model, physical air-flow model, or
  closed-loop stability guarantee.
- Any reduction in total radio traffic inferred from DATA-only accounting.

## Existing main-campaign claims retained

- The dual-memory, cumulative-ACK mechanism is causal at the sender and
  distinguishes new information from refresh traffic.
- Causal-v3 beats the conventional state-event baseline throughout the
  frozen final matrix and beats P10 under the pre-registered Stressed
  accuracy comparison.
- The seven rejected/bounded pre-registered claims remain rejected or
  bounded. EXP11 does not reopen them.
- Sampled-grid evaluation gives
  `t_(n+1)^(ij) - t_n^(ij) >= h > 0`, excluding Zeno behavior by
  construction; this is not a closed-loop stability proof.

## Novelty wording

Permitted wording:

> We did not identify prior work combining ACK-derived receiver-freshness
> estimation, state-innovation threshold modulation, and separate
> new-information/refresh handling with in-flight suppression in a
> distributed multi-agent/UAV communication policy.

Do not claim priority. Tahir et al. (2024) already combine delayed ACKs,
receiver-AoI belief estimation and decentralized multi-agent scheduling;
Kesper et al. (2023) combine learned distributed multi-agent triggering with
last-broadcast states and explicit age timers; Lin et al. (2023) provide a
direct AoI-aware event-triggered controller; and Onozuka et al. (2024) apply
AoI/event triggering in both forward and feedback control communication.
The narrower combination above is the defensible distinction.
