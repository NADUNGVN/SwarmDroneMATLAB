# FINAL CLAIMS — simulation-v1.0

Every claim this simulation campaign supports, limits, or rejects. One
place, three groups, each claim pointing at the experiment, tag and result
directory that carries its evidence.

**How to read this file.** A claim in **SUPPORTED** is one the campaign
demonstrated under stated conditions. A claim in **LIMITED / CONDITIONAL**
holds only under a condition that must be quoted alongside it — drop the
condition and the claim becomes false. A claim in **REJECTED** was tested
and did not hold; those are results, not open tasks, and nothing later in
the campaign retracted them.

**Scope of the whole document.** This is a SIMULATION campaign. Nothing
here is a hardware result. The 6-DOF quadrotor, the external-force proxy
and the estimator noise are parameter assumptions, not measurements, and
the estimator sigmas in particular must never be presented as a measured
sensor model.

**Final validation.** EXP10A ran the frozen protocol on **50 holdout
seeds never used during development** (`25000001:25000050`), 3400 runs
across 17 point-scenario cells, with all six CRN master realizations
hash-verified per seed. Every number labelled *EXP10* below comes from
that dataset. Paired differences carry a 95 % confidence interval on 50
matched pairs.

| Group | Count |
|---|---|
| SUPPORTED | 8 |
| LIMITED / CONDITIONAL | 11 |
| REJECTED | 7 |

---

## SUPPORTED

### S1 — Causal-AoI-v3 is causally implementable

The transmitter learns what the receiver holds **only** through ACK
packets that cross a reverse channel with its own delay, jitter and loss.
No same-timestep synchronisation, no reading of receiver state.

- **Evidence** EXP07A `exp07a-locked`, 9/9 gates —
  `results/exp07a_causal_ack/2026-08-21_202017`
- **EXP10** 0 causality-invariant violations across all 3400 holdout runs
  (ACK-before-accept, ACK-for-dropped-data, sender rollback, future
  genTime, stale-ACK-accepted, unknown-sequence ACK, sequence/genTime
  mismatch, new-info bypass without innovation, refresh while a useful
  packet is in flight — all zero)

### S2 — Lower formation RMSE than 10 Hz periodic at Nominal Stressed

Pre-registered claim **K1**, on holdout seeds, directional.

| | value |
|---|---|
| mean paired difference RMSE(Causal-v3 − P10) | **−0.0288 m** |
| 95 % CI | **[−0.0294, −0.0283]** |
| pairs | 50 / 50 |
| verdict | interval entirely below zero → **SUPPORTED** |

- **Evidence** EXP10A — `results/exp10a_final_validation/2026-08-27_081056`

### S3 — Lower mean RMSE than State-event throughout the final matrix

Causal-v3 has lower mean formation RMSE than State-event in **all 17
cells**. The statement is permitted by the rule fixed in `EXP10_PLAN.md`
§12 before the data existed, not asserted in advance.

- **Evidence** EXP10B — `results/exp10b_unified_matrix/2026-08-27_084853`
- **Read with L11**: part of this margin is State-event failing safety
  outright at N = 20 and N = 50.

### S4 — One configuration adapts to network quality

A single parameter set, no per-scenario tuning. Causal-v3 DATA rate on
the nominal N = 5 6-DOF point:

| Scenario | DATA Hz | ACK Hz | DATA + 0.25 ACK | RMSE | AoI |
|---|---|---|---|---|---|
| Clean | 84.47 | 84.47 | 105.58 | 0.0414 | 0.060 |
| Moderate | 134.84 | 107.62 | 161.74 | 0.0892 | 0.142 |
| Stressed | 182.94 | 109.61 | 210.34 | 0.1188 | 0.190 |

Clean < Moderate < Stressed on DATA: **MET**. The ACK-inclusive total is
reported beside it, because DATA alone does not say what happened to total
communication.

- **Evidence** EXP10B, nominal point, 50 holdout seeds

### S5 — The result survives 6-DOF quadrotor followers

Not a double integrator: full attitude dynamics, an inner loop at 500 Hz
against a 50 Hz outer loop, thrust and torque saturation, an analytic
command-consistent reference.

- **Evidence** EXP09A `exp09a-locked`, 7/7 gates —
  `results/exp09a_multiuav_6dof/2026-08-26_210235`
- **EXP10** 0 divergences in 3400 runs, and 0 runs left a 50 m ball while
  staying finite, so the divergence labelling is complete rather than
  merely empty

### S6 — Non-dominated in Moderate under the pre-registered criterion

