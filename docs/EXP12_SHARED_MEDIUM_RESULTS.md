# EXP12 — Shared-medium infrastructure result

## 1. Verdict and scope

EXP12 is **PASS (14/14 infrastructure gates)** on the recorded run:

`results/exp12_shared_medium_diagnostic/2026-08-29_104600`

This result establishes that the formation controller, causal broadcast
policy, finite queues, shared DATA/ACK channel, receiver-specific collision,
aggregated feedback and metric accounting execute together under one
deterministic trace contract. It does not establish that Causal-Broadcast is
better than a baseline. `verdict.json` therefore fixes
`policyClaimPermitted=false`.

The matrix uses only three development seeds (`12012001:12012003`), not the
future holdout family:

- `N=5`, 12 s double-integrator mission, ring communication topology;
- one fully-conflicting interference domain;
- p-persistent CSMA with `p={0.1,0.2,0.4,1}`;
- residual receiver loss `{0,0.1,0.3}`;
- Periodic-P10, State-event and Causal-Broadcast semantics;
- 3 seeds x 3 loss regimes x 4 p values x 3 methods = 108 runs.

The analytical primary remains `p=1/(c+1)=1/5` for `c=4`. The other p values
are sensitivity arms. EXP12 did not tune thresholds or select a policy point.

## 2. Executed evidence

Before the matrix, the runner executed 38 deterministic checks:

- 23 kernel checks: one-to-many/partial reception, collision domain,
  serialization/spatial reuse, finite queue, latest-generated-wins, bounded
  retry/history, preservation of piggyback feedback across queue replacement,
  cumulative/piggyback/deadline ACK, inline delivery, causality, trace
  determinism, airtime identity and zero-load equivalence;
- 7 Causal-Broadcast branch checks;
- 8 end-to-end formation/MAC checks.

The 108-run matrix then passed all machine-readable gates:

1. all micro-contracts pass;
2. zero causal invariant violations;
3. sender-confirmed age is conservative wherever that belief exists;
4. finite control/freshness outputs in every cell;
5. queue depth never exceeds 4 (observed maximum 2);
6. sender history never exceeds 32 (the ring reaches and wraps at 32);
7. recipient success/loss accounting closes exactly;
8. busy-time union does not exceed offered airtime or the horizon;
9. synchronized Periodic-P10 at `p=1` collapses as declared;
10. the analytical tagged access term has its unique tested-grid maximum at
    `p=0.2`;
11. every `p<1` run delivers DATA;
12. one absolute trace hash is shared across every cell of a seed;
13. only Causal-Broadcast generates feedback and every `p<1` causal cell
    confirms ACK entries;
14. unique delivered logical frames never exceed generated frames.

The first complete run (`092028`) was superseded after a queue-semantics audit:
a DATA frame carrying piggyback feedback could be replaced before service,
silently losing its ACK obligations. The corrected admission rule transfers
those entries to the newer DATA frame or to a priority standalone ACK. Two
deterministic gates now lock both paths. In the final matrix, 78 entries are
transferred in 10/108 cells. The repair changes those causal cells, with a
maximum absolute RMSE change of 0.00123 m and maximum mean-true-AoI change of
0.00426 s; all 14 gates and the total separation-failure count remain
unchanged. This supersession is retained rather than described as a
reporting-only change.

## 3. Development observations — not claims

The following means pool the three loss regimes and three development seeds.
They are diagnostics, not inferential comparisons.

