# Artifact README

Everything needed to reproduce the simulation campaign and the manuscript
built on it.

| | |
|---|---|
| **Frozen simulation release** | tag `simulation-v1.0`, commit `32858b1` |
| **Paper package** | branch `paper-v1` (accepted at `8c79ee0`), `paper-v2` candidate on top |
| **Machine-readable identity** | `paper/FROZEN_BASE.json` |
| **Language / runtime** | MATLAB R2025a on Windows |

The SHA is the authority, not the tag. A tag is a movable label; the commit
is not. Every verification in this artifact is anchored to `32858b1`.

---

## 1. What `simulation-v1.0` contains

The complete, frozen simulation campaign: the swarm and network models, the
four communication methods, the ten experiment scripts (EXP01–EXP10), the
nine-file test suite, and the persisted results of every experiment that
counts.

| Claim group | Count | Where |
|---|---|---|
| Supported | 8 | `docs/FINAL_CLAIMS.md` |
| Limited / conditional | 12 | `docs/FINAL_CLAIMS.md` |
| Rejected | 7 | `docs/FINAL_CLAIMS.md`, Table VI of the manuscript |

The headline result set is the EXP10 holdout validation: 3400 runs, 17
point-scenario cells, four methods, 50 seeds never used during development.

**What it does not contain:** any hardware measurement. No timing, airtime,
energy or radio quantity in this artifact was measured on a device.

## 2. What the paper package contains

```
paper/
  main.tex                   manuscript root
  sections/01..09_*.tex      nine sections
  references.bib             48 verified references
  tables/tableI..VI.tex      GENERATED - do not edit
  figures/fig01..11.{pdf,png} GENERATED - do not edit
  generated/                 GENERATED - do not edit
    headline_metrics.csv     279 metrics, each with its source file
    metrics.tex              125 LaTeX macros
    PROVENANCE.md            which result directory fed what
  scripts/                   the generators and the checkers
    make_paper_metrics.m     harvests every number from frozen results
    make_paper_tables.m      builds the six tables
    make_paper_figures.m     builds the eleven figures
    paper_guard.m            proves no frozen source was modified
    paper_audit.m            publication consistency rules
  FROZEN_BASE.json           frozen identity anchor
  CLAIM_LEDGER.md            publication-ready claim table
  REFERENCE_AUDIT.csv        per-reference verification status
  LITERATURE_SEARCH_LOG.md   how references were found and verified
  RELATED_WORK_MATRIX.md     reference-to-claim mapping
  NOVELTY_GAP_REVIEW.md      15 near neighbours, element by element
  REPRODUCIBILITY.md         seeds, CRN, defects found during the freeze
  MANUSCRIPT_QA.md           static QA and the compiler blocker
  VENUE_SHORTLIST.md         5 venues, ranked, from official sources
  RISK_REGISTER.md           11 risks with required paper wording
  REVIEWER_ATTACKS.md        18 criticisms, classified honestly
  AUDIT_REPORT.md            GENERATED - audit verdict
```

## 3. Repository structure (frozen paths)

```
simulation/    the four simulators (periodic, state-event, causal, AoI-ideal)
network/       trigger policies, queues, delivery, ACK channel
swarm/         formation policy, follower integration, estimator, topology
controllers/   cascaded quadrotor controller
models/        6-DOF quadrotor dynamics
metrics/       formation RMSE, minimum separation, 6-DOF metrics
configs/       defaultConfig - every locked parameter
utils/         CRN generators, hashes, paired CI, EXP10 registry
experiments/   EXP01..EXP10 scripts and the validation entry points
tests/         nine test files + run_all_tests
results/       persisted runs: console.log, tidy.csv, meta.json, figures
docs/          pre-registration, final claims, hardware roadmap
```

**These paths are read-only on the paper branch.** `paper/scripts/paper_guard.m`
verifies that against `git diff` from the frozen commit and fails if any of
them was touched.

## 4. MATLAB version and toolboxes

| | |
|---|---|
| **Version used** | MATLAB 25.1 (R2025a) |
| **Required beyond base** | Statistics and Machine Learning Toolbox — `tinv`, for the paired confidence intervals |
| **Used for throughput only** | Parallel Computing Toolbox — results are independent of worker count, which is verified rather than assumed |
| **Recorded environment** | `results/simulation_v1_validation/<run>/manifest.json` lists all 111 toolboxes present, the platform, core count and pool configuration |

The full validation runs without the Parallel Computing Toolbox; MATLAB
executes `parfor` serially and the results are identical.

## 5. Reproducing the tables

```matlab
addpath('paper/scripts');
make_paper_metrics      % generated/headline_metrics.csv, metrics.tex, PROVENANCE.md
make_paper_tables       % tables/tableI..VI.tex
```

Runtime: seconds. Reads persisted `tidy.csv` files only; runs no simulation.

## 6. Reproducing the figures

```matlab
addpath('paper/scripts');
make_paper_figures      % figures/fig01..fig11.pdf and .png
```

