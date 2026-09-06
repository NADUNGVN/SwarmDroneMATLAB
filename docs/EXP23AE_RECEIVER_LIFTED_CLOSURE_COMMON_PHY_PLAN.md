# EXP23AE receiver-lifted closure common-PHY validation plan

Frozen: 2026-09-05, before registered execution.

## Question

Does the EXP23AD receiver-lifted closure state machine remain exact when every
PREPARE, QUIESCENT, CLAIM, LOCK-PROOF, RESPONSE, COMMIT and DATA transmission
occupies the same continuous-time PHY under bounded affine clock error?

## Frozen matrix

- 50 new development seeds, N={5,10,20}.
- Seven cases: nominal zero-erasure, IID-20, PREPARE blackout, QUIESCENT
  blackout, RESPONSE metadata blackout, COMMIT blackout, and an intentionally
  incomplete sender-union oracle.
- Two paired clocks: exact and bounded affine clock with offset <=0.25 ms and
  drift <=40 ppm.
- 2,100 rows total.
- 250 kb/s PHY, 96-byte DATA and at most 96-byte control packets.
- The guard is calculated, not tuned, by `continuousTdmaGuardBound` over a
  30-second reset horizon.

The continuous frame has two N-slot management phases, one COMMIT slot and N
DATA slots. PREPARE and QUIESCENT carry revocation semantics, so no standalone
REVOKE packet is introduced. Logical opportunities must pair exactly between
clock arms.

## Frozen decision contracts

The run requires 22/22 gates. They cover the locked EXP23AD parent; exact
matrix and paired hashes; nonincident receiver-lift stimulus; union coloring;
piggyback/control-kind, byte, airtime and recipient accounting; exact mapping
of every kernel active/suppressed state and slot to DATA; receiver-level DATA
outcome partition; zero supported collision; oracle-negative collision
agreement; affine-clock safety; no trimmed logical opportunities; blackout
semantics; aggregate IID-20 completion; bounded/causal execution; and scope.

This is integration evidence only. It cannot authorize a closed-loop, online
plant-coupling, fresh-seed or submission claim.
