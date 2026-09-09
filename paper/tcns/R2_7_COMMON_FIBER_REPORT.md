# R2.7 common multi-action fiber closure report

**Protocol commit:** `55340bff657d8881482810b9ca457d736951c0b5`

**Authoritative run:**
`results/tcns_r2_7_common_fiber/2026-09-09_121641/`

**Frozen scientific parent:** `7376fb097ca6c25fe0758dcb4c89f69c66a66003`

**Result commit:** reported in the coauthor handoff; not pushed.

## Scope and deterministic state source

The audit reads only
`results/tcns_r2_generalization_validation/2026-09-08_161130/workspace.mat`.
It exhaustively replays the ten previously persisted N=5 R2 `uCenter`
coordinates, in catalog order, for senders 1, 3, and 4. This produces 30
predeclared sender/center attempts. All ten physical centers and all 30
sender/center attempts are eligible; none is excluded. No new stochastic
closed-loop trajectory, seed, topology, gain, scheduler, or observation model
is generated.

The common action families include the genuine no-transmission action first:

- sender 1: `[0, ordinary_1_to_2, ordinary_1_to_5,
  pinned_leader_1_to_2, pinned_leader_1_to_4]`;
- sender 3: `[0, ordinary_3_to_2, ordinary_3_to_4]`;
- sender 4: `[0, ordinary_4_to_3, ordinary_4_to_5]`.

Every communication action is constructed from the same terminal physical
state and receiver memories. Every endpoint is independently replayed for all
actions, not one state per action.

## Common-fiber dimensions

The dimension tuple below is
`(reachable, sender-information nullity, joint-response, K_common)`. It is the
same at every one of the ten persisted centers for the given sender:

| Sender | Dimension tuple | Certified radius range |
|---:|---|---:|
| 1 | `(24,24,24,24)` | `0.0029882240772093`--`0.00576342094068266` |
| 3 | `(24,6,6,6)` | `0.00602310713083089`--`0.0090703481929314` |
| 4 | `(24,6,6,6)` | `0.0031707720929204`--`0.00644854879393177` |

Thus no attempted common fiber is zero-dimensional. Jointly preserving all
candidate responses and target/payload semantics removes no further direction
beyond the complete sender-history equality in this frozen construction. This
is a measured property of these matrices, not a general theorem.

The complete per-attempt ranks and radii are in
`common_fiber_dimensions.csv`. The maximum explicit/centered-difference action
response-Jacobian residual is `1.35205858767856e-15`; the exact command-map
residual is zero.

## Direct set-valued argmax outcomes

Outcome counts are A/B/C/D = `24/6/0/0`. The following table reports every
attempt; `A` means `COMMON_FIBER_ARGMAX_AMBIGUOUS`, and `B` means
`COMMON_FIBER_WINNER_CERTIFIED`.

| Frozen center source | Sender 1 | Sender 3 | Sender 4 |
|---|---:|---:|---:|
| `ordinary_1_to_2` | A | A | A |
| `ordinary_1_to_5` | A | A | A |
| `ordinary_2_to_3` | B | A | A |
| `ordinary_3_to_2` | B | A | A |
| `ordinary_3_to_4` | B | A | A |
| `ordinary_4_to_3` | B | A | A |
| `ordinary_4_to_5` | B | A | A |
| `ordinary_5_to_4` | B | A | A |
| `pinned_leader_1_to_2` | A | A | A |
| `pinned_leader_1_to_4` | A | A | A |

Each A row has two independently replayed endpoints whose tolerance-aware
argmax sets are disjoint. The smallest positive unique-winner margin among all
A endpoints is `1.2069057306442031e-7`, more than 1200 times the predeclared
`1e-10` decision tolerance. A representative sender-1 pair is

```
q_left  = [0,
           -1.9538688111277999e-4,
           -1.6311549592179338e-4,
           -1.6278641009033164e-4,
           -2.0005518230769095e-4],  A*(left)  = {0}

q_right = [0,
            1.9723552995688939e-4,
            7.7516277640320979e-5,
            1.6439893246772611e-4,
            1.6465374220610849e-4],  A*(right) = {1}
```

The complete q-vectors, full argmax sets, intersections, and margins for all
24 claimed endpoint pairs are persisted without rounding in
`common_fiber_argmax.csv`; action-wise copies and residuals are in
`common_fiber_replay.csv`.

The six B rows are exact flat ties, not tolerance-selected near-ties: for each,
`q_aug=[0,0,0,0,0]` and the restricted affine gradient is exactly zero, so
`A*(x)={0,1,2,3,4}` throughout the certified common fiber. Relative values do
not vary in these six cases. They therefore certify a common action while
preserving ties, but they are not an empirical example of a common winner with
nonidentifiable relative values.

## Independent replay and controls

All 330 action/endpoint replay rows pass. The maximum residuals over claimed
endpoint pairs are:

| Check | Maximum |
|---|---:|
| complete sender history | `2.6020852139652106e-18` |
| joint candidate responses | `3.4694469519536142e-18` |
| dynamic/reachability replay | `7.91033905045424e-16` |
| affine/direct-oracle value | `7.37257477290143e-18` |
| frozen-center physical-state reconstruction | `3.33066907387547e-16` |

Action identities, targets, payloads, topology, pinning, H, D, and the
unsaturated controller branch agree at every claimed pair. Deliberate
corruption of (i) sender information, (ii) one candidate response, and (iii)
reachability/dynamics is rejected by the validator.

`tests/test_tcns_r2_7_common_fiber.m` passes all joint-response, negative-
control, q0, set-valued tie, disjoint-argmax, and common-winner checks. It also
runs the approved R2.6 suite, which remains `6/6` base cases plus `4/4`
rank-gap refinements PASS.

## Claim boundary

The 24 A outcomes instantiate Theorem 3 on physically common, jointly
fixed-response, at-most-one N=5 fibers. They do not turn the R2.6 `360/360`
rank reductions into `360/360` argmax ambiguities, do not establish an
arbitrary-topology result, and do not propose a scheduler. The authoritative
manuscript was not edited in R2.7.
