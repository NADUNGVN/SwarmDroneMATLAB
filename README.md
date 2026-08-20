# SwarmDroneMATLAB

Starter MATLAB project for a research path from **single quadrotor control** to **communication-aware UAV swarm simulation** and later sim-to-real deployment on 3–5 micro-drones.

## Design goals

1. Keep low-level flight stabilization separate from swarm intelligence.
2. Make the swarm layer scalable to 10–50 agents without requiring a full 6-DOF model for every agent.
3. Explicitly model packet loss, delay and Age of Information (AoI).
4. Produce research-friendly metrics and repeatable experiments.
5. Avoid mandatory toolbox dependencies in the starter version. UAV Toolbox can be added later for scenario visualization/formation metrics.

## Project structure

```text
SwarmDroneMATLAB/
├─ startup.m
├─ run_all.m
├─ configs/
├─ models/quadrotor/
├─ controllers/
├─ simulation/
├─ swarm/
├─ network/
├─ metrics/
├─ visualization/
├─ experiments/
├─ tests/
├─ results/
├─ docs/
└─ utils/
```

## First run

Open MATLAB in this project folder and run:

```matlab
startup
exp01_hover
exp02_formation
exp03_packet_loss_sweep
```

Or run everything:

```matlab
run_all
```

## Experiments

### `exp01_hover`
Single 12-state quadrotor, 6-DOF rigid-body dynamics, geometric attitude control and outer-loop position control. Verifies that the low-level controller can hold a 1 m hover.

### `exp02_formation`
Five-agent distributed formation simulation using a double-integrator abstraction. This isolates swarm coordination from low-level motor dynamics.

### `exp03_packet_loss_sweep`
Runs repeated formation experiments under increasing packet-loss probability and saves a CSV with formation RMSE, minimum separation, velocity disagreement, PDR and mean AoI.

## Important modeling convention

World frame is **ENU-like Cartesian** with `+z` upward. State order for the 6-DOF model:

```text
x = [position(3); velocity(3); roll; pitch; yaw; bodyRates(3)]
```

The quadrotor body `+z` axis is defined along the thrust direction in this starter model.

## Research evolution

Recommended progression:

1. Validate hover and trajectory tracking.
2. Validate nominal distributed formation.
3. Add packet loss/delay/AoI sweeps.
4. Replace fixed consensus gains with event-triggered / learned communication policies.
5. Add estimator noise and partial observability.
6. Add resource metrics (CPU, memory, energy, deadline misses).
7. Add UAV Toolbox visualization and formation metrics if available.
8. Export the high-level policy to embedded targets; keep low-level PID on the MCU.

## Toolbox policy

The starter code uses base MATLAB syntax only. If UAV Toolbox is available, later modules can use `uavScenario`, `uavPlatform`, sensor models and `uavFormationMetrics` without changing the core swarm-policy interfaces.
