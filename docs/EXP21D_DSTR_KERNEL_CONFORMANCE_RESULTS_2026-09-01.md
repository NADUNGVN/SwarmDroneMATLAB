# EXP21D-K D-STR kernel conformance — results

**Date:** 2026-09-01

**Accepted run:**
`results/exp21d_dstr_kernel_conformance/2026-09-01_070545`

**Verdict:** `DSTR_KERNEL_CONFORMANCE_VALID`

This verdict authorizes a closed-loop prior-art comparison. It does not
promote a new policy, support a submission claim, or claim numerical
reproduction of the D-STR authors' SINR simulations.

## 1. Integrity result

All 17 registered gates passed:

- 800/800 unique rows from exactly 100 fresh v3 seeds, two swarm sizes, and
  four conditions;
- registry hash `85258916` over 48 leaves;
- 13-file frozen-source hash `8171592`;
- 16/16 deterministic mechanism contracts;
- exact replay and condition-paired absolute draws;
- all `TG`, `TGn`, `TS`, `TSo`, and `TSn` paths activated;
- 200/200 native rows Resolved and physically valid by frame 200;
- 200/200 native rows converged without a globally unused slot by frame 1000;
- zero native frame-length disagreement;
- every success/collision had a physical witness;
- all DATA and management recipient accounting closed; and
- zero future-random and hidden receiver-truth decision reads.

All 600 boundary rows were retained, including 201 rows that were not Resolved
at the terminal frame.

## 2. Native mechanism behavior

| N | Resolution median / p95 / max (frames) | Convergence median / p95 / max (frames) | Mean final DATA slots | Mean conflict-frame fraction |
|---:|---:|---:|---:|---:|
| 5 | 6 / 10 / 17 | 16 / 36 / 48 | 5.00 | 0.00211 |
| 10 | 11 / 17 / 22 | 50 / 163 / 225 | 8.16 | 0.00668 |

This separates two protocol timescales. A physically valid schedule is
acquired quickly, while conservative removal of unused slots can take much
longer. The v1/v2 history is retained because it exposed precisely this
distinction rather than permitting the convergence horizon to be silently
relaxed.

## 3. Boundary mechanisms

| Condition | N | Physically valid terminal rows | Converged rows | Frame-agreement rows |
|---|---:|---:|---:|---:|
| DATA-beacon erasure 0.05 | 5 | 48/100 | 18/100 | 100/100 |
| DATA-beacon erasure 0.05 | 10 | 32/100 | 0/100 | 100/100 |
| Local-only management reach | 5 | 31/100 | 0/100 | 0/100 |
| Local-only management reach | 10 | 47/100 | 0/100 | 0/100 |
| Node-2 state loss/rejoin | 5 | 100/100 | 100/100 | 100/100 |
| Node-2 state loss/rejoin | 10 | 100/100 | 100/100 | 100/100 |

The boundary rows are projections of the kernel outside the source-native
assumptions, not claims that the published D-STR protocol promised robustness
there. They establish useful mechanisms for the next study:

1. unreliable DATA records can prevent implicit evidence from stabilizing even
   when formation-wide management consensus remains intact;
2. restricting management reach destroys frame-length agreement in every row;
   and
3. isolated local state loss is recovered rapidly under native reach (median
   two to three frames).

## 4. Accounting caution

At `N=10`, native offered utilization averaged 0.948 and channel utilization
0.634 under the kernel's 512-byte, 1-Mbit/s accounting. This includes continued
locally motivated shrink negotiations even after the global schedule has no
unused slot. The source reports overhead to convergence and uses a detailed
path-loss/SINR PHY; EXP21D-K uses a binary safety-neighborhood conflict graph.
The number is therefore a warning to charge the complete control plane in
EXP21D-CL, not a numerical comparison against the source paper.

## 5. Decision

EXP21D-K closes the missing prior-art state-machine baseline sufficiently to
proceed. EXP21D-CL must now:

- compose D-STR assignments and all five management slots with continuous
  physical airtime and the validated guard model from EXP21B/C;
- deliver the actual scheduled safety beacons into the swarm estimator and
  controller;
- charge management and DATA attempts, busy-time union, and terminal outcomes;
- compare against a common-PHY periodic TDMA reference; and
- retain acquisition, loss, local-management, and rejoin failures rather than
  initializing D-STR from an oracle schedule.

No new distributed scheduler may be promoted until this closed-loop baseline
comparison is complete.
