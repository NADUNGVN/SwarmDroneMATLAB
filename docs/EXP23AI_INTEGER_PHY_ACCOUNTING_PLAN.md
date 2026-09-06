# EXP23AI integer-PHY accounting confirmation plan

Frozen: 2026-09-06, before any registered seed is executed.

## Parent result and repair

EXP23AH `2026-09-06_001301` remains **invalid at 26/27 gates**. Its 50 fresh
seeds passed every online geometry, reliability, transaction, common-PHY,
causality, negative-control and safety gate. The sole failure was a tolerance
comparison between two floating-point summations of the same management
airtimes. The largest difference was `1.3322676295501878e-15 s`; all observed
attempt counts matched exactly and every byte-bound ratio was below 0.949.

The result is not relabeled and the tolerance is not enlarged. The PHY runtime
now accumulates an integer `dstrManagementBytes` counter. Continuous schedules
carry exact per-group bytes and PHY bit rate through affine-clock mapping.
Runtime management airtime is recomputed as

`A_mgmt = 8 * B_mgmt / R_phy`

after each group. The registered gate requires exact equality of observed,
scheduled and kernel byte totals, plus exact equality to the derived airtime.

## Frozen matrix

- 50 untouched seeds, 16094401--16094450, disjoint from all design,
  calibration, EXP23AG and EXP23AH seeds.
- The complete EXP23AH configuration is unchanged: N=10; 10.5 s mission;
  request at 4 s; 7 PREPARE, 15 CLAIM and 6 COMMIT opportunities; persistent
  QUIESCENT; IID-20 control/DATA erasure; bounded affine clocks; pairwise
  radial budgets 0.11/0.18/0.23 m; receiver-lifted union coloring; parallel
  emergency service; and the same six paired arms.
- 300 rows total. No scientific or numerical tolerance may change after the
  run begins.

## Frozen gates

EXP23AI requires 28/28 gates. Gates 1--27 retain the EXP23AH scientific
contracts: fresh registry and explicit invalid parent; exact matrix/trace/
prefix/geometry pairing; receiver-lift stimulus; union/MTU/slot and kernel-v2
bounds; motion/blackout semantics; analytical transaction reliability below
`10^-3`; at least 95% normal completion with safe abort; protected emergency
mapping; radial premise/theorem and actual graph subsets; paired negative
removal; collision safety; exact receiver outcome replay; affine timing,
causality, closed-loop safety and non-promotion scope.

The accounting requirement is split into two independently visible gates:

1. management attempts and integer observed/scheduled/kernel bytes match
   exactly and respect analytical attempt/byte bounds;
2. observed and expected airtime both equal `8*bytes/rate` exactly.

Passing EXP23AI validates the single-transaction, fresh-seed phase-reserved
radial closure result. It still does not validate routed multi-hop management,
repeated online renewal, broad topology/network robustness, or submission
readiness.
