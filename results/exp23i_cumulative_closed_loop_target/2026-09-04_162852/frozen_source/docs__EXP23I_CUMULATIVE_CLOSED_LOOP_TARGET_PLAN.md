# EXP23I — Targeted cumulative-receipt closed-loop falsification

Status: frozen before fresh-seed execution on 2026-09-04.

## Question

Valid EXP23G rejected legacy ELCS-W at N5 under 15% IID exogenous
occupancy: periodic TDMA was 11.61% cheaper while its RMSE penalty was only
0.86%, inside the frozen 1% epsilon band. Valid EXP23H then isolated and
repaired same-frame ACK fragmentation at the protocol-kernel level.

EXP23I asks one targeted question: does the cumulative-receipt repair remove
enough management amplification in the closed loop to escape that exact
periodic epsilon-dominance failure?

## Frozen design

- 60 fresh seeds `16072001:16072060`, disjoint from EXP23G and EXP23H.
- One decision cell: N5 6-DOF, shared IID occupancy 15%.
- Three arms on the same channel, clock and occupancy realization:
  periodic TDMA at the EXP23D lower-cost boundary, legacy ELCS-W, and
  cumulative-receipt ELCS-W.
- 180 trajectories in total.
- No threshold, topology, PHY, guard, formation or access-parameter tuning.

The only difference between the two ELCS-W arms is receipt state: the
cumulative arm retransmits the current CLAIM sequence and retains exact
per-edge witness receipts until the renewal transaction is complete.

## Integrity and safety gates

The run requires an exact unique matrix; absolute realization pairing;
correct retry-mode declarations; shared-background and clock composition;
one-hop witness coverage; exact variable-payload replay/accounting; causal
information use; absolute control-effort bounds; zero false-valid and
scheduled-collision frames; and terminal certification in all ELCS-W rows.

All failures are retained. An integrity failure invalidates the study; a
safety or terminal-liveness failure rejects the cumulative candidate.

## Frozen decision rule

The redesign mechanism is considered active only if cumulative ELCS-W:

1. reduces mean management airtime by at least 15% relative to legacy
   ELCS-W; and
2. has a paired 95% bootstrap interval for cumulative-minus-legacy
   management airtime strictly below zero.

It escapes the prior performance failure only if periodic TDMA does not
epsilon-dominate cumulative ELCS-W under the same frozen rule used in
EXP23G: periodic RMSE no more than 1% above the candidate and periodic cost
at least 1% below it.

A valid pass authorizes a fresh full background matrix. It does not establish
broad robustness, promote the method, or authorize a submission claim.

