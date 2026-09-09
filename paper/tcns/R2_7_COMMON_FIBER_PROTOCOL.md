# R2.7 common multi-action fiber protocol

**Protocol status:** frozen before any R2.7 argmax evaluation  
**Repository/branch:** `NADUNGVN/SwarmDroneMATLAB`, `paper-v3-tcns`  
**Scientific parent:** `7376fb097ca6c25fe0758dcb4c89f69c66a66003`  
**Scope:** deterministic post-processing and replay of already persisted N=5
states only. No trajectory generation, stochastic search, new seed, registry
extension, scheduler, protocol, or noisy-observation model is authorized.

## 1. Frozen instance and action families

The only plant instance is the persisted N=5 `ring2/even` case in
`results/tcns_r2_generalization_validation/2026-09-08_161130/workspace.mat`,
with its stored `cfg`, H=25, D=4, controller, topology, pinning, integrator,
payload semantics, and unsaturated branch. The only senders with at least two
communication actions are enumerated in the fixed order `[1,3,4]`:

- sender 1: `ordinary_1_to_2`, `ordinary_1_to_5`,
  `pinned_leader_1_to_2`, `pinned_leader_1_to_4`;
- sender 3: `ordinary_3_to_2`, `ordinary_3_to_4`;
- sender 4: `ordinary_4_to_3`, `ordinary_4_to_5`.

Every audit uses the at-most-one family
`A_aug={q0=0,q1,...,qp}`. The communication-action order is the persisted
catalog order; action 0 is prepended. Ties are retained as sets. No
single-valued tie-breaking rule is used.

## 2. Eligible persisted physical states

The sole eligible state source is the same frozen R2 workspace above. Its ten
`witness.details{a}.uCenter` coordinates, associated leader velocity, history
length, and `cfg` are sufficient to reconstruct a complete dynamically
reachable physical trajectory and receiver-memory state using
`tcnsInformationLimitsReplayWitness`. They were frozen once per catalog action
before R2.7; their R2 binary outcome is not used to select a center.

The O1 action CSV and aggregate artifacts are ineligible because they do not
persist the complete receiver-memory/history state needed to replay every
candidate action at one common physical state. The earlier IL synthetic
witnesses and R2.5 replay summaries are also ineligible because they do not add
a distinct complete common-state source.

A persisted R2 center is eligible exactly when, before any R2.7 argmax test:

1. its catalog row, detail object, `uCenter`, leader velocity, and history
   length are present and finite;
2. the frozen R2 row says `reachableWitnessFound=true` and
   `failureReason="NONE"`;
3. direct no-update replay reconstructs the stored terminal physical state,
   complete sender history, and unsaturated branch within the tolerances below;
4. all actions of the audited sender exist in the frozen catalog and can be
   evaluated at that same replayed terminal state.

Failure of any condition produces an explicit excluded row and reason. No
duplicate center is removed and no center is excluded because of its values,
winner, margin, or common-fiber dimension.

## 3. Deterministic enumeration rule

Read catalog rows 1 through 10 in their persisted order. For every eligible
center, audit senders 1, 3, and 4 in that order. Thus the predeclared maximum is
30 sender/center attempts. Candidate actions follow persisted catalog order.
No random number is drawn. Outcome tables retain all eligible and excluded
attempts.

## 4. Common perturbation construction

Let `J` be the persisted implementation-faithful consistent-initialization map
and let `F0=A_hold^L J` map its coordinates to the terminal augmented state.
For a sender, stack its complete history as `C_hist J`. Starting from the
reachable coordinate space, report successively:

1. `reachableDimension = rank(J)`;
2. `senderInformationNullity = nullity(C_hist J)`;
3. `jointResponseDimension`, the nullity after also stacking the affine
   Jacobians of **every** candidate action response;
4. `commonDimension`, the nullity after also preserving every candidate target
   value/payload coordinate and action identity.

The last null space is `K_common`. The response Jacobians are built explicitly
on the retained affine branch and independently checked by centered finite
differences of implementation replay. Equivalently, for every retained
direction `v`, every candidate must satisfy
`g_a(x0+v)=g_a(x0)`. A zero dimension is retained as outcome C, never filtered.

At every reported endpoint, replay reconstructs the physical history once and
evaluates all sender actions jointly. It must confirm identical complete
sender history, candidate identities, target semantics, payloads, and all
fixed responses across endpoints. A change in even one response invalidates
the common-fiber claim.