Runtime: under a minute. Figures 1 and 2 are schematics with no measured
quantity; Figures 3–11 are drawn from persisted results. Deterministic — no
random draw, no order-dependent layout.

## 7. Smoke validation (minutes)

```matlab
exp10SmokeSeeds = 25000001:25000003;
exp10a_final_validation      % 3 seeds, 204 runs, all 5 gates
clear exp10SmokeSeeds
```

A shortened run cannot masquerade as the real one: the seed list is printed
to `console.log`, written into every row of `tidy.csv`, and re-checked by
gate G2.

## 8. Full EXP10 validation

```matlab
run_simulation_v1_validation             % reload mode: reuse the dataset
v1ForceRun = true; run_simulation_v1_validation   % regenerate from scratch
run_clean_clone_check                    % clone HEAD and reproduce it
```

| Step | Runtime |
|---|---|
| Test suite (9 files) | ~5–7 min |
| Reload-mode validation (7 steps) | ~6 min |
| **Full EXP10A regeneration** | **~30 min** (3400 runs, 16 workers) |
| Clean-clone check | ~10 min |

Blocking steps are the test suite, the locked-tag check, the realisation-hash
re-verification and the serial-versus-parallel determinism check. An
unfavourable *scientific* result is never a blocker.

## 9. Seed policy

- Development experiments: 20 seeds each, per-experiment seed families.
- **Final validation: holdout block `25000001:25000050`**, proven disjoint
  from every EXP01–EXP09 seed family before any simulation ran.
- The seed count was fixed in advance. Adding seeds after inspecting a
  confidence interval is forbidden — that is choosing the sample size by
  the result.

## 10. CRN policy

Sharing a seed is not sharing a realisation: each policy calls the random
number generator a different number of times, so two methods at one seed
desynchronise at the first transmission. Every stochastic input is therefore
**pre-drawn** and consumed by lookup, indexed by `(link, timestep)` or by
physical time:

| Realisation | RNG offset |
|---|---|
| forward channel | 20240001 |
| reverse ACK channel | 30240001 |
| link-fault pattern | 50240001 |
| node blackout | 60240001 |
| external-force trace | 70240001 |
| estimator-noise trace | 80240001 |
| transmission phase | 90240001 |

Consequences, all checked rather than asserted: traffic volume does not
advance the realisation (all four methods report the same forward hash at a
seed despite very different packet counts); a scenario changes thresholds,
not draws; and traces that must survive a timestep change are indexed by
physical time.

## 11. Known negative results

Seven pre-registered claims were tested and **rejected**. They are part of
the artifact, not omissions from it:

| Rejected claim | Evidence |
|---|---|
| Stressed ACK-inclusive Pareto superiority | non-dominated in 37.5 % of cells at w = 0.50, airtime and broadcast; ACK-inclusive paired difference **+10.67 Hz** |
| Universal topology safety | safety gate fails at one sweep condition; cause is the unnormalised consensus gain (controller) |
| Absolute link-fault safety | 9/49 connected seeds unsafe, **identical** for P10, P20 and ours |
| 5 s node-blackout safety | 9/50 eligible seeds unsafe under matched no-fault eligibility |
| ≤ 25 % RMSE degradation under plant mismatch | **+720 %** at Moderate; controller has no integral action |
| Clean estimator-noise traffic < 2× | ratio **×2.34** |
| DATA-rate invariance to Δt | 202.9 / 182.9 / 133.0 Hz at Δt = 0.01 / 0.02 / 0.04 s |

A favourable later number does not retract an earlier rejection. EXP10 ran
**one** selected point per rejection; one point cannot retract a sweep.

## 12. What has NOT been experimentally validated

Stated plainly, because it is the most important limitation of this
artifact:

- **Nothing has been run on hardware.** No radio, no flight controller, no
  vehicle.
- **Airtime and energy are proxies.** The airtime cost model prices frames
  by assumed byte counts (48 B DATA, 24 B ACK); the broadcast model is an
  accounting proxy, not a medium-access simulation. There is no MAC, no
  contention and no duty-cycle model.
- **The estimator is synthetic.** Noise standard deviations and latency are
  parameter assumptions, not sensor measurements.
- **The disturbance is a proxy.** A world-frame nominal-mass-equivalent
  acceleration, with no airspeed dependence, drag coefficient or frontal
  area — it is not an aerodynamic wind model.
- **One topology, one geometry, one timestep** in the final validation:
  ring, one formation lattice, Δt = 0.02 s.
- **The leader is kinematic** in the 6-DOF study and is never blacked out.
- **6-DOF results are at N = 5** (secondary at N = 10); the N = 50 anchor is
  double-integrator. Physical realism and scale are never demonstrated
  together.

`docs/HARDWARE_ROADMAP.md` stages the transition, naming for each phase the
simulation assumption it is designed to test. Phases H0–H2 need no vehicle
and address exactly the assumptions above that are most in need of
measurement.
