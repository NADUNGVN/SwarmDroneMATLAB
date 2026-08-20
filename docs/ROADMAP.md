# Research implementation roadmap

## L0 — Single vehicle baseline
- 6-DOF rigid-body model.
- Position + attitude controller.
- Hover, step position and trajectory tracking.
- Inject IMU-like noise later.

## L1 — Multi-agent baseline
- 5 UAVs first, then scale to 10–50 agents.
- Consensus / leader-follower / formation baselines.
- Safety separation and connectivity metrics.

## L2 — Communication-aware swarm
- Packet loss, delay, bandwidth and Age of Information.
- Event-triggered communication baseline.
- Compare fixed-rate vs event-triggered communication.
- Report coordination error versus communication cost.

## L3 — Partial observability and estimator coupling
- Neighbor-state staleness.
- Sensor noise / dropout.
- EKF or complementary estimator interface.

## L4 — Learned policy
- Tiny GNN / MARL high-level policy.
- Keep low-level PID deterministic.
- Quantization/compression and compute budget.

## L5 — Sim-to-real
- First 5-node tabletop communication test.
- One-drone hover/position hold.
- Two-drone coordination.
- Three-to-five-drone swarm.
- Log timestamp, PDR, latency, AoI, CPU, RAM, energy and deadline misses.