## 5. Branch-valid bounded fiber

For nonzero `K_common`, use orthonormal coordinate basis `K` and the centered
ball `u=u0+Kz`, `||z||_2<=rho`. The radius is not selected from an argmax
outcome. Replay at the center and at signed unit coordinate perturbations
constructs and verifies the affine unsaturated-command maps
`c_{k,i}+A_{k,i}z` for every history time and UAV. The predeclared conservative
branch certificate is

`rho = min_{k,i} (maxAccel-saturationMarginTolerance-||c_{k,i}||_2)
                  / ||A_{k,i}||_2`,

over nonzero `A_{k,i}`; constant rows must already satisfy the margin. This is
the largest radius certified by this declared triangle-inequality bound, not
an outcome-tuned radius. A nonpositive or nonfinite admissible radius is
reported explicitly and cannot support A or B.

## 6. Affine values and deterministic decision test

At the same center and for every action, construct the fixed-response affine
value in `K` coordinates and compare it with direct finite-horizon centralized
oracle recomputation. Prepend `(q0,g0)=(0,0)`. Report the maximum mismatch.

For each candidate action `a`, solve the deterministic second-order-cone
problem that maximizes its minimum pairwise margin over `||z||<=rho`. Candidate
actions and action pairs are inspected lexicographically. Each optimizer point
is evidence only after independent implementation replay. Two replayed points
whose tolerance-aware argmax sets are disjoint establish outcome A; unique
winners with margins above the decision tolerance are preferred.

Independently, apply the closed-form common-winner test on the entire ball:

`m_ab = q_a(u0)-q_b(u0)-rho*||(gradient_a-gradient_b)K||_2`.

If an action has all lower margins nonnegative within tolerance, outcome B is
reported. If no action does, the common-maximizer intersection on the declared
ball is empty; outcome A is permitted only when the ball and all replay checks
are certified. Optimization failure or insufficient persisted information is
outcome D, not evidence for A or B. Relative-value variation is reported
separately and never equated with argmax ambiguity.

## 7. Tolerances and boundary policy

The tolerances are frozen before outcome inspection:

| Check | Tolerance |
|---|---:|
| numerical rank/null space, relative | `1e-10` |
| complete sender history, infinity norm | `1e-9` |
| reachability/affine trajectory, infinity norm | `1e-9` |
| each action response, target and payload, infinity norm | `1e-9` |
| affine versus direct-oracle value | `1e-9` |
| unsaturated-branch margin | `1e-6` m/s^2 |
| decision/argmax comparison | `1e-10` value units |
| affine-Jacobian centered-difference check | `1e-9` |

An action belongs to an argmax set when it is within `1e-10` of the maximum.
A unique winner or disjointness claim requires its relevant positive margin to
exceed `1e-10`. A margin with absolute value at most `100*1e-10` is marked
`NUMERICALLY_UNRESOLVED` unless a higher-precision linear-algebra check resolves
it; it is never promoted by machine-epsilon optimism.

## 8. Independent replay and negative controls

Every claimed endpoint pair is independently replayed and records:

- complete sender-history mismatch;
- dynamic/reachability residual;
- per-action correction, payload/target, and fixed-response mismatch;
- per-action affine/oracle mismatch;
- minimum saturation margin and branch identity;
- complete augmented q-vector, tolerance-aware argmax set, and winner margin.

The deterministic tests must also corrupt, one at a time, (i) sender
information, (ii) one candidate response, and (iii) reachability/dynamics. The
validator must reject all three. These controls are test-contract checks and
are not added to the scientific candidate enumeration.

## 9. Predeclared outcomes and persisted outputs

Each attempted sender/center receives exactly one label:

- `COMMON_FIBER_ARGMAX_AMBIGUOUS` (A);
- `COMMON_FIBER_WINNER_CERTIFIED` (B);
- `COMMON_FIBER_ZERO_DIMENSION` (C);
- `COMMON_FIBER_NOT_CERTIFIABLE` (D).

The run must persist `common_fiber_candidates.csv`,
`common_fiber_dimensions.csv`, `common_fiber_argmax.csv`,
`common_fiber_replay.csv`, `summary.json`, and `workspace.mat` under one
timestamped `results/tcns_r2_7_common_fiber/` directory. Every attempted
sender/center and every exclusion reason remains machine-readable.

This protocol authorizes no manuscript edit. In particular, the R2.6
`360/360` relative-rank reductions are not treated as `360/360` argmax
ambiguities.
