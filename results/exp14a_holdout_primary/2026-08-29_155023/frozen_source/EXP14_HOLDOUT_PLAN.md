# EXP14 — Frozen holdout for Causal-Broadcast on a time-varying shared medium

**Status at freeze:** preregistered and executable before the first EXP14 seed
was consumed.  Registry version `EXP14-FROZEN-v1`; registry hash `201658753`
over 139 leaves.  Holdout seeds are `14014001:14014100` and may not be used to
modify a policy, baseline, channel cell, metric, contrast or exclusion rule.

The executable registry is `utils/exp14Registry.m`; primary and OOD builders
are `configs/study2Exp14Config.m` and `utils/applyExp14OODPoint.m`.  The runners
are `experiments/exp14a_holdout_primary.m` and
`experiments/exp14b_holdout_ood.m`.

## 1. Scientific question and scope

EXP14 asks whether receiver-confirmed semantic triggering remains useful when
DATA is genuinely broadcast, DATA and ACK share a finite multi-slot medium,
and link errors occur in bursts.  It does **not** assume that Causal-Broadcast
must win.  Clean-regime domination, loss of a Pareto point, feedback overhead,
straggler domination, congestion collapse and OOD failure are all reportable
outcomes, not grounds for changing the design.

This remains an abstract discrete-event MAC study.  The PHY rate, frame size,
Gilbert--Elliott probabilities, energy proxy and carrier graphs are declared
simulation parameters, not hardware measurements or IEEE 802.11 emulation.
Trace replay and radio/HIL calibration remain EXP15.

## 2. Freeze and separation from development

- 100 unique holdout seeds: `14014001:14014100`;
- EXP13 development seeds: `13013001:13013004`;
- Study-1 final seeds: `25000001:25000050`;
- no sequential stopping and no added seeds after inspecting an interval;
- all policy parameters are the EXP13-selected default design 0;
- access probability remains the analytical `p=1/5=0.2`;
- the full baseline frontiers are retained; no best baseline is chosen per
  scenario or per seed.

Before opening the holdout, `test_exp14_infrastructure` must reproduce the
registry hash, exact primary configuration hashes and all matrix counts.  The
three seed-zero primary hashes are Clean `103822268`, Moderate `103613168` and
Stressed `101886664`, each over 102 leaves.  Each run directory snapshots the
frozen registry and source files because the working tree may be dirty.

## 3. Primary plant and shared-medium contract

- `N=5`, ring2 information topology, two follower leader pins;
- 6-DOF follower plants, outer step 20 ms, inner/outer ratio 10;
- mission 12 s and evaluation window `t>=8 s`;
- p-persistent CSMA, 1-ms slots, fully connected carrier-sense and
  interference domains;
- 96-byte DATA, 16-byte ACK base, 8 bytes per cumulative ACK entry and
  250-kbit/s abstract PHY;
- bare DATA therefore occupies four slots; ACK duration depends on its merged
  entry count;
- finite per-node queue 4, history 32, two collision retries and a 20-ms ACK
  deadline;
- hybrid cumulative ACK is the proposed default;
- offered DATA airtime, standalone ACK airtime, piggyback overhead, busy-time
  union and the transmit-energy proxy remain distinct quantities.

`interferenceMatrix(receiver, transmitter)` and
`carrierSenseMatrix(node, transmitter)` are separate.  The primary cell sets
both to all true.  This separation is necessary for the hidden-terminal OOD
cell and is additive: the all-true carrier-sense default reproduces EXP12/13.

## 4. Time-varying DATA and ACK channel

Each directed DATA link and each standalone-ACK link is an independently
initialized stationary two-state Gilbert--Elliott chain on the absolute 1-ms
slot grid.  Primary DATA and ACK have equal marginals but independent draws and
states.  A piggybacked ACK entry experiences its enclosing DATA frame, not the
standalone reverse channel.  Policy actions never advance an RNG or state
machine.

| Cell | Good loss | Bad loss | Good→bad | Bad→good | Stationary bad | Mean bad duration | Mean loss |
|---|---:|---:|---:|---:|---:|---:|---:|
| Clean | 0.00 | 0.20 | 0.001 | 0.039 | 0.025 | 25.64 ms | 0.005 |
| Moderate | 0.03 | 0.70 | 0.004 | 0.036 | 0.100 | 27.78 ms | 0.097 |
| Stressed | 0.05 | 0.85 | 0.009 | 0.021 | 0.300 | 47.62 ms | 0.290 |

The chain is independent across directed links; spatially correlated fading is
outside this experiment.  The underlying uniforms are common across channel
cells at a seed.  Within a seed/scenario, every policy consumes the exact same
absolute trace and precomputed channel-state realization.

## 5. EXP14A primary matrix

### 5.1 Equal-budget frontiers

All six families receive five fixed points in all three channel cells and all
100 seeds:

