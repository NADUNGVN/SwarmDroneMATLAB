# EXP23AD receiver-lifted closure kernel falsification plan

Frozen: 2026-09-05, before registered execution.

## Matrix

- N = {5, 10, 20}.
- 100 new seeds per N.
- Eight conditions: nominal zero-erasure, IID-20, PREPARE blackout, QUIESCENT blackout, RESPONSE blackout, COMMIT blackout, REVOKE blackout, and an incomplete-union oracle control.
- Total: 2,400 kernel rows.

Each fixture changes one or more physical relations incident to the initiator acting as a receiver. The receiver lift converts these into sender-conflict edges whose endpoints exclude the initiator. The exact migration closure is the initiator plus all changed-edge endpoints, with closure sizes varied by seed.

## Frozen contracts

The study requires 24/24 gates. In particular:

- closure membership is exact and every fixture contains a nonincident receiver-lifted sender change;
- joint candidate colors the old/new union and leaves every outside slot fixed;
- nominal rows close the barrier, authorize motion, and reactivate all affected senders;
- aggregate IID-20 completion has a 95% Wilson lower bound of at least 0.95;
- PREPARE or QUIESCENT blackout prevents motion authorization;
- RESPONSE blackout permits gated graph activation but no commit and keeps the closure suppressed;
- COMMIT blackout permits only the initiator to reactivate and remains collision-safe;
- REVOKE loss is state-identical to nominal operation;
- incomplete union is detected by the independent post-activation graph oracle;
- all supported rows are collision-free, packet/byte/airtime accounting closes, analytical bounds hold, and forbidden reads are zero.

No closed-loop, plant-coupling, or submission claim is allowed from a kernel pass.

