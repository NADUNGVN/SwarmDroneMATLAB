# EXP23F — ELCS-W exogenous occupancy and burst robustness

Status: frozen before fresh-seed trajectory generation on 2026-09-03.

## Question

Does ELCS-W retain terminal certificate safety and its RMSE advantage over a
lower-cost periodic reference when an exogenous transmitter occupies the
shared medium independently or in correlated 50 ms bursts?

## Frozen design

- Parent IID result:
  `results/exp23e_local_witness_iid_robustness/2026-09-03_164740`.
- Fresh seeds: `16067001:16067030`; stimulus pilot seed `16065901` is excluded.
- Cells: N5 6-DOF and N10 ring-2.
- Arms: fixed EXP23D lower-cost periodic TDMA and ELCS-W with affine clocks.
- Conditions: clean; IID 15% occupancy; two-state Markov 15% occupancy with
  mean on-burst 50 ms; and two-state Markov 30% occupancy with mean on-burst
  50 ms.
- 480 paired trajectories.
- One MAC quantum is 1 ms. For target stationary occupancy `pi` and
  `p_on_to_off=0.02`, `p_off_to_on=pi*0.02/(1-pi)`.
- No policy or candidate parameter tuning is permitted.

Both arms consume the same absolute background state sequence. Every
occupied quantum contributes to physical background busy time. For ELCS-W,
overlap of an occupied interval with a possible CLAIM, RESPONSE, fallback or
scheduled DATA interval is mapped before causal kernel execution; only
actually attempted packets affect outcomes and accounting. Affine physical
start times, not nominal slot labels, determine overlap.

## Integrity and outcome separation

Twenty integrity gates validate matrix coverage, shared random fields,
exact background busy-time equality between engines, Markov correlation,
one-hop witness coverage, control bounds, replay, variable bytes, retry
activation, cost eligibility, causality and complete retention of failures.

Safety/performance outcomes are evaluated only after integrity passes. The
candidate fails if any cell/condition has terminal certification below 100%,
any false-valid or scheduled-collision witness, any safety/divergence event,
or periodic epsilon-dominance (periodic cost at least 1% lower and RMSE no
more than 1% above ELCS-W). Paired 10,000-resample 95% intervals are reported.

A clean pass yields `ELCS_W_BACKGROUND_ROBUSTNESS_SCREEN_SURVIVES` and only
permits a later bursty link-loss/topology-dynamics study. It does not permit
method promotion, a broad robustness claim or a submission decision.
