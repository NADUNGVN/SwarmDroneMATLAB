# EXP22E-K: queue-compatible fallback repair results

**Run:** `results/exp22e_elcs_fallback_repair/2026-09-01_174154`  
**Verdict:** `ELCS_F_KERNEL_VALID`  
**Matrix:** 1,400/1,400 rows  
**Gates:** 17/17

The first-eligible-minislot repair satisfies its new randomized gate: the
maximum observed number of fallback attempts per node/frame is exactly one.
All upstream safety and recovery behavior is preserved:

- 200/200 zero-loss rows fully certify;
- zero certified scheduled collision frames, false-valid edge-frames, owner
  lock violations, stale accepts and future accepts;
- 200/200 directed-GRANT blackout clients remain conservatively uncertified;
- 200/200 state-loss rows recover;
- 200/200 forced reconfigurations apply after the fence, terminally recertify,
  and produce 600 automatic recolors; and
- DATA erasure leaves schedule-state hashes unchanged.

The adverse boundary remains visible: local management and directed blackout
produce 400 terminally uncertified rows and 23,262 fallback collision frames.
The repair removes duplicate attempts; it does not claim to solve missing
conflict-edge control visibility.

Passing this kernel gate authorizes only the preregistered EXP22E closed-loop
rerun on seeds `16046001:16046030`. It does not authorize promotion.
