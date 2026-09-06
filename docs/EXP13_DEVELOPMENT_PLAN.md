# EXP13 — Development baselines, ablations and sensitivity

**Status:** preregistered before the first EXP13 simulation run, then completed
without changing the matrix.  Recorded run
`results/exp13_development/2026-08-29_111747` passed 14/14 gates over 531 runs.
Results and the post-run corrective EXP13B diagnostic are documented in
`docs/EXP13_DEVELOPMENT_RESULTS.md`.  Holdout remains unopened.

## 1. Questions

EXP13 asks four separate questions.

1. Does Causal-Broadcast remain competitive against equal-budget periodic,
   state-event, ACK/AoI-only, AoCI-inspired and delayed-ACK belief frontiers?
2. Which gain or cost comes from broadcast DATA, standalone ACK, piggyback ACK
   and their hybrid, rather than from a threshold change?
3. Which of the nine trigger parameters materially changes accuracy, safety,
   confirmed freshness or airtime over the declared development box?
4. Where do contention, exogenous channel occupancy and bounded ACK history
   invalidate the benign-service interpretation of the primary cell?

All conclusions are development decisions or boundary observations.  EXP14
will use disjoint seeds and a frozen configuration.

## 2. Fixed plant and shared-medium contract

- `N=5`, double-integrator development plant, ring graph plus two leader pins;
- mission `T=12 s`, evaluation window `t>=8 s`, outer step `20 ms`;
- one fully conflicting domain, 1-ms slots, 1-Mbit/s abstract PHY;
- finite queue capacity 4, history length 32 and at most two collision retries;
- primary p-persistent CSMA access `p=1/5=0.2` from the analytical tagged
  access term, not from EXP12 empirical throughput;
- residual DATA and ACK loss uses the same declared cell value;
- all methods in a seed consume the same absolute access/loss/background trace;
- DATA frames, recipients, ACK entries, airtime and energy proxy remain
  separate quantities.

The MAC is an abstraction, not an IEEE 802.11 implementation.  Background
load is a pre-drawn one-slot external busy process, not a sixth UAV or an SINR
model.

## 3. Policy and feedback variants

The simulator accepts the following closed policy identifiers.

| Identifier | State generation rule | Physical DATA | Feedback |
|---|---|---|---|
| `periodic` | fixed period | broadcast | none |
| `state-event` | position/velocity innovation | broadcast | none |
| `causal-aoi-only` | worst confirmed age | broadcast | hybrid cumulative ACK |
| `causal-aoci` | innovation times normalized confirmed age | broadcast | hybrid cumulative ACK |
| `delayed-ack-belief` | worst expected receiver age from a bounded deterministic particle belief | broadcast | hybrid cumulative ACK |
| `causal-broadcast` | proposed new-information/refresh split | broadcast | declared standalone/piggyback/hybrid mode |
| `causal-unicast` | same proposed trigger | one DATA frame per receiver | standalone cumulative ACK |

`delayed-ack-belief` is an explicit adaptation of Tahir et al. to the
multi-receiver broadcast action space, not a reproduction of their optimizer.
Its 64 stratified particles update only from admitted actions, a declared
delivery-probability model and delayed ACK observations.  No particle reads
collision or receiver truth.

Feedback mode is a second closed enum: `none`, `standalone`, `piggyback`, or
`hybrid`.  Unsupported policy/mode combinations fail at the simulator
boundary.  Existing EXP12 calls retain their old behavior: periodic and
state-event use `none`; Causal-Broadcast defaults to `hybrid`.

## 4. Development matrices

Development seeds are `13013001:13013004`; sensitivity screening uses the
first three.  They are disjoint from EXP12 and all future EXP14 seeds.

### 4.1 Equal-budget frontiers

Six families receive exactly five evaluation points under Clean, Moderate and
Stressed residual loss `[0, 0.1, 0.3]`:

- Periodic: `[5, 10, 12.5, 20, 25] Hz`;
- State-event: common position/velocity threshold multiplier
  `[0.5, 0.75, 1, 1.5, 2]`;
