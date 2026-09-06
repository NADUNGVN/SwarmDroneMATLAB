# EXP23S — Dynamic self-revocation kernel results

Run: `results/exp23s_dynamic_revocation_kernel/2026-09-04_180028`

Status: **DYNAMIC_COHERENCE_REVOCATION_KERNEL_VALID (25/25 gates)**.

All 800/800 unique fresh-seed rows reached positive scheduled state before
the injected event and executed exactly one charged 24-byte REVOKE. The
revoker suppressed itself in the event frame and throughout every
outside-supergraph edge interval. There were zero scheduled-collision and
zero false-valid edge frames across the full matrix.

All 600 non-blackout rows reacquired with the incremented tuple only after
the captured old fence. All 200 permanent reacquisition-RESPONSE-blackout
rows remained suppressed. Delivered and lost REVOKE pairs had identical
local suppression and scheduled-reuse histories. Joint-loss rows stimulated
both cumulative CLAIM retry and REVOKE erasure. Attempt, byte, recipient, MTU
and absolute-bound accounting closed exactly.

This validates dynamic self-revocation/reacquisition while the certified
supergraph and color map remain fixed. Online graph reselection and color
migration remain unvalidated.
