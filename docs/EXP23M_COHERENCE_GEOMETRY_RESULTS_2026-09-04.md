# EXP23M — Valid coherence geometry-kernel results

Run: `results/exp23m_coherence_geometry_stimulus_repair/2026-09-04_170157`

Status: **`COHERENCE_GEOMETRY_KERNEL_VALID`**.

Scope correction after broadcast-integration falsification: this valid result
certifies pairwise physical-interference geometry only. It does not by itself
certify the receiver-lifted broadcast sender-conflict graph. The latter
requires separate validation before packet integration.

## Integrity and coverage

- 100 fresh seeds, N5/N10 and three conditions: 600/600 unique rows.
- Registry hash `106670224` over 48 leaves.
- All 16/16 validation gates passed.
- Base positions and random motion/error directions pair across conditions.
- Deterministic replay of a repeated seed/cell is bit-identical.

## Mathematical safety checks

Across all requested horizons and 41 time samples per horizon:

- zero actual-conflict edges fell outside the reachable-tube supergraph;
- zero actual-conflict edges shared a supergraph color;
- zero potential edges disappeared as the requested horizon grew;
- higher causal state uncertainty never lengthened the paired selected
  horizon;
- every issued horizon had complete witness cover, single-packet response fit
  and enough DATA slots;
- every injected acceleration-bound violation triggered local self-revocation,
  while bounded motion produced no false self-revocation;
- zero future-random and receiver-truth decision reads were reported.

## Non-vacuous selector boundary

The repaired matrix exercises all three intended branches:

- target 6.8 s horizon: `200` rows;
- contracted positive horizon: `331` rows;
- no positive lease: `69` rows.

Every static/wide-reach row selects 6.8 s (`200/200`). Under mobile limited
reach, mean selected horizons are:

| N | Low uncertainty | High uncertainty | High-uncertainty no-lease rate |
|---:|---:|---:|---:|
| 5 | `1.3000` s | `0.6125` s | `18%` |
| 10 | `0.8900` s | `0.2175` s | `51%` |

This is an important operating boundary: coherence certification preserves
safety by shortening or refusing leases, so the communication-cost advantage
seen in static EXP23K cannot be assumed under fast motion, stale state and
limited management visibility.

## Decision

The reachable-supergraph, horizon-selection and self-revocation layer may be
integrated into the distributed ELCS-W packet kernel. The valid geometry result
does not establish packet-level liveness during graph change, revocation byte
cost, reacquisition delay or closed-loop performance. Those are the next
falsification gates; no method-promotion or submission claim is authorized.
