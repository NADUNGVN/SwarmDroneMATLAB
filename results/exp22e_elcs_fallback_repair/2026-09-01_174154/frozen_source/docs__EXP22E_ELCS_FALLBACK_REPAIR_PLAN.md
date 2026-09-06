# EXP22E: ELCS-F queue-compatible fallback repair

**Frozen after retained invalid EXP22D and before new outcomes:** 2026-09-01  
**Parent invalid run:** EXP22D `2026-09-01_173320`, 14/17 gates  
**Tuning, promotion and submission claims:** prohibited

## Structural change

For each uncertified node and ELCS frame, scan the same `W` frozen fallback
draws in minislot order and transmit at the first draw no larger than `p`.
After that attempt, the node is ineligible for the remaining fallback
minislots of the frame.

Thus

`sum_w I{node n attempts in fallback slot w of frame k} <= 1`.

The probability that an invalid node receives some fallback attempt in a
frame remains `1-(1-p)^W`; only duplicate attempts using the same latest state
are removed. STATUS, GRANT, leases, fences, priority coloring, control-window
size, scheduled DATA region, `p`, `W`, PHY sizes and guard are unchanged.

## Stage K: kernel regression

- Seeds: `16045001:16045100`.
- Same two cells and seven conditions as EXP22C.
- Same activation-corrected reconfiguration witness.
- All 16 EXP22C gates remain unchanged.
- Added deterministic contract: no frame/node has more than one fallback
  attempt, including retained EXP22D witnesses.

Passing Stage K authorizes only a fresh closed-loop rerun.

## Stage CL: closed-loop rerun

If Stage K passes, repeat the exact EXP22D matrix on seeds
`16046001:16046030`. All 17 EXP22D gates remain unchanged. In particular,
empty-queue skips and physical outcome mismatches must be zero; neither is
reclassified as benign after seeing the invalid result.

No performance threshold is introduced. Passing both stages authorizes the
next robustness experiment, not promotion.
