# EXP23D — ELCS-W sharp measured-cost periodic frontier

Status: frozen before fresh-seed trajectory generation on 2026-09-03.

## Question

Can a guarded static periodic TDMA reference reduce measured total offered
airtime by at least 1% relative to ELCS-W while keeping mean formation RMSE
within 1% of ELCS-W in either frozen cell?

This is a direct falsification test. If such a periodic reference exists,
ELCS-W returns to design even if all protocol-integration checks pass.

## Parent evidence and cost calibration

The parent is the valid EXP23C run
`results/exp23c_local_witness_closed_loop_integration/2026-09-03_161908`.
Its affine-clock mean total offered utilization is:

- N5 6-DOF: `0.290453333333331`;
- N10 ring-2: `0.309759999999997`.

The analytic cost-match rate is `parentCost/(N*D)`, where
`D = 8*96/250000` s. Because the 12 s horizon admits an integer number of
completed transmissions, multiplying this rate by 0.99 does not necessarily
produce a measured 1% cost decrease. Cost-only pilot seeds
`16059801:16059810`, disjoint from EXP23D, were used to select the largest
retained tested factors satisfying the measured-airtime constraint without
using pilot RMSE:

- N5 rate factor: `0.9875`;
- N10 rate factor: `0.9866`.

This correction favors the periodic reference: it places it as close as the
finite-horizon cost plateau permits to the required lower-cost side.

## Frozen matrix

- Fresh seeds: `16061001:16061030`.
- Cells: N5 6-DOF zero-loss and N10 ring-2 zero-loss.
- Arms: periodic cost-match, periodic measured-cost-at-least-1%-lower, and
  ELCS-W with bounded affine clocks.
- 180 trajectories, paired by seed and cell.
- Same 96-byte DATA, 250 kbit/s PHY, mission-horizon guard and 12 s horizon.
- ELCS-W management reach is exactly the one-hop neighbor graph.
- No parameter or policy tuning is permitted.

## Dominance rule

For periodic reference `P` and ELCS-W candidate `E`, periodic epsilon-
dominance is declared in a cell when both point estimates satisfy

`mean(RMSE_P) <= 1.01 mean(RMSE_E)`

and

`mean(Cost_P) <= 0.99 mean(Cost_E)`.

Strict dominance retains the pre-registered 1% margins in both metrics. A
separate paired 10,000-resample bootstrap flag reports whether both epsilon
inequalities are also supported by the one-sided limits of the two-sided 95%
paired intervals. Point-estimate epsilon-dominance is the conservative kill
rule; confidence support is reported but is not needed to kill the candidate.

## Integrity gates and decision

All 15 integrity gates must pass, including exact matrix/trace pairing,
frozen rates, collision-free periodic timing, one-hop witness coverage,
ELCS-W certification and replay safety, variable-byte airtime closure, and
direct verification that the lower periodic arm actually achieves at least
1% lower measured cost on fresh seeds.

- Failed integrity gate: `ELCS_W_FRONTIER_STUDY_INVALID`.
- Any lower-cost periodic epsilon-dominance:
  `ELCS_W_EPSILON_DOMINATED_RETURN_TO_DESIGN`.
- Otherwise: `ELCS_W_SHARP_PERIODIC_FRONTIER_SURVIVES`, permitting the next
  loss/load robustness study but not method promotion or a submission claim.