- causal AoI-only: age threshold `[0.06, 0.09, 0.12, 0.18, 0.24] s`;
- AoCI-inspired: dimensionless risk threshold
  `[0.5, 0.75, 1, 1.5, 2]`;
- delayed-ACK belief: expected-age threshold
  `[0.06, 0.09, 0.12, 0.18, 0.24] s`;
- Causal-Broadcast: common position/velocity threshold multiplier
  `[0.5, 0.75, 1, 1.5, 2]`.

No single baseline point is selected after looking at a scenario.  Results are
reported as complete frontiers.

### 4.2 Mechanism ablation

At the default thresholds and `p=0.2`, compare across all three loss cells:

1. causal unicast DATA plus standalone cumulative ACK;
2. state-event broadcast DATA without ACK;
3. causal broadcast with standalone-only ACK;
4. causal broadcast with piggyback-only ACK;
5. full causal broadcast with hybrid ACK.

The unicast arm is a Study-2 shared-medium adaptation that isolates the number
of physical DATA frames.  Frozen Study-1 Causal-v3 remains a legacy reference;
the two must not be described as bit-identical implementations.

### 4.3 Parameter screening

The default point plus 12 deterministic Latin-hypercube points screen:

| Parameter | Development interval |
|---|---:|
| position threshold | 0.03--0.08 m |
| velocity threshold | 0.06--0.16 m/s |
| AoI threshold | 0.08--0.24 s |
| max silence | 0.25--0.80 s |
| hard/new-information minimum interval | 0.02--0.08 s |
| refresh minimum interval | 0.04--0.20 s |
| age scale base | 0.35--0.75 |
| minimum scale | 0.10--0.30 |
| adaptation range | 0.50--2.00 |

Screening uses Moderate loss, primary MAC and three seeds.  Time parameters are
rounded to the 20-ms control grid.  This is an LHS screening study, not a
variance decomposition or a global sensitivity proof.

### 4.4 Contention and finite-memory stress

The default Causal-Broadcast and P10 are both run under:

- CSMA `p={0.1,0.2,0.4,1.0}`;
- slotted ALOHA `p=0.2`;
- collision-free TDMA reference;
- CSMA `p=0.2` with background busy probability `{0.1,0.3}`;
- finite-history stress: history 2, ACK deadline 0.5 s and residual loss 0.3.

These are boundary arms, not alternative primary cells.

## 5. Configuration selection rule

Only the 13 Causal-Broadcast sensitivity designs are eligible.  Selection is
lexicographic and fixed before the run:

1. fewest separation failures across the three paired seeds;
2. smallest worst-seed formation RMSE;
3. among designs within 5% of that RMSE, smallest worst-seed offered airtime
   utilization;
4. lowest design index as the exact tie-break.

The selected point is then frozen as the EXP14 candidate.  It does not replace
the analytical `p=0.2`, the primary MAC cell or any baseline frontier point.

## 6. Machine gates

EXP13 passes only if:

1. EXP12 kernel/policy/end-to-end contract tests pass before the matrix;
2. every declared matrix cell and paired seed is present exactly once;
3. all plant and required age outputs are finite;
4. causal conservatism and all protocol invariants hold;
5. queue and history bounds hold in every run;
6. recipient and airtime accounting identities hold;
7. all methods in a seed use the same MAC trace realization;
8. non-feedback methods emit no ACK and every causal family obtains at least
   one confirmation in each non-collapse primary cell;
9. standalone-only has zero piggyback attempts, piggyback-only has zero
   standalone frames, and hybrid exercises both mechanisms;
10. the unicast arm generates at least as many physical DATA frames as the
    corresponding broadcast causal arm for every paired cell;
11. the LHS occupies every stratum exactly once in every parameter dimension;
12. background occupancy is inert at zero and exercised in both nonzero arms;
13. finite-history stress reaches either expired-ACK or stale-ACK handling
    without violating causality;
14. the selected configuration follows the declared lexicographic rule.

Passing these gates permits freezing an EXP14 candidate only.  It does not
permit a paper-level method-performance claim.
