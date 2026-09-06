# EXP23AO multi-origin routed-control result ledger

Canonical run: `results/exp23ao_multi_origin_routing/2026-09-06_075633`

Status: `MULTI_ORIGIN_ROUTED_CONTROL_DIAGNOSTIC_VALID` (16/16 frozen
validation gates).

## Result

The retained N=10 online migration contains five phase bundles with logical /
routed packet counts 1/1 PREPARE, 3/3 QUIESCENT, 10/10 EVIDENCE, 10/9 RESPONSE
(one response is local-only), and 1/1 COMMIT.  At four hop-local repetitions,
the multi-origin scheduler is precedence-safe and independently collision-free.
It reduces the largest serial incumbents by 20 slots and admits at most two
simultaneous transmitter tasks.  No-loss replay delivers every routed packet
with exact integer byte and derived-airtime accounting.

The 25,000 registered random replays contain zero collision, accounting,
attempt-bound, forbidden-read, or cross-packet-state violations.  Empirical
all-packet failure agrees with the exact independent-erasure certificate for
all five bundles.  The largest bundle is EVIDENCE: exact attempt failure
0.0798942 and empirical failure 392/5000 = 0.0784.

The complete uniform repetition frontier preserves two negative boundaries:

- r=1 cannot reach transaction failure below 1e-3 in the registered outer
  retry ranges;
- r=2 reaches the reliability target but needs 6.953507 s, exceeding the
  6.5 s post-request budget.

The minimum conservative feasible point is r=4, with three PREPARE attempts,
four CLAIM opportunities split into two evidence-prefix and two
response-suffix opportunities, two COMMIT attempts, and 11 phase indices.  Its
transaction failure upper bound is 0.000909554397 and its conservative time is
5.034618441 s.  Thus it has 1.465381559 s of registered time headroom.

## Scope

This closes the multi-origin common-PHY routing primitive and cross-layer retry
allocation only.  It does not yet validate management relaying in the actual
closure state machine, plant-driven closed loop, repeated online renewal,
fresh-seed evidence, robustness, or a submission claim.  The next experiment
must make routed bundle delivery drive the closure kernel and continuous shared
medium rather than treating routing as an external diagnostic.

## SHA-256

- `multi_origin_registry.json`: `DDE31212AC4389A4BC9D846FD5156A65D69FF7ACF874111023C256160F2D5845`
- `bundle_schedules.csv`: `81C0D67070104876FBA4462D25555914AD6B2CAE35BB9541259173C7F21352FA`
- `uniform_retry_frontier.csv`: `E05684C94D0DEF301501E193EF853A48780A43D09F23C74DE615EE83E8BE30A2`
- `multi_origin_monte_carlo.csv`: `419C0E1985612DB6E2EF0095620ADCFE749A0E24563096F0E017B0F234D39EA5`
- `selected_transaction_certificate.json`: `6244ED308C92E8DA5C85A95A48ED94AF0D12ED3D0FE327831D13FD0CC23A1806`
- `validation_gates.csv`: `601DF3BF5EC7FC1CC0AB21ACD4E6A1885435307D95504A749DDC709C1120FFE5`
- `multi_origin_verdict.json`: `FB3F2FF3D6E199A2F4D8C46BC7F844A48DB395D10ED1B094AF977E089A09C5D6`
- `workspace.mat`: `0EE7FA4D7E7B899D69E51ACA9D71680FFDB276BC548D0CFDC671C42D8D00A27B`
