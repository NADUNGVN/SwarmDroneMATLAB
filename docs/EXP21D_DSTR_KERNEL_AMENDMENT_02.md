# EXP21D-K amendment 02 — evidence timeout, backoff, and absolute traces

**Date:** 2026-09-01

**Trigger:** retained registered v1 run
`results/exp21d_dstr_kernel_conformance/2026-09-01_055220`.

## Retained v1 result

The run completed all 800 declared rows and passed 15 of 17 integrity and
scope gates, but failed both native mechanism gates:

- only 194/200 native rows ended Resolved and physically valid; and
- only 189/200 native rows converged without unused slots.

Its verdict remains `DSTR_KERNEL_INVALID_NO_CLOSED_LOOP`.  No v1 output is
relabelled or overwritten.

## Root-cause corrections

Source-level replay of the six resolution failures and eleven convergence
failures identified three implementation faults.

1. **Missing implicit evidence waited forever.**  Section 4.2 says an
   Assignment UAV transmits in different slots until success, and Section 4.5
   says it self-allocates again unless all known neighbors report success.
   V1 instead held a collided claim indefinitely when no record returned.
   V2 treats the absence of complete fresh success from already-known
   reporters after one full superframe as a failed Assignment attempt.  This
   is a causal timeout, not a fabricated receiver outcome.  Neighbors never
   discovered remain unknown, preserving the source's temporary-acceptance
   boundary.

2. **The exponential window excluded its upper endpoint.**  The published
   NACK-only window is `[0, 2^min(s,S)-1]`, containing `2^min(s,S)` choices.
   V1 generated only `2^min(s,S)-1` choices and made the first retry always
   zero.  V2 draws from the correct number of choices and declares a cap of
   six exponent stages.

3. **Trace arrays were paired but not horizon-prefix invariant.**  V1 drew
   whole multidimensional arrays sequentially, so increasing `maxFrames`
   changed series belonging to later nodes/links.  V2 assigns a fixed
   `mrg32k3a` substream to every draw type and node/link/management-slot tuple.
   A new deterministic contract verifies that a 17-frame trace equals the
   prefix of its 23-frame continuation exactly.

## V2 confirmation boundary

The v1 seed range was inspected during diagnosis.  V2 therefore does not
rescore it as confirmation and uses the fresh range
`16034001:16034100`, retaining the same two sizes, four conditions, 200-frame
horizon, and native gates.  Contract count increases from 14 to 15.  If v2
fails, its failed rows remain visible and closed-loop integration remains
forbidden.
