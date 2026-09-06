# EXP23O — Receiver-lifted broadcast coherence results

Run: `results/exp23o_broadcast_coherence_kernel/2026-09-04_172147`

Status: **`BROADCAST_COHERENCE_KERNEL_VALID`**.

## Integrity and safety

- 100 fresh seeds, N5/N10 and three conditions: 600/600 unique rows.
- Registry hash `114879144` over 51 leaves.
- All 17/17 frozen gates passed.
- Base motion and intended-receiver graphs pair across uncertainty arms;
  repeated seed/cell execution is bit-identical.
- Across all horizon/time samples, zero actual receiver-lifted sender
  conflicts fell outside the certified supergraph and zero actual conflicts
  shared a color.
- Sender-conflict graphs grew monotonically with horizon and high uncertainty
  never lengthened a paired mobile horizon.
- Every issued horizon had witness-cover, MTU and color feasibility; uncovered
  cases issued no lease.
- Self-revocation and causal-information contracts passed.

## Non-vacuous broadcast stimulus

- Aggregate hidden sender-conflict instances: `17,040`.
- Target 6.8 s horizon: `250` rows.
- Contracted positive horizon: `295` rows.
- No lease: `55` rows.
- Static/wide positive control: 200/200 rows select 6.8 s.

The receiver lift is materially different from pairwise sender distance: it
adds conflicts caused at intended receivers, including distant hidden
transmitters. This closes the broadcast-model flaw exposed by the first ELCS-W
integration fixture.

## Decision

The receiver-lifted potential-conflict supergraph may enter packet-kernel
validation. The next study must charge the 28-byte CLAIM and 10-byte horizon
entry, exercise cumulative retry under control loss/occupancy, keep no-lease
rows fallback-only, and fail silent under a permanent missing witness
response. No closed-loop or promotion claim follows from EXP23O.

