# SwarmDroneMATLAB

MATLAB research code for **communication-aware UAV swarm coordination**, from single-quadrotor
control up to a 50-agent scalability study, with an Age-of-Information (AoI) aware
event-triggered communication policy as the central contribution.

## Design goals

1. Keep low-level flight stabilization separate from swarm intelligence.
2. Make the swarm layer scalable to 10–50 agents without a full 6-DOF model per agent.
3. Explicitly model packet loss, delay, jitter, reordering and Age of Information.
4. Produce research-friendly metrics and repeatable experiments.
5. Avoid mandatory toolbox dependencies in the core simulation path.

## Quick start

```matlab
startup
exp02_formation          % nominal swarm, seconds
exp05d_pareto_frontier   % the headline policy comparison
```

Or the whole suite:

```matlab
run_all
```

## Results are saved automatically

Every experiment writes a timestamped folder under `results/`:

```text
results/
  INDEX.md                       run log, one row per run, appended automatically
  exp06a_scalability/
    LATEST.txt                   run id of the newest run
    2026-08-20_143012/
      console.log                every line the experiment printed
      workspace.mat              the complete script workspace
      exp06a_scalability.m       snapshot of the source that produced this run
      meta.json                  MATLAB version, host, git commit, elapsed time
      figures/                   every figure as 300 dpi PNG and editable .fig
      tidy.csv                   long-format results, one row per seed x condition
```

Nothing is overwritten; re-running an experiment creates a new run id. `tidy.csv` is the file
to use for paper tables, confidence intervals and statistical tests — it contains the raw
per-seed values, so those can be recomputed without re-running any simulation.

Helper functions live in `utils/`: `startExperiment`, `finishExperiment`, `saveAllFigures`,
`tidyFromArray`, `ensureParallelPool`, `projectRoot`.

## Experiments

### L0 — single vehicle (6-DOF, RK4 @ 500 Hz)

| Script | Purpose |
|---|---|
| `exp01_hover` | 1 m hover hold |
| `exp01b_position_step` | Position step response, settling time |
| `exp01c_disturbance` | Gust rejection and recovery time |
| `exp01d_trajectory` | Circular trajectory tracking |

### L1 — nominal swarm (double integrator @ 50 Hz)

| Script | Purpose |
|---|---|
| `exp02_formation` | Five-agent distributed formation under ideal communication |

### L2 — network characterization

| Script | Sweep | Sims |
|---|---|---|
| `exp03a_packet_loss` | Packet loss 0–60 % | 140 |
| `exp03b_delay` | Fixed delay 0–300 ms | 7 |
| `exp03c_loss_delay` | Loss × delay surface | 480 |
| `exp03d_jitter` | Jitter, reordering, stale-packet rejection | 120 |

### L2 — rate / cost trade-off

| Script | Sweep | Sims |
|---|---|---|
| `exp04a_comm_rate` | Communication rate 2–50 Hz | 5 |
| `exp04b_rate_impairment` | Rate × loss × delay | 540 |

### L2 — communication policy

| Script | Purpose | Sims |
|---|---|---|
| `exp05a_event_triggered` | Conventional event trigger vs periodic, clean network | 8 |
| `exp05b_aoi_aware` | Proposed AoI-aware policy vs baselines, one operating point each | 240 |
| `exp05c_ablation` | Component ablation A0→A4 | 300 |
| `exp05d_pareto_frontier` | Full rate-vs-error frontier for all three policy families | 1080 |

`exp05d` is the decisive comparison: it sweeps the operating point of *every* policy, so the
result does not depend on how each baseline happened to be tuned.

### L1/L2 — scalability

| Script | Sweep | Sims |
|---|---|---|
| `exp06a_scalability` | N = 5, 10, 20, 50 × 4 methods × 2 network scenarios | 640 |

### Deprecated

`exp03_packet_loss_sweep` does not run and errors out on purpose. It called a simulator with no
network model and read metric fields that never existed. Use `exp03a_packet_loss`.

## Read this before trusting the numbers

`docs/RESEARCH_REVIEW.md` documents the modelling assumptions, the known limitations and the
issues that are still open — in particular the idealised ACK channel, the unicast-per-link cost
model, and what the scalability exponent does and does not demonstrate. It also records which
comparisons are valid across experiments and which are not.

## Modelling conventions

World frame is ENU-like Cartesian with `+z` up. The 6-DOF state order is:

```text
x = [position(3); velocity(3); roll; pitch; yaw; bodyRates(3)]
```

The swarm layer (`exp02` onward) uses double-integrator agents with acceleration saturation;
the leader is driven exactly along the reference trajectory and acts as the formation anchor.
The 6-DOF model is not in the swarm loop — see `docs/RESEARCH_REVIEW.md` for why this matters.

## Reproducibility

- Every simulator pins the RNG with `rng(seed, 'twister')`. The explicit generator matters:
  parallel-pool workers default to a different generator, so without it `parfor` would silently
  produce different results from the equivalent serial loop.
- Seeds are shared across methods within a scenario so comparisons are paired.
- `meta.json` records the git commit, MATLAB version and host for every run.

## Toolboxes

The core simulation path uses base MATLAB only. Optional:

- **Parallel Computing Toolbox** — `parfor` over Monte-Carlo seeds in `exp05d` and `exp06a`.
  Without it these still run, just serially.
- **Statistics and Machine Learning Toolbox** — percentile statistics.
