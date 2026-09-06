# EXP23T — Static coherence common-PHY closed-loop confirmation

Status: frozen before fresh-seed execution on 2026-09-04.

The study uses 100 fresh seeds `16081001:16081100` in the frozen N5 6-DOF,
IID-15% shared-occupancy cell. Three arms share each absolute channel,
estimator, clock and occupancy realization: the EXP23D lower-cost periodic
boundary, a 1 s static coherence lease, and the 6.8 s target static coherence
lease. Both coherence arms use the repaired receiver-detectability graph,
cumulative receipts and exact 28-byte CLAIM, 16+10e-byte RESPONSE, 24-byte
REVOKE/96-byte-MTU format.

The topology/interference graph is explicitly declared fixed for this study;
the static certificate therefore validates the common-PHY packet and cost
mechanism, not online motion-tube reselection. The primary target must reduce
management airtime by at least 75% relative to the 1 s arm, remain within 1%
RMSE of that arm, and cost at least 1% less than the periodic boundary. Paired
bootstrap confidence intervals use 10,000 resamples. Safety, terminal
liveness, continuous replay, clock, recipient, airtime and causal gates are
mandatory and failures remain visible.

A pass is fresh evidence for the static common-PHY mechanism only. Dynamic
closed-loop and online graph-migration validation remain required before
promotion.
