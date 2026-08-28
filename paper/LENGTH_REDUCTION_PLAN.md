# Length reduction plan

## Trigger and boundary

The isolated TeX Live build of `paper/main.tex` is **23 pages** in the
current 10-point, two-column, letter-paper article layout. This exceeds the
estimated 12-page TCNS target. The count is not yet a TCNS-template count,
so template conversion must precede any final page-budget decision.

This file is a plan only. No major content cut has been executed.

## Material that must remain protected

Any shorter version must retain, in the main manuscript and at readable
size:

1. the ACK-inclusive reversal (fewer DATA packets but higher total cost);
2. the P12.5 counterexample, including 97.7% accuracy, 89.6% $C_{0.25}$
   cost, and 39.1% broadcast cost;
3. the complete negative/boundary-results table (`tableVI_negative_results`,
   Table 8 in the current compiled ordering);
4. the limitations section;
5. the EXP11 tuned-periodic caveat and the distinction between mechanistic
   adaptivity and mission-level Pareto superiority.

## Ranked compression actions for review

| Rank | Candidate action | Expected leverage | Scientific protection |
|---|---|---:|---|
| 1 | Convert a copy to the actual TCNS/IEEE template and recount before cutting | Establishes the real deficit; may change float and bibliography density | No content change |
| 2 | Move implementation-detail reproducibility prose and the appendix pointer material to the supplemental package, retaining frozen anchors and a concise reproducibility paragraph in the paper | Medium | Keeps numeric traceability and release boundaries in the main text |
| 3 | Consolidate the design-evolution narrative around Table II and Figure 3; remove repeated prose that restates the same four mechanisms | Medium | Keeps the causal-feedback mechanism, negative ablations, and oracle-information interpretation |
| 4 | Compress Related Work prose while retaining the explicit Kesper, Onozuka, Lin, Mamduhi, Ceran, WiSwarm, and Tahir distinctions and the cautious sentence “We did not identify prior work combining” | Medium | Keeps the novelty stress test and avoids stronger priority claims |
| 5 | Merge repeated robustness explanations between Results, Discussion, and Limitations; keep the attribution once in Results and once in the protected negative-results table | High | Keeps every rejected/boundary claim and controller-versus-communication attribution |
| 6 | Combine compatible plot panels (especially topology/fault and plant/estimator diagnostics) and shorten captions that duplicate body text | Medium | Keeps all negative evidence and units; no result deletion |
| 7 | Compress statistical-convention and common-random-number exposition to a compact protocol paragraph plus a reproducibility pointer | Low–medium | Keeps paired-CI definitions, no-p-value policy, eligibility rules, and per-channel/swarm-total distinction |
| 8 | Tighten the conclusion/future-work repetition after all earlier actions | Low | Keeps the central adaptivity claim, ACK-inclusive reversal, P12.5 caveat, and limitations |

## Decision gate

After template conversion, record the new page count and estimate the pages
saved by each candidate. Do not remove protected evidence or perform major
cuts until the ranked plan has been reviewed.
