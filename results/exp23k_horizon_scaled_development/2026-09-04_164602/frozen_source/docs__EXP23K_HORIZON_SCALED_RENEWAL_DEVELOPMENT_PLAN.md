# EXP23K — Horizon-scaled renewal development probe

Status: frozen before execution on 2026-09-04.

## Single design change

EXP23J found that 94.34% of cumulative ELCS-W control bytes occur after
bootstrap and that a worst-seed idealized factor of `8.876x` is required for
a 1% cost advantage over periodic. EXP23K applies the smallest conservative
integer factor, `9x`, to the renewal horizon:

- renewal period: `13 -> 117` frames;
- refresh lead: unchanged at `6` frames;
- lease fence: unchanged at `1` frame;
- lease duration: `124` frames, exactly renewal period plus refresh lead and
  fence.

Cumulative same-sequence receipts, witness assignment, slot coloring,
fallback, packet sizes, PHY, guard, clock uncertainty and DATA logic remain
unchanged.

## Data and scope

This probe reuses the 60 EXP23I development seeds and pairs the new candidate
against the already frozen EXP23I periodic and short-horizon cumulative rows.
It is intentionally not fresh promotion evidence: the factor was derived
from these seeds.

## Development gates

The probe is structurally valid only if trace/occupancy pairing closes against
EXP23I, exact replay and accounting close, the declared `9x` configuration is
observed, and causal/protocol invariants hold. It is rejected on any false-
valid, scheduled-collision, safety, divergence or terminal-certification
failure.

The mechanism is promising only if:

1. management airtime is at least 75% below short-horizon cumulative ELCS-W;
2. mean total utilization is at least 1% below periodic TDMA; and
3. RMSE is no more than 1% worse than short-horizon cumulative ELCS-W.

A pass authorizes work on topology-coherence and lease-revocation semantics.
It does not authorize a fixed long-lease claim, method promotion, broad
robustness, or submission.