Fraction of evaluable Moderate point-families in which Causal-v3 is
non-dominated, under the 1 % dominance rule inherited from EXP05D/EXP07C:

| Cost model | non-dominated |
|---|---|
| w = 0.10 | 87.5 % (7/8) |
| **w = 0.25 (reference)** | **87.5 % (7/8)** |
| w = 0.50 | 87.5 % (7/8) |
| airtime | 87.5 % (7/8) |
| broadcast | 25.0 % (2/8) |

Reference criterion ≥ 75 % at w = 0.25: **MET**. The single Moderate loss
is `ESTIMATOR / Moderate`, dominated by P20.

**This claim is inseparable from L2.** Under broadcast accounting the same
fraction is 25 %.

- **Evidence** EXP10B

### S7 — Scales to N = 50 without divergence

| Method | RMSE | minSep | DATA Hz | unsafe |
|---|---|---|---|---|
| P10 | 0.2882 | 0.3026 | 1225.90 | 0/50 |
| P20 | 0.2216 | 0.3746 | 2455.90 | 0/50 |
| State-event | 0.4952 | 0.0864 | 451.63 | **50/50** |
| Causal-v3 | 0.2347 | 0.3618 | 2139.49 | 0/50 |

(N = 50, double integrator, ring2, Stressed, 50 holdout seeds.)

- **Evidence** EXP10B `SCALE` point; EXP06A for the scaling exponent
- **Read with L10**: absolute traffic at N = 50 is not comparable to
  EXP06A, which used a different graph convention

### S8 — The claim set is reproducible

- full test suite of 9 files, including `test_lock_regression`, which
  re-derives the stored EXP05C / EXP06A / EXP07A values **bit-identically**
- all six CRN master realizations per seed re-derived in a fresh MATLAB
  process and matched against the persisted dataset
- serial versus parallel execution compared **bit-identically** — every
  counter, every exact realization hash and the full trajectory, with no
  tolerance applied
- a fresh `git clone` reproduces the test suite, the unified matrix
  rebuilt from persisted tidy files, and one re-simulated seed
- **Evidence** EXP10C — `experiments/run_simulation_v1_validation.m`,
  `experiments/run_clean_clone_check.m`,
  `results/simulation_v1_validation/<LATEST>` incl. `manifest.json` and
  `trace_hashes.csv`

**One caveat, stated rather than buried.** The *locked* trace-generator
checksums (whose values appear in EXP07–EXP09 result tables, and which
therefore could not be changed) sum millions of floats past 2^53, so their
last one or two digits move with MATLAB's multithreaded summation
grouping — a pool worker runs single-threaded, the client does not. They
also need sixteen digits and lose one when written to CSV. They are
reported and compared against a **stated** relative tolerance of 1e-14;
the gates use `realizationHash`, which is exact integer arithmetic
throughout and therefore genuinely order-independent and text-safe. This
was found by the determinism check itself: the trajectories were
bit-identical while the checksums differed, which is what identified the
checksum rather than the simulation as the problem.

---

## LIMITED / CONDITIONAL

### L1 — The communication saving is DATA-only, and reverses under ACK-inclusive cost

Pre-registered claims **K2a** and **K2b**, Nominal Stressed, neither
carrying a direction:

| Claim | mean paired difference vs P20 | 95 % CI |
|---|---|---|
| K2a DATA | **−16.73 Hz** | [−16.77, −16.68] |
| K2b DATA + 0.25 ACK | **+10.67 Hz** | [+10.59, +10.76] |

Causal-v3 sends **fewer DATA packets** than 20 Hz periodic and **more
total traffic** once its acknowledgements are priced. Both intervals
exclude zero, so this is not ambiguity — it is a reversal.

**No communication-saving claim may be made from this cell.** Across the
whole final matrix Causal-v3 is the cheapest method in **0 of 17** cells
at w = 0.25 (State-event is cheapest in 13, P10 in 4).

- **Evidence** EXP10A / EXP10B; the mechanism was established by EXP07C
  `exp07c-locked-negative`

### L2 — The Moderate Pareto result does not survive broadcast accounting

Under broadcast accounting — one radio transmission from a sender priced
once regardless of how many neighbours receive it, ACKs still unicast —
Causal-v3 is non-dominated in only **25 % (2/8)** of Moderate cells. The
87.5 % of S6 is a packet-count and airtime result.

- **Evidence** EXP10B

### L3 — Stressed non-dominance is cost-model dependent

| Cost model | Stressed non-dominated |
|---|---|
| w = 0.10 | 100 % |
| w = 0.25 | 75 % |
| w = 0.50 | 37.5 % |
| airtime | 37.5 % |
| broadcast | 37.5 % |

