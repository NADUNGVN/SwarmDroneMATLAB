# EXP14D — Factorial closure of MAC-aware causal communication

## 1. Status and separation

EXP14D is a new development study motivated by the unresolved EXP14C
confound. It does not alter or append rows to EXP14A/B/C. Its seeds
`16017001:16017012` are disjoint from all earlier Study-2 seed blocks.
Performance is not inspected until this document, the registry, factor mapping,
integrity gates and selection rule are executable.

The study is exploratory mechanism attribution. It cannot support a
confirmatory claim and cannot reopen any EXP14 conclusion. EXP15 remains
reserved for trace/radio/HIL validation.

## 2. Question

Under a shared multi-slot medium, which part of the three-factor controller
causes the N20 safety loss observed in EXP14C relative to access scaling alone?

The factors are:

- `A`: feedback mode, frozen hybrid (`0`) or local-busy adaptive ACK (`1`);
- `G`: branch-aware load guard disabled (`0`) or enabled (`1`);
- `S`: configured access retained (`0`) or scaled to
  `min(p_configured,1/N)` (`1`).

All eight `A × G × S` combinations are required. In particular, EXP14D adds
the missing `A=1,G=0,S=1` arm needed to separate adaptive ACK from the load
guard under scaled access.

## 3. Additive public contract

Existing method values and feedback semantics remain unchanged. A new method
value `load-guarded-broadcast` applies the same causal state trigger and the
same local-busy branch guard as `mac-aware-broadcast`, but requires frozen
`feedbackMode=hybrid`. It exists only to expose the `A=0,G=1` factorial cells
without weakening the existing fail-fast pairing:

- `causal-broadcast` rejects adaptive feedback and never applies the guard;
- `mac-aware-broadcast` requires adaptive feedback;
- `load-guarded-broadcast` requires hybrid feedback and an enabled guard;
- `causal-unicast` remains standalone-only.

Access scaling remains an explicit configuration factor. No method may read
collision outcomes, receiver truth, future arrivals or delivery success when
making a load/ACK decision.

## 4. Fixed matrix

Twelve seeds are crossed with four fixed Moderate Gilbert--Elliott cells:

1. N5 ring2, fully sensed CSMA, 6-DOF;
2. N5 ring2, slotted ALOHA, 6-DOF;
3. N10 ring2, fully sensed CSMA, double integrator;
4. N20 ring2, fully sensed CSMA, double integrator.

Every seed/cell uses one absolute plant, channel-state and MAC-uniform trace
across the eight factor combinations. The matrix contains
`12 × 4 × 8 = 384` runs.

For N5, configured access is already `0.2=1/N`. Therefore paired `S=0/S=1`
arms with identical `A,G` must be bit-identical. This is a negative-control
integrity gate, not a performance result.

All EXP14C thresholds are frozen. EXP14D does not tune the busy EWMA, ACK
delays, busy ceilings, queue threshold or trigger thresholds.

## 5. Registered estimands

For RMSE, mean true AoI, offered utilization, channel utilization, collision
frames, DATA attempts and ACK attempts, estimate the seven complete-factorial
effects `A`, `G`, `S`, `A×G`, `A×S`, `G×S`, and `A×G×S` separately in each
cell. Each effect is first computed within seed from the eight CRN arms, then
summarized with its mean and paired-t 95% development interval.

Safety is reported as raw failures for every cell/arm and as paired improved,
worsened and unchanged seed counts. Binary safety is not passed through a
t interval.

## 6. Integrity gates

The run is valid only if:

- all 384 declared keys occur once and all continuous outputs are finite;
- all arms in a seed/cell share absolute trace and channel-state hashes;
- causal conservatism, bounded memory and three-way terminal accounting hold;
- factor metadata contains the complete binary cube exactly once per
  seed/cell;
- adaptive decisions occur only for `A=1`, guard blocks only for `G=1`, and
  scaled access is applied only for `S=1` when it changes `p`;
- every N5 `S` negative-control pair is bit-identical for all logged physical,
  control, traffic and protocol outputs other than declared metadata;
- local busy estimates remain in `[0,1]`; divergences remain explicit safety
  outcomes rather than integrity failures.

## 7. Frozen candidate rule

Candidate selection is deterministic and uses only arm summaries:

1. eligible arms have zero observed safety failures in all four cells and N20
   mean offered utilization below `1.2`;
2. for every eligible arm, compute its worst cell-wise RMSE regret relative to
   the lowest-RMSE eligible arm in that cell;
3. retain arms within one percentage point of the smallest worst RMSE regret;
4. among them, minimize worst cell-wise offered-utilization regret relative to
   the lowest-load eligible arm in that cell;
5. values within one percentage point are tied and resolved by the registry
   order.

If no arm is eligible, the design is closed. Otherwise the selected arm may be
frozen in a new preregistration, but EXP14D itself still permits no
confirmatory claim.

## 8. Interpretation constraints

- A main effect is an average over the other two factors, not a claim that the
  factor has the same effect in every regime.
- Factor interactions and all intervals are exploratory at 12 seeds and are
  reported without multiplicity-adjusted confirmatory language.
- Offered utilization may exceed one because it is pre-contention demand;
  channel utilization remains a busy-time union bounded by one.
- Even a selected arm remains validated only in the abstract simulator until
  EXP15 trace/radio/HIL evidence exists.

