# EXP23AI integer-PHY accounting results

Canonical run: `results/exp23ai_integer_phy_accounting/2026-09-06_003132`

Status: **INTEGER_ACCOUNTED_RADIAL_CLOSURE_FRESH_VALID**

## Decision

EXP23AI passed 28/28 preregistered gates on all 300 rows (50 untouched seeds
times six paired arms). It validates one causal online receiver-lifted closure
transaction under the frozen IID-20 common-PHY model, including the radial
non-edge theorem, finite-retry reliability certificate, blackout fail-silent
semantics, parallel protected DATA service, affine clocks, exact receiver
replay, and integer management accounting.

This result does not relabel the failed EXP23AF, EXP23AG or EXP23AH runs. It
does not validate routed multi-hop management, repeated online renewal, broad
network/topology robustness, or submission readiness. The verdict therefore
keeps all four downstream flags false.

## Registered evidence

- Matrix: 300/300 unique rows; seeds 16094401--16094450 were disjoint from all
  design and calibration sets.
- Online causality: identical decision state and pre-PREPARE schedule prefix
  across closure arms for every seed; zero future-random and receiver-truth
  reads.
- Nonvacuous topology change: every seed had at least one changed
  receiver-lifted sender edge not incident on commanded node 2; affected set
  size was 3--4 and every candidate changed at least one slot.
- Transaction reliability: the per-geometry union failure upper bound was at
  most `0.000760320524288`; normal closure completed in 50/50 runs.
- Protected geometry: 200/200 protected closure rows satisfied the radial
  contraction theorem. Maximum inward-contraction ratio was `0.980655494`,
  leaving only 1.93% relative headroom; minimum omitted-edge physical margin
  was `0.131280 m`.
- Realized graph safety: physical and receiver-lifted sender graphs were
  subsets of their certificates in every protected row. Kernel, receiver and
  observed collision counts were all zero.
- Closed-loop safety: zero protected failures/divergences; minimum protected
  separation was `0.996960 m`.
- Accounting: observed integer management bytes equaled scheduled and kernel
  bytes exactly. Maximum per-run management traffic was 13,034 bytes, and
  both runtime and expected airtime equaled `8*bytes/250000` exactly.
- Receiver replay: every DATA success/erasure count matched its registered
  schedule, with zero queue skips and zero control/DATA overlaps.

## Mechanism-negative comparison

Under RESPONSE blackout, removing protected emergency service violated the
radial contract in 50/50 paired seeds (minimum violation ratio `5.930`) and
increased mission RMSE by `0.227599 m` on average; every paired delta was
positive (`0.184728` to `0.257715 m`). It reduced total offered cost by
`0.033400`, so the result is a safety/performance-versus-airtime tradeoff, not
a free Pareto improvement.

Normal protected closure also traded accuracy for cost relative to the frozen
periodic arm: mean mission RMSE was higher by `0.038142 m`, while mean total
cost was lower by `0.103225`. These descriptive results forbid a general
superiority claim.

## Immediate research consequence

The single-transaction online integration gap is closed under the registered
model. The closest technical risks are now:

1. the radial margin is narrow (1.93%), so repeated causal renewal or local
   revocation is needed before longer missions/disturbance robustness;
2. management reach is still a full logical matrix, not routed over the
   two-hop wireless graph;
3. robustness across swarm size, command direction/magnitude, channel memory,
   external load and topology is not yet confirmed;
4. prior-art performance comparisons remain separate from this new closure
   mechanism and must be reintegrated only after routing/renewal are valid.

The next registered mechanism study is therefore routed multi-hop management,
followed by repeated online renewal. No manuscript-building gate is opened.

## SHA-256 manifest

- `integer_accounting_registry.json`:
  `0EFEF873A0806BA9A6C9143F4CD110CDDE083FC8E0BCDBBADCC58F99D7F84A70`
- `trajectory_tidy.csv`:
  `36136A4C10C5B256A90488BE13DCCB391FCCF4FAFDE60E157B0F46BEED438434`
- `summary.csv`:
  `C20DCB54F5B79C1C9DEC8CE5DB77CC2C44D25ED266AF3A80E27B87DAED241838`
- `paired_contrasts.csv`:
  `016EF23FEC793415D3AB9DB6B8491F7E655535BD84BF71CF29737E3625E42CA2`
- `validation_gates.csv`:
  `C756A9DEF8CD0918CE2B16111D019CB03B37D0EA36A0129D72E3FC1BDF7E1222`
- `integer_accounting_verdict.json`:
  `E435D4D3C1322DCAD1371E912EA4D1B19BB9F114B29CE403F329D1425CC45C20`
- `workspace.mat`:
  `94166D1E90FA7EF872B27BF0279509153E282E55837F3D44A3C297FFF4B03F92`
