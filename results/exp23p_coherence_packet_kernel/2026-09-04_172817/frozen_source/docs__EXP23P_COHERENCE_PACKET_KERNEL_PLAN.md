# EXP23P — Coherence-aware ELCS-W packet-kernel falsification

Status: frozen before fresh-seed execution on 2026-09-04.

## Frozen matrix

- 50 fresh seeds `16077001:16077050`, disjoint from EXP23L/M/O.
- N=5 and N=10.
- Static/wide-low, mobile/limited-low and mobile/limited-high geometry cells.
- Six channel cells: zero loss, CLAIM IID 5%, RESPONSE IID 5%, joint control
  IID 5%, shared IID occupancy 15%, and directed permanent RESPONSE blackout.
- 1,800 packet-kernel rows.

Each geometry realization constructs an initial intended-receiver graph at
1.5 m, selects a receiver-lifted coherence horizon, and binds the exact
charged format: 28-byte CLAIM, 16-byte RESPONSE header, 10-byte horizon entry,
24-byte REVOKE and 96-byte MTU. No-lease or too-short-horizon decisions are
explicitly inadmissible and may use only fallback DATA.

## Gates

The matrix must pair base geometry and absolute channel draws across channel
conditions; selected broadcast graphs must retain witness/MTU/slot
feasibility; every transmitted packet must fit the declared MTU and byte
accounting must close; cumulative same-sequence retry must be active; admitted
non-blackout rows must terminate certified; inadmissible rows must have zero
CLAIM, RESPONSE and scheduled attempts; permanent RESPONSE blackout must
prevent complete certification without false validity; and every row must
have zero false-valid and scheduled-collision frames, zero unsupported
certificates, bounded control effort and zero forbidden information reads.

All max-horizon, contracted-horizon, binding-rejected and no-lease branches
must be stimulated. A pass permits common-PHY closed-loop integration of the
static admissible branch and implementation of dynamic self-revocation. It
does not establish dynamic closed-loop safety or promote the method.

