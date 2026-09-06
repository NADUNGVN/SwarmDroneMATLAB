# EXP23AQ routed state-machine confirmation plan

Frozen: 2026-09-06, before execution of seeds 16095702--16096202.

EXP23AP produced consistent core results on 500 transactions, but its named
implementation-version gate asserted only the routed trace and state-kernel
versions.  It did not assert the continuous-builder version hash.  The run is
retained with scientific status
`SUPERSEDED_BY_CONTINUOUS_VERSION_IDENTITY_AUDIT`; none of its seeds are reused.

EXP23AQ repeats the complete EXP23AP protocol with 500 new normal seeds and one
new isolated fault seed.  All numerical configuration, analytical bounds,
bundle envelopes, time budgets, fault trajectories, and the other 17 gates are
unchanged.  A nineteenth lineage gate requires the explicit superseded marker.
The repaired implementation-version gate now requires exact registered hashes
for the routed trace, routed state kernel, and routed continuous builder.

A pass may validate management relaying in the transaction state machine and
continuous common-PHY schedule.  It still cannot validate plant closed-loop
behavior, repeated renewal, broad robustness, or submission readiness.
