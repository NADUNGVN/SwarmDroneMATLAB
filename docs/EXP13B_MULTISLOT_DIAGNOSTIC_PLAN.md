# EXP13B — Corrective multi-slot MAC diagnostic

**Status:** declared after EXP13 completed and before EXP13B was run.  This is
an openly post-EXP13 diagnostic, not part of the preregistered EXP13 matrix and
not a method-performance experiment.

## Why this diagnostic exists

EXP13 used the declared 48-byte DATA frame, 1-Mbit/s abstract PHY and 1-ms
slot.  The resulting airtime is 0.384 ms and therefore every DATA occupies one
discrete slot.  ACK summaries also remain one slot in the observed N=5 cells.
Consequently, p-persistent CSMA and slotted ALOHA have identical action
semantics: no frame remains active into a later slot where carrier sensing
could suppress a new start.  EXP13 correctly passed its preregistered gates,
but its ALOHA reference cannot distinguish MAC behavior.

EXP13B preserves that negative result and asks only whether the kernel produces
the expected distinction once frames span several slots.

## Fixed matrix

- development seeds: `13013001:13013004` (no new seed selection);
- Moderate residual loss 0.1, N=5, T=12 s;
- methods: Periodic-P10 and default Causal-Broadcast;
- access probabilities: `[0.1, 0.2, 0.4]`;
- MAC: p-persistent CSMA and slotted ALOHA;
- calibration A: EXP13 one-slot parameters (48 B, 1 Mbit/s);
- calibration B: declared multi-slot stress parameters (96 B DATA, 16 B ACK
  base, 8 B per ACK entry, 250 kbit/s).

At calibration B, a bare DATA occupies four 1-ms slots and an ACK with at least
three entries occupies at least two slots.  These values are an abstract stress
calibration, not claimed hardware measurements.

## Gates

1. 96 declared runs are present.
2. One-slot CSMA and ALOHA remain bit-identical on all logged outcome metrics.
3. Multi-slot service spans at least four slots for DATA.
4. Multi-slot CSMA and ALOHA differ in at least one paired physical outcome.
5. All protocol invariants, memory bounds and accounting identities hold.
6. One absolute trace hash is shared by every cell of a seed.

Passing EXP13B permits retaining both CSMA and ALOHA in later OOD validation.
It does not choose a MAC, tune a policy or permit a superiority claim.
