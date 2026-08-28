# Highlights

Four items, one sentence each. No superlative that the frozen data does not
support: no "first", no "optimal", no "robust", no unqualified "efficient".

---

1. A causal ACK-assisted, AoI-aware event-triggered communication policy in
   which each sender estimates its receiver's information freshness only
   from cumulative acknowledgements, never by reading receiver state.

2. Separating genuinely new information from refresh traffic — so that a
   repetition cooldown governs repetition alone — restores adaptivity that
   is otherwise lost, and does so without changing any threshold value.

3. On 50 holdout seeds and 3400 runs with 6-DOF quadrotor followers, one
   fixed parameterization adapts DATA traffic monotonically with network
   quality (84.47 → 134.84 → 182.94 Hz) and attains lower formation error
   than a conventional state-event trigger in all 17 cells of the final
   matrix.

4. The reduction is DATA-only: against 20 Hz periodic, DATA falls by
   16.73 Hz while the ACK-inclusive total rises by 10.67 Hz (both 95 %
   intervals excluding zero), so no reduction in total radio traffic is
   claimed — and a non-causal ideal-feedback policy is used as an
   information-efficiency reference rather than as a bound on accuracy.

6. **EXP11 directly supports within-mission adaptivity, not universal
   dominance.** With no regime label, fixed Causal-v3 changes effort at all
   four network transitions. P12.5 remains the prominent counterexample:
   97.7% of Causal-v3 accuracy at 89.6% of `Total_w025` and 39.1% of
   broadcast cost.

---

## Notes for whoever adapts these

- Items 3 and 4 must travel together. Item 3 alone reads as an efficiency
  claim that item 4 exists to bound.
- Every number is in `paper/generated/headline_metrics.csv`; if the dataset
  is ever regenerated, re-read them from there rather than editing here.
- If a venue allows only three highlights, merge 1 and 2 — the mechanism
  and its semantic split are one contribution — and keep 3 and 4 intact.
- Results are simulation only. No highlight may imply otherwise.