| p | Method | RMSE [m] | True AoI [s] | Confirmed age [s] | DATA frame goodput [Hz] | Collision rate | Channel utilization |
|---:|---|---:|---:|---:|---:|---:|---:|
| 0.1 | Periodic-P10 | 0.0563 | 0.0816 | N/A | 48.44 | 0.207 | 0.056 |
| 0.2 | Periodic-P10 | 0.0594 | 0.0839 | N/A | 46.49 | 0.385 | 0.062 |
| 0.4 | Periodic-P10 | 0.0916 | 0.1313 | N/A | 34.05 | 0.701 | 0.068 |
| 1.0 | Periodic-P10 | 1.7372 | 10.0000 | N/A | 0.00 | 1.000 | 0.030 |
| 0.1 | Causal-Broadcast | 0.0571 | 0.0825 | 0.1259 | 52.54 | 0.100 | 0.105 |
| 0.2 | Causal-Broadcast | 0.0546 | 0.0790 | 0.1216 | 51.60 | 0.147 | 0.106 |
| 0.4 | Causal-Broadcast | 0.0552 | 0.0777 | 0.1292 | 52.82 | 0.309 | 0.113 |
| 1.0 | Causal-Broadcast | 0.3755 | 0.6378 | 3.6577 | 12.86 | 0.944 | 0.108 |

Important interpretations:

- `theta(p)=p(1-p)^4` equals `{0.06561,0.08192,0.05184,0}` at the tested p
  values, so the one-opportunity worst-case bound is maximized at 0.2.
  Periodic-P10 nevertheless has higher empirical goodput at 0.1 than 0.2 in
  this unsaturated finite-queue workload. This is not a contradiction: the
  analytical result optimizes a tagged opportunity with four active
  competitors, not mission throughput under endogenous queues and retries.
  EXP12 therefore **rejects any claim that p=0.2 universally optimizes
  empirical throughput**.
- `p=1` causes complete collapse only for synchronized Periodic-P10. Event
  policies can desynchronize their offered load and obtain occasional
  service, so the result must not be generalized to every workload.
- At causal `p=0.2`, mean ACK airtime is 0.6131 s versus 0.7622 s DATA airtime
  per 12 s run. Aggregated feedback is therefore not negligible. The mean run
  has 613.1 standalone ACK frames, 445.9 actually attempted piggyback ACK
  entries, 0.3 transferred entries and 938.4 delivered ACK entries. These are
  different units and are deliberately not added into one packet count.
- Across the entire matrix there are zero expired-history ACKs, stale ACKs,
  stale DATA acceptances, ACK-before-accept events and obsolete retry drops.
  There are 78 queue-transfer events preserving feedback in 10 cells. The
  history ring reaches its declared capacity in all cells, showing fixed memory
  reuse rather than unbounded allocation.
- Binary separation failures occur in 22/108 development runs, concentrated
  in `p=1` event/causal cells and Stressed State-event cells. This is retained
  as a boundary observation, not a safety comparison. Periodic-P10 at `p=1`
  has zero DATA delivery and RMSE 1.7372 m but no binary separation failure,
  demonstrating that minimum separation alone cannot certify coordination.

## 4. Consequences for EXP13

EXP13 may now use the end-to-end kernel, but it must not inherit a performance
conclusion from EXP12. Its preregistration/development phase must include:

1. the analytical primary `p=0.2` plus declared p sensitivity; no replacement
   by `p=0.1` after seeing this diagnostic;
2. separate DATA-frame, recipient, ACK-entry, airtime and energy metrics;
3. explicit ablations for standalone ACK, piggyback ACK and full aggregation,
   because feedback airtime is material;
4. both formation accuracy and binary separation, with failure denominators;
5. saturated-load and background-load arms to test when the block-service
   minorization assumptions are empirically plausible;
6. a finite-history stress arm long enough to produce delayed/expired ACKs,
   because the nominal EXP12 matrix did not exercise that boundary;
7. no headline claim until baselines/frontiers, parameter budget and new
   holdout seeds are preregistered.

## 5. Artifacts

- raw matrix: `results/exp12_shared_medium_diagnostic/2026-08-29_104600/tidy.csv`;
- gates: `results/exp12_shared_medium_diagnostic/2026-08-29_104600/gates.csv`;
- machine verdict: `results/exp12_shared_medium_diagnostic/2026-08-29_104600/verdict.json`;
- configuration manifest:
  `results/exp12_shared_medium_diagnostic/2026-08-29_104600/diagnostic_config.json`;
- executable workspace and representative infrastructure trace are retained in
  the same run directory.
