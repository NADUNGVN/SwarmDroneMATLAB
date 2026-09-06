# EXP23J — ELCS-W control-overhead floor audit

Status: frozen posthoc diagnostic after valid EXP23I and before inspecting
per-packet overhead decomposition.

## Purpose

EXP23I established that cumulative receipts remove retry amplification but
leave cumulative ELCS-W 7.96% more expensive than periodic TDMA at the
N5/IID-15% decision cell. Because RMSE separation is only 0.00762 percentage
points beyond the 1% boundary, the next design must create cost headroom
rather than rely on that boundary.

EXP23J reconstructs the frozen cumulative schedules for the 60 EXP23I seeds
and decomposes physical-horizon control airtime. It is diagnostic reuse of
development seeds, not fresh confirmation evidence.

## Frozen decomposition

For every seed, physical control bytes are partitioned exactly into:

- CLAIM and RESPONSE bytes;
- RESPONSE header and certificate-entry bytes;
- bootstrap bytes through the first all-certified frame and steady-state
  renewal bytes afterward;
- nominal and retry CLAIM bytes.

The audit reports four counterfactual lower bounds without claiming that a
protocol already achieves them:

1. no-control floor: DATA and ACK airtime only;
2. claim-free floor: all standalone CLAIM bytes removed;
3. shared-header floor: CLAIM bytes and RESPONSE headers have zero marginal
   airtime, but certificate entries remain charged;
4. bootstrap-only floor: all post-certification renewal control has zero
   marginal airtime while bootstrap remains fully charged.

## Decision logic

- If the bootstrap-only floor is not cheaper than periodic, renewal redesign
  cannot close the gap without changing DATA service.
- If the shared-header floor is not cheaper than periodic, packet aggregation
  that removes only standalone headers is insufficient.
- If bootstrap-only is cheaper and steady-state renewal contains at least the
  required removal fraction, an in-band or longer-horizon renewal mechanism
  has theoretical headroom and may advance to a new kernel design.

All floors are oracle diagnostics. No result promotes a method, establishes
robustness, or authorizes a submission claim.

