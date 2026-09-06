# EXP23AN full-detectability routing results

Date: 2026-09-06  
Canonical run: `results/exp23an_full_detectability_routing/2026-09-06_072949`  
Status: `FULL_DETECTABILITY_ROUTING_PRIMITIVE_DIAGNOSTIC_VALID`

## Decision

EXP23AN passes 19/19 frozen gates. The corrected **single-packet physical
multi-hop routing primitive** is valid for the next development stage.

This conclusion supersedes the routing interpretation of EXP23AJ--AM. It does
not alter those stored machine verdicts and does not validate multi-origin or
closed-loop management relaying.

## Evidence

- 210/210 unique structural route rows over N={5,10,20}, both spatial-reuse
  and complete-interference boundaries, every source, and p={0.05,0.20,0.30}.
- Direct-graph diameter and maximum recipient depth are both at most 4.
- Hop-local repetition ranges from 3 to 9 and gives maximum exact logical
  packet failure `8.74513064e-4`; the maximum union upper bound is `8.748e-4`.
- 60,000 new replay trials with seeds 16094801--16094806 match the exact
  multicast probabilities; maximum absolute error is 0.005734 against a
  registered maximum tolerance of 0.025022.
- Independent collision replay reports zero collisions, duplicate forwards,
  future-random reads and receiver-truth reads.
- Integer attempts/bytes and `airtime = 8*bytes/rate` are exact; maximum
  all-node physical cost is 99 transmissions / 9,504 bytes.
- The legacy audit reproduces 30 invalid all-node routes and 5 invalid
  semantic routes. The corrected independent oracle accepts 94/94 routes.
- Full direct-reach detectability adds at most two base slots. The maximum
  semantic single-packet route uses 30 physical transmissions and
  `0.156123480139206 s` reserved duration.
- Logical-clique accounting undercounts by up to 99x; hop-local repetition
  saves up to 264 slots relative to restarting whole floods.

## Scope

Validated: deterministic BFS multicast tree, one-parent duplicate suppression,
full receiver detectability, receiver-conflict coloring, receive-before-forward
causality, hop-local reliability dimensioning, semantic recipients, independent
collision replay and exact physical accounting.

Not validated: simultaneous packets from multiple origins, cross-packet
version isolation, routed delivery driving kernel state, transaction-level
failure after route composition, repeated online renewal, broad robustness,
fresh confirmatory evidence or submission readiness.

## Canonical SHA-256

| Artifact | SHA-256 |
|---|---|
| Registry | `7DC5592322A6CA5571A3F915C7036B2AD56FC598CA7C1D48D1297C0C2331E59D` |
| Structural routes | `00D549EF4B51D24374BEF3D8AC629E50E3DB12E28004C05E401CCE28B3C9FBA3` |
| Monte Carlo replay | `25044360DF7EA32C2168E7EC0FDC15207F15050AE4ACFD5CAAE81CE85CFD7778` |
| Semantic routes | `C4D4AB380EA6DC824769E711E85E15E593EE2DBA95F8338A0A5004D1292E8E6B` |
| Detectability audit | `75D800AA309FA1E0B12E694C19A738B2DE5AA93E98B641F1CBA31F2635C3C197` |
| Gates | `CBADAEEE3A59DEF5F32DA6065C9FC778F80C625593C9AC83651524C0E81D45C3` |
| Verdict | `1510F098162ECE4B1A71ADF881C10D0D87A99C5A1D55136834224305B13ADA3F` |
| Workspace | `946C61D2B12AD235BC44026B0C4FB0B08369FA941EFAA0BDD162686105DBB483` |

## Next action

Develop a multi-origin routed control scheduler. It must schedule atomic
packet-relay tasks jointly, prevent same-sender and receiver-level conflicts,
enforce completion of every parent's repetition block before child forwarding,
preserve packet/version identity, and expose exact per-packet delivery plus
integer PHY accounting. Its first comparator is serial composition of the now
validated single-packet schedules.
