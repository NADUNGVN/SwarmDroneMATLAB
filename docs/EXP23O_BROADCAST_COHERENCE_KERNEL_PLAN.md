# EXP23O — Receiver-lifted broadcast coherence-kernel validation

Status: frozen before fresh-seed execution on 2026-09-04.

## Motivation

An integration fixture falsified direct use of EXP23M's pairwise transmitter
graph: with broadcast recipients, distant senders can collide at a third
receiver. EXP23O validates the corrected two-stage construction. Reachable
tubes produce a potential physical-interference graph, which is lifted through
the intended-receiver graph into a sender-conflict supergraph.

## Frozen matrix

- 100 fresh seeds `16076001:16076100`, disjoint from EXP23L/M.
- N=5 and N=10.
- Static/wide-low, mobile/limited-low and mobile/limited-high conditions as
  in EXP23M.
- Fixed intended-receiver graph per base realization: symmetric links within
  1.5 m at certificate time.
- Candidate horizons `[0.25, 0.5, 1, 2, 4, 6.8]` s.
- 600 rows, 41 actual-motion samples per horizon.

The static condition provides maximum-horizon positive control. Mobile cells
retain limited management reach, hidden sender conflicts, horizon contraction
and no-lease pressure.

## Gates

For every sample, the actual receiver-lifted sender-conflict graph must be a
subset of the certified broadcast supergraph and no actual conflict may share
a color. Every selected conflict edge must have a valid local witness and fit
the 96-byte packet. At least one hidden sender conflict, maximum horizon,
contracted horizon and no-lease outcome must occur. Higher uncertainty may
never lengthen the selected horizon. Determinism, monotonicity,
self-revocation and causal-information gates from EXP23M remain.

A pass permits receiver-lifted coherence configuration to enter ELCS-W packet
kernel validation. It does not establish closed-loop performance or promote
the method.