| Family | Points |
|---|---|
| Periodic broadcast | `[5, 10, 12.5, 20, 25]` Hz |
| State-event broadcast | threshold multiplier `[0.5, 0.75, 1, 1.5, 2]` |
| Causal AoI-only | confirmed-age threshold `[0.06, 0.09, 0.12, 0.18, 0.24]` s |
| AoCI-inspired | risk threshold `[0.5, 0.75, 1, 1.5, 2]` |
| Delayed-ACK belief | expected-age threshold `[0.06, 0.09, 0.12, 0.18, 0.24]` s |
| Causal-Broadcast | state-threshold multiplier `[0.5, 0.75, 1, 1.5, 2]` |

This is `100 × 3 × 6 × 5 = 9000` runs.

### 5.2 Mechanism matrix

At default thresholds, every seed and channel cell additionally runs:

1. causal unicast DATA plus standalone cumulative ACK;
2. state-event broadcast DATA without ACK;
3. causal broadcast with standalone-only ACK;
4. causal broadcast with piggyback-only ACK;
5. causal broadcast with hybrid ACK.

This is `100 × 3 × 5 = 1500` runs.  EXP14A therefore contains 10,500 runs.

## 6. EXP14B secondary/OOD matrix

OOD points use the Moderate channel and fixed, non-retuned methods.  N=5 cells
retain 6-DOF; N=10/20 scalability cells use the double integrator so plant
fidelity is not confounded with swarm size.

1. N10 ring2;
2. N20 ring2;
3. N10 sparse4;
4. N5 with external busy probability 0.30;
5. N5 hidden terminals: physical interference remains global while a sender
   senses only itself and its two ring neighbours;
6. N5 reverse asymmetry: DATA remains Moderate; standalone ACK uses good/bad
   loss 0.15/0.95 and transitions 0.008/0.022, giving mean reverse loss
   0.3633;
7. N5 C3 synthetic estimator: 30-mm position noise, 0.05-m/s velocity noise
   and 50-ms latency;
8. N5 slotted ALOHA at `p=0.2`.

Each point runs Periodic-P10, Periodic-P20, default state-event, default
delayed-ACK belief, Causal-Broadcast hybrid and Causal-Broadcast
piggyback-only.  This is `100 × 8 × 6 = 4800` runs.  Fixed OOD points test
robustness; they are not substitutes for the complete primary frontiers.

## 7. Outcomes and inference

The seed is the independent experimental unit.  CRN comparisons are paired by
seed; a policy is never paired to a different channel trace.

Primary outcomes are formation RMSE, safety failure count, offered airtime
utilization and mean/p95/p99 true AoI.  Secondary outcomes include estimated
AoI and its conservative gap, DATA/ACK frames and recipient outcomes,
collision/retry/queue counts, access and confirmation delay, channel-state
occupancy, Jain goodput, attitude/saturation/control effort and the declared
transmit-energy proxy.

The complete mean RMSE--offered-airtime frontier is reported in every primary
cell.  Exact weak Pareto membership is the main descriptive frontier rule
among zero-divergence, zero-safety-failure points.  To expose dependence on an
arbitrary tolerance, dominance is also reported at margins 0.5%, 1% and 2%; a
margin cannot be chosen after inspection.

Continuous paired contrasts report mean difference, standard deviation and a
two-sided 95% paired-t interval.  A deterministic 10,000-resample paired
percentile bootstrap (seed `14141414`) is a sensitivity interval, with its
resampling unit and replicate count stated in the paper.  Safety proportions
report raw numerator/denominator and Wilson 95% intervals; they are not passed
through a t interval.  No run is discarded silently.  Divergence is a
stability and safety failure and removes that seed only from continuous paired
differences, with requested/usable/dropped counts exposed.

The five named contrasts, reported regardless of sign, are:

1. Clean proposed default minus Periodic-P10;
2. Stressed proposed default minus Periodic-P10;
3. Stressed proposed default minus delayed-belief default;
4. Moderate hybrid broadcast minus causal unicast;
5. Moderate piggyback-only minus hybrid broadcast.

No performance outcome is a machine pass gate.  Thus an unfavorable Clean
contrast or the absence of a proposed Pareto point cannot make the experiment
“fail” and cannot trigger retuning.

## 8. Integrity gates

EXP14A/B may be interpreted only when their machine gates pass:

- exact matrix size and one row per declared cell;
- finite required outputs and explicit divergence count;
- zero causal/protocol invariant violations;
- bounded queue and history;
- closed DATA and ACK recipient accounting and valid busy-time union;
- one underlying trace per paired seed/cell and one channel-state realization
  per paired seed/scenario;
- no ACK from no-feedback methods and correct standalone/piggyback semantics;
- declared channel marginals and OOD perturbations actually exercised.

Integrity gates authorize analysis, not a superiority claim.  If a software
defect is discovered after opening, it must be logged as an amendment, the
original output retained, and the entire affected frozen matrix rerun.  Policy
or matrix changes require a new experiment identifier, not an in-place edit.

## 9. Claim discipline

The final paper must state explicitly whether P10 or another baseline dominates
Causal-Broadcast in Clean, Moderate or Stressed.  It must report all proposed
frontier points and every negative OOD cell.  EXP14 supports only simulation
claims under the abstract channel/MAC above; energy, security, radio standard
compliance and flight readiness require EXP15 measurements and threat testing.