Reported, **not gated**. EXP07C rejected Stressed Pareto superiority and
EXP10 does not re-open it.

- **Evidence** EXP10B

### L4 — Causal-v3 is not the most accurate method

P20 has the lower mean RMSE in **16 of 17** cells. Causal-v3 wins one:
`ESTIMATOR / Stressed` (0.1007 against P20's 0.1050). The accuracy claim
is against P10 and State-event, never against P20.

- **Evidence** EXP10B

### L5 — Even against P10, the accuracy advantage has two exceptions

| Cell | Causal-v3 | P10 |
|---|---|---|
| `NOMINAL / Clean` | 0.0414 | **0.0361** |
| `LINK / Moderate` | 1.0656 | **1.0655** |

The Clean exception is real: with no loss and no delay, 10 Hz periodic
already delivers everything and event triggering only adds jitter in
information age. The LINK exception is a tie to four decimal places at a
condition where all methods are failing badly (RMSE ≈ 1.07 m).

K1 was pre-registered at Nominal Stressed only, where it is supported;
these two cells are outside it and are reported rather than absorbed.

- **Evidence** EXP10B

### L6 — Safety under link and node faults is not restored

Unsafe fraction under each source experiment's own eligibility rule:

| Cell | P10 | P20 | State-event | Causal-v3 |
|---|---|---|---|---|
| `LINK / Moderate` | 9/49 | 9/49 | 10/49 | 9/49 |
| `LINK / Stressed` | 9/49 | 9/49 | 24/49 | 9/49 |
| `NODE / Moderate` | 9/50 | 9/50 | 16/34 | 9/50 |
| `NODE / Stressed` | 11/50 | 9/50 | *(0 eligible)* | 9/50 |

The rate is **identical across P10, P20 and Causal-v3** — about 18 % — so
the failure belongs to the formation geometry and the controller, not to
the communication policy. Choosing a better policy does not fix it.

- **Evidence** EXP10B; EXP08B `exp08b-locked-partial`, EXP08C
  `exp08c-locked-partial`

### L7 — Topology generalization is untested by EXP10

EXP10 ran **ring2 only**. EXP08A left safety generalization across
topology partial, and EXP10 carries no evidence either way about
`sparse4`, `sparse6` or the geometric graph.

- **Evidence** EXP08A `exp08a-locked-partial`; attribution in EXP08A-D
  `exp08ad-locked-diagnostic` (unnormalised consensus gain)

### L8 — Estimator noise inflates traffic and costs Causal-v3 its one Moderate loss

At the C3 estimator point (σP 0.03 m, σV 0.05 m/s, 50 ms latency):

| Cell | Causal DATA | nominal DATA | ratio |
|---|---|---|---|
| `ESTIMATOR / Moderate` | 227.59 Hz | 134.84 Hz | **×1.69** |
| `ESTIMATOR / Stressed` | 249.16 Hz | 182.94 Hz | **×1.36** |

`ESTIMATOR / Moderate` is the single Moderate cell where Causal-v3 is
dominated (by P20), and it is dominated *because* of this traffic
inflation — Causal-v3 sends **more** DATA than 20 Hz periodic there
(227.59 against 199.67 Hz).

- **Evidence** EXP10B; EXP09C `exp09c-locked-partial`

### L9 — ACK-impairment tolerance is saturation, not robustness

EXP07B passed 5/5 gates under reverse-channel impairment, but the
mechanism is that the policy was already transmitting near its ceiling, so
losing acknowledgements changed little. That is not the same thing as
being robust to them.

- **Evidence** EXP07B `exp07b-locked`
- **EXP10** at the ACK point (10 % reverse loss), the three baselines are
  bit-identical to their nominal runs — they have no reverse channel at
  all — which is verified as a protocol invariant, not assumed

### L10 — N = 50 traffic is not comparable to EXP06A

EXP10 uses the EXP08 graph convention (`applyTopologyConfig`, which
removes in-links to the leader because the leader reads the reference
directly). EXP06A used `applyScalableSwarmConfig`, which keeps them. The
two have different channel counts at the same N, so **absolute** traffic
must not be compared across them. Method ratios within EXP10 are
unaffected.

### L11 — State-event fails safety without any fault at N = 20 and N = 50

Part of S3's margin is the comparator collapsing rather than Causal-v3
excelling:

| Cell | State-event unsafe |
|---|---|
| `NOMINAL / Stressed` (N = 5) | 12/50 |
| `N20REF / Moderate` | 16/50 |
| `N20REF / Stressed` | **50/50** |
| `SCALE / Moderate` | 19/50 |
| `SCALE / Stressed` | **50/50** |

Because State-event was unsafe in all 50 no-fault seeds at
`N20REF / Stressed`, EXP08C's matched no-fault eligibility rule leaves it
**zero eligible seeds** at `NODE / Stressed`. Its blackout safety there is
*unevaluable*, not zero — a `0/0` that must not be read as "no failures".

- **Evidence** EXP10B

---

## REJECTED

Each of these was tested and did not hold. None is re-tested away later.
EXP10 ran **one** selected point per rejection, on new seeds; one point
cannot retract a sweep, and where EXP10 has no evidence that is stated
rather than left silent.

### R1 — Stressed ACK-inclusive Pareto superiority

**REJECTED** by EXP07C `exp07c-locked-negative` —
`results/exp07c_cost_model/2026-08-21_214817`.

EXP10 does not re-open it: Stressed carries no superiority gate, and the
holdout numbers point the same way (L1, L3).

### R2 — Safety generalization across topology

**REJECTED as a general claim** by EXP08A `exp08a-locked-partial`; safety
failed systematically at one condition. Attributed by EXP08A-D
`exp08ad-locked-diagnostic` to the unnormalised consensus gain. EXP10 adds
no evidence (L7).

### R3 — Absolute safety under permanent link failure

**REJECTED** by EXP08B `exp08b-locked-partial`; the failure is shared by
every method. EXP10 at 20 % permanent removal: ≈ 18 % of connected seeds
unsafe for P10, P20 and Causal-v3 alike (L6).

### R4 — Absolute safety under a 5 s node blackout

**REJECTED** by EXP08C `exp08c-locked-partial`; shared by every method.
EXP10 at one follower dark for 5 s: 9/50 eligible seeds unsafe for P10,
P20 and Causal-v3 alike (L6).

### R5 — Absolute RMSE robustness to plant mismatch

**REJECTED** by EXP09B `exp09b-locked-partial`. EXP10 at arm B7
(external-force proxy 0.5 m/s², true mass +10 %, true drag +20 %):

| Cell | Causal RMSE | nominal | increase |
|---|---|---|---|
| `MISMATCH / Moderate` | 0.7317 | 0.0892 | **+720 %** |
| `MISMATCH / Stressed` | 0.7372 | 0.1188 | **+521 %** |

**Attribution stands and matters:** the controller has no integral action,
so a mass offset leaves a steady-state error that no communication policy
can remove. This is a controller limitation, not a communication one, and
fixing it is a control-design task outside this campaign.

### R6 — Bounded false-trigger bandwidth under estimator noise in Clean

**REJECTED** by EXP09C `exp09c-locked-partial`: Clean-scenario noise drove
hard triggers and more than **doubled** DATA traffic against the noiseless
arm, breaching the pre-registered 2× bound.

EXP10 did **not** run the estimator point at Clean, so it carries no
evidence about this failure and cannot retract it.

### R7 — Invariance of the communication rate to the outer timestep

**REJECTED** by the EXP09C timestep diagnostic
(`results/exp09c_timestep_diagnostic/2026-08-27_030722`). Formation RMSE
was stable across the outer dt, but the DATA rate was not: it depends
materially on dt, so a rate quoted from this campaign is a rate **at
dt = 0.02 s**, not a property of the policy.

EXP10 ran dt = 0.02 s only, so the rejection stands untouched.

---

## What this campaign does not claim

- no hardware validation of any kind
- no claim about topologies other than ring2 in the final validation
- no claim about outer timesteps other than 0.02 s
- no claim that Causal-v3 reduces total communication cost once
  acknowledgements are priced (L1)
- no claim that Causal-v3 is the most accurate policy tested (L4)
- no claim that any communication policy restores safety under link or
  node faults, or under plant mismatch (L6, R3, R4, R5)
- no aerodynamic wind model — the external forcing is a world-frame
  nominal-mass-equivalent acceleration proxy
- no measured sensor model — the estimator sigmas and latency are
  parameter assumptions

## Provenance

| Artefact | Location |
|---|---|
| pre-registration | `docs/PREREGISTRATION.md`, `docs/EXP10_PLAN.md` |
| holdout dataset | `results/exp10a_final_validation/2026-08-27_081056/tidy.csv` (3400 rows) |
| unified matrix | `results/exp10b_unified_matrix/2026-08-27_084853/tidy.csv` (68 rows) |
| freeze validation | `results/simulation_v1_validation/<LATEST>/` |
| run index | `results/INDEX.md` |
| tag | `simulation-v1.0` |
