# EXP22M: sharp 1%-cost periodic-frontier closure

**Frozen before randomized outcomes:** 2026-09-01  
**Parent:** valid EXP22L (`2026-09-01_195423`)  
**Stage:** final periodic-frontier development falsification  
**Tuning, robustness, promotion and submission claims:** prohibited

## Rationale

EXP22L's buffered periodic arm realized approximately 1.92--2.05% lower cost.
The practical dominance rule requires at least 1% lower cost, so the periodic
policy most favorable in RMSE is the highest-rate point on the 0.99-cost
boundary. EXP22M directly tests that unresolved boundary before robustness.

No EXP22L RMSE value is used to define EXP22M. The periodic rates use only the
same EXP22J parent communication cost already frozen for EXP22K/L:

- N5: `r_0.99 = 18.9211000 Hz`;
- N10: `r_0.99 = 10.2762000 Hz`.

Finite-horizon attempt quantization is retained and reported rather than
corrected post hoc.

## Matrix and decision

- Fresh seeds: `16054001:16054030`.
- Two cells and three arms: cost-match periodic, 0.99-cost periodic, and the
  unchanged event-driven ELCS-F candidate.
- Total: 180 trajectories.
- Same 13 integrity gates as repaired EXP22L.
- Same strict and practical epsilon rules with 10,000 paired-bootstrap
  resamples.

If the 0.99-cost arm has at most 1% worse RMSE and at least 1% lower realized
offered utilization in either cell, the candidate returns to design. A valid
survival closes only the periodic frontier development gate and permits the
robustness matrix.
