# EXP23V — Witness-confirmed reactivation development probe

Status: frozen before execution on 2026-09-04.

EXP23V deliberately reuses the 60 paired seeds from EXP23U to isolate one
mechanism change: the sender may resume after its fresh cumulative incident-
witness transaction closes on a certified union graph, without waiting for
the old lease fence. It runs early (3 s), late (8 s) and early permanent
reacquisition-RESPONSE-blackout arms, for 180 trajectories.

The early and late arms must remain collision-free and reacquire no earlier
than eligibility/fresh-response closure. The blackout arm must remain
suppressed. Exact common-PHY REVOKE mapping, occupancy, replay, packet,
recipient, airtime and causal gates are unchanged. Performance is compared
pairwise to the matching conservative EXP23U arms plus static coherence and
periodic references. A positive result only permits a disjoint fresh-seed
confirmation; it cannot promote the method.
