# EXP23AD receiver-lifted dependency-closure kernel result

Date: 2026-09-05  
Canonical result: `results/exp23ad_receiver_lifted_closure_kernel/2026-09-05_081510`  
Status: `RECEIVER_LIFTED_CLOSURE_KERNEL_VALID`

## Decision

All 24 frozen gates pass over 2,400 kernel rows. The dependency closure repairs the theorem defect exposed by EXP23AC at the packet-state-machine level. Common-PHY mapping is now permitted; closed-loop, online plant-coupling, and submission claims remain prohibited.

## Coverage and result

- N={5,10,20}, 100 new seeds per N, eight conditions.
- Every fixture changes physical relations incident to one moving receiver but creates sender-conflict edges that do not contain the initiator.
- Closure size varies from 3 to 6 nodes; every joint union coloring is proper and forces at least one slot change.
- All 300 zero-erasure rows close the quiescence barrier, authorize next-frame motion, and fully reactivate.
- All 300 IID-20 rows fully reactivate. The aggregate 95% Wilson lower bound is 0.9874, above the frozen 0.95 gate.
- Every PREPARE-blackout and QUIESCENT-blackout row blocks motion authorization.
- Every RESPONSE-blackout row authorizes the already-quiesced graph change but retains the full affected set in scheduled silence.
- Every COMMIT-blackout row reactivates only the initiator; the remaining affected nodes stay suppressed, with zero collision.
- REVOKE-blackout and nominal state histories are exact matches.
- Every supported row is collision-free.
- The deliberately incomplete union is rejected in all 300 rows and produces 53 collision frames per row, demonstrating a non-vacuous oracle.
- Attempt, byte, airtime, recipient, hard-budget, and causal-read contracts all pass.

## Cost boundary visible at kernel level

Control overhead scales with closure size. In N=10 and N=20 fixtures, nominal transactions average 18 packets / 685 bytes; IID-20 averages about 32 packets / 1.4 kB. A permanent RESPONSE blackout reaches 89 packets / 4.392 kB. This is not yet total common-PHY cost and cannot be compared with periodic DATA until the next integration.

## Scope

- `developmentOnly=true`.
- `closedLoopClaimPermitted=false`.
- `submissionClaimPermitted=false`.
- The quiescence theorem applies to gateable commanded motion; uncontrolled old-tube violation remains a separate boundary.

## Canonical SHA-256

| Artifact | SHA-256 |
|---|---|
| `kernel_tidy.csv` | `3ADC96BD33A5255A04F1754BD088EC930B6821BEE1BD51BD9E1DC1C64BD3277F` |
| `summary.csv` | `0100A74597D921145E9DA7AD675FB857D79356813DC49C04EA73A564FB4FF052` |
| `validation_gates.csv` | `36B0A2ED7AC25F04ECBE7B28A491FCB8B9624526C431E6564969E5587E842B5A` |
| `closure_kernel_verdict.json` | `D31F708FEEB94CEB15F73D4C5EF4364088D5A8730D00D2972E37759B591F2ED4` |

