# R2 generalization and actual-action witness protocol

**Protocol date:** 2026-09-08  
**Parent evidence:** accepted SQ commit
`9d9212e134c9e2cae3bbdb0f79d918d3560e5359`  
**Study class:** new TCNS theory/generalization study; not simulation-v1 and not
a held-out policy experiment.

This protocol is frozen before inspecting R2 rank or witness outcomes. It
tests recurrence and physical relevance of the existing information-structure
mechanism. It does not introduce a scheduler or a new generic observability
claim.

## 1. Deterministic network registry

The complete Cartesian registry is:

- swarm size `N = [5 7 9]`;
- graph `ring2`, `sparse4`, and `geometric`, using the existing deterministic
  `applyTopologyConfig` registry;
- pin set `even`: every even-indexed follower is pinned;
- pin set `odd`: every odd-indexed follower from UAV 3 onward is pinned;
- finite-horizon output `H = [15 25]` samples;
- action delay `D = [2 4]` samples.

Consensus degree normalization remains disabled and gains remain
`Kp=1.8`, `Kv=2.2`, `KpLeader=1.5`, `KvLeader=1.8`. Each graph/pin pair must
pass the same symmetric-grounded, positive-definite and Schur scope check used
by `tcnsInformationLimitsModel`. An inadmissible predefined cell is retained
with an explicit failure record; it is not replaced after results are viewed.

The graph registry varies density and geometry while remaining deterministic.
The two D values are required because D changes the candidate response kernel
independently of H. No stochastic channel trajectory or held-out seed is used.

## 2. Structural audit quantities

For every controller-relevant ordinary and pinned-leader action, construct the
same structural x-axis unit command correction `[1 0 0]` used in R1. Report it
only as a structural functional.

For fixed-payload finite-history identifiability, the target receiver-memory
coordinates are conditioned and the complete held-memory history has length
`n_free-1`. The full-state equivalent is checked by stacking the target
coordinate selector with the sender history. Report:

- conditioned history rank and nullity;
- normalized hidden-coefficient residual;
- identifiable/nonidentifiable;
- rank increase after appending the value row;
- tolerance-grid stability.

The declared relative tolerance grid is
`[1e-6 1e-8 1e-10 1e-12 1e-14]`, with `1e-10` as reference. A compressed
null-space calculation and an independent direct row-space calculation must
agree at the reference tolerance.

For every sender, stack its full-state current structural action-value rows and
report `p_j`, `r_j*`, `r_j*/p_j`, singular values of the missing projection,
minimum owning coalition, and whether the full coalition identifies all rows.
Coalitions are exhaustively enumerated for N <= 9 and must include the sender.

High-precision arithmetic is not used as a favorable-outcome filter. An
80-digit row-basis projection is attempted for the minimum-residual action in
every graph/pin/N/H/D cell and for every action whose double residual is below
`1e-6`. Every row records whether VPA was attempted and any failure.

## 3. N=5 actual-action witness audit

The active catalog is exactly the ten existing controller-relevant actions at
the accepted N=5 ring/even-pin configuration, H=25 and D=4. No action may be
dropped.

Each actual-action witness uses a deterministic, admissible no-update history:

1. receiver memories are initialized consistently at time zero;
2. no DATA update occurs before the decision, so those memories are held;
3. a common source excitation is chosen before the hidden perturbation;
4. the candidate correction at the decision is recomputed from the actual
   controller residual, never set to `[1 0 0]`;
5. target-memory constancy, complete sender-history equality, and identical
   candidate response are enforced as linear constraints on consistent initial
   perturbations;
6. a value-sensitive direction is the projection of the actual action-value
   gradient into that constrained null space;
7. two symmetric perturbations of size `1e-4` are placed around the exact
   affine zero crossing;
8. both histories are replayed through `distributedFormationPolicy` and
   `integrateFollowers`, and their action values are independently checked
   against `tcnsCentralizedStateOracleValue`.

The common source excitation targets a 0.01 m/s^2 x-axis candidate correction.
Leader actions use constant leader velocity as in the accepted witnesses.
Follower actions use whichever of a source's initial position or scaled
velocity coordinate has the larger deterministic transfer to the final
controller correction. No target escalation or result-dependent restart is
allowed.

Acceptance tolerances are:

- sender-observation mismatch <= `1e-9`;
- affine/dynamic reachability residual <= `1e-9`;
- action-response mismatch <= `1e-9`;
- affine-versus-independent-oracle value residual <= `1e-9`;
- saturation margin > `1e-6` m/s^2;
- strict signs `qMinus < -1e-12` and `qPlus > 1e-12`.

Every failure is retained using exactly one primary reason:

`NONE`, `NO_NULL_DIRECTION`, `REACHABILITY_INFEASIBLE`,
`NO_SIGN_CROSSING_FOUND`, `SATURATION_VIOLATION`, or `NUMERICAL_FAILURE`.

## 4. Practical-scale diagnostics

For every successful witness report midpoint, information radius, and
deterministic/randomized endpoint regret. Normalize the radius using the
median absolute centralized value for the same link over 32 deterministic
reference initial conditions. Reference perturbations use seed 27022001 only
to generate a reproducible analysis grid; this is not a population sample.

For the same reference grid, report descriptively:

- the fraction of unsaturated reference states whose local compatible interval
  of initial-coordinate radius `1e-4` crosses zero;
- the disagreement fraction between the centralized exact sign and the
  orthogonal sender-row-space projection sign.

These are deterministic diagnostics of the selected operating neighborhood,
not population probabilities and not a proposed local scheduling policy.

## 5. Outputs and stop rules

The driver `experiments/tcns_r2_generalization_validation.m` must write CSV,
MAT, JSON, configuration registry, and console metadata. The separate
actual-witness table must list all ten actions including failures.

Stop manuscript strengthening and report rather than code around the result if:

- the predefined graphs cannot satisfy the model's theorem scope in enough
  cells to constitute a cross-instance study;
- the full coalition fails because the declared agent information maps do not
  cover a target row;
- direct replay contradicts the affine construction;
- structural/action catalogs lose entries silently;
- successful witnesses depend on violating saturation or the stated numerical
  tolerances.
