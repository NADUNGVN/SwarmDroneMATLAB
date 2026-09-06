# EXP22H: event-driven discovery and lease renewal

**Frozen after EXP22G and before new randomized outcomes:** 2026-09-01  
**Parent verdict:** `ELCS_EPSILON_DOMINATED_RETURN_TO_DESIGN`  
**Stage:** structural control-plane redesign  
**Closed-loop, robustness, tuning, promotion and submission claims:** prohibited

## Structural repair

The accepted lease/fence/fallback safety kernel remains unchanged. Only the
control emission rule changes:

1. A discovery STATUS is broadcast once per lease horizon (`P_d=L_lease=20`
   frames). It advertises the local tuple but does not request a GRANT.
2. A node that has just acquired/reacquired a tuple or whose minimum lower-edge
   lease is within the existing refresh lead sends a renewal-request STATUS.
3. An owner creates a lock and emits a GRANT only after decoding a STATUS whose
   request bit is set.
4. If a request or GRANT is lost, the uncertified/requesting client retries on
   the next frame. Silence never creates validity.
5. A newly ready node is forced to request on the next frame, preserving the
   ID-inductive acquisition burst instead of waiting one discovery period per
   hop.

Lease length, refresh lead, fence, deterministic control minislots, fixed
coloring, fallback access probability/window/cap, payload sizes, PHY and clock
guard are unchanged.

## Analytical zero-loss control bound

Let `J=L_lease-L_refresh-L_fence=13`, and let `d_i^-` be the number of lower-ID
conflict neighbors of node `i`. Over `F` frames, discovery attempts are at most

`B_disc = N ceil(F/P_d)`.

Each non-root client requests no more than `ceil(F/J)` times, and each decoded
request can cause at most `d_i^-` owner GRANT frames. Hence

`B_ctrl = B_disc + sum_i ceil(F/J)(1+d_i^-)`.

This deliberately loose bound counts coincident discovery/request frames and
aggregated owner grants separately. Every zero-loss row must satisfy it.

## Frozen validation

- Seeds: `16049001:16049100`.
- Same N5/N10 cells and seven conditions as EXP22E-K.
- Same activation-corrected forced reconfiguration.
- All 17 EXP22E-K gates remain.
- Added gates:
  - no GRANT frame is emitted without at least one decoded request;
  - every zero-loss row satisfies `controlAttempts <= B_ctrl`;
  - zero-loss acquisition still certifies by frame `N`;
  - discovery-only and request STATUS counters partition STATUS attempts.

Passing authorizes only fresh-seed continuous closed-loop integration and a
repeat of the targeted periodic kill test. It does not authorize robustness.
