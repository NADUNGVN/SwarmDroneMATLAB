# EXP22-K: ELCS-F kernel falsification

**Frozen before randomized outcomes:** 2026-09-01  
**Deterministic contracts:** 12/12  
**Stage:** candidate safety-kernel falsification  
**Tuning, closed-loop claims, promotion and submission claims:** prohibited

## Matrix

The matrix contains 100 fresh seeds, the accepted N5 6-DOF and N10 ring2
graphs, and seven conditions: zero loss, 5% DATA erasure, 5% management
erasure, management reach restricted to the DATA graph, complete loss of the
lexicographically first owner-to-client GRANT direction, client state loss at
frame 200, and owner tuple reconfiguration requested at frame 200. Total:
1,400 kernel runs.

All conditions reuse absolute STATUS-slot, GRANT-slot, delivery, fallback
access and DATA arrays. The directed-GRANT blackout is an explicit projection:
STATUS and all other GRANT draws are set to success while the selected GRANT
direction is erased, so it is a deterministic final-message-loss witness.

The untuned implementation uses fixed `L=N`, `N` STATUS minislots, `N` GRANT
minislots, two fallback minislots, a 20-frame lease, six-frame refresh lead,
one-frame lease fence, STATUS period two, and fallback access `1/N`.

## Gates

The run is valid only if:

1. all 1,400 unique rows and exact seed/cell/condition coverage are present;
2. base absolute trace hashes are paired within every seed/cell;
3. zero-loss and DATA-erasure conditions have identical schedule-state hashes;
4. every zero-loss row reaches full certification;
5. every scheduled region is collision-free in every condition;
6. false-valid edge-frames, owner-lock violations, stale accepts and future
   accepts are zero in every condition;
7. the directed blackout retains an attempted owner lock while the selected
   client cannot obtain that lease;
8. every state-loss row recovers through the normal lease path;
9. every reconfiguration is applied strictly after its release fence;
10. management, scheduled DATA and fallback DATA recipient partitions close;
11. offered utilization is no smaller than busy-union utilization;
12. future-random and receiver-truth decision reads are zero; and
13. all nonconvergence and fallback/collision outcomes are retained.

There is deliberately no requirement that local-management, control-loss or
blackout rows finish fully certified. Their valid negative outcome is bounded
conservatism/fallback without false scheduled validity. No parameter is
selected from EXP22-K.
