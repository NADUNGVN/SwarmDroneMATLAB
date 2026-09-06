# EXP20A results and research decision — 2026-09-01

## Status

EXP20A is complete as a development/falsification study. The valid combined
artifact consists of the unchanged 2,520-row formation panel from
`2026-08-31_232833` and the corrected 1,800-row native panel from
`2026-09-01_005821`.

The registered verdict is:

> `PRIOR_ART_EXPLAINS_FRONTIER`

Consequently, EXP20B candidate design is not permitted. EXP20A does not permit
a manuscript claim, confirmatory claim or hardware-policy promotion.

## Integrity and correction trail

- The original full matrix completed 4,320 trajectories. All 13 parent
  integrity gates passed: exact matrices and seeds, paired absolute traces and
  native draws, zero future reads, zero formation protocol violations, bounded
  memory, closed physical accounting, all mechanisms activated, and all 451
  unsafe outcomes retained. There were zero formation divergences.
- The first native implementation was then invalidated by comparison with the
  official DELTA source. It omitted collision-exit plus silence returning to
  normal phase and differed at the clock/hot-start boundary, `K=2.5N`,
  comparator ACK reset and initial collision-step memory.
- No erroneous native file was overwritten. The correction run contains an
  explicit supersession record and a frozen corrected-source snapshot.
- The corrected native matrix completed 1,800/1,800 rows. All seven correction
  gates passed, including exact task uniqueness, all frozen seeds, five-arm
  absolute-draw pairing, zero future feedback reads, queue bound five, finite
  accounting, and activation of public and delayed/lossy private feedback.
- A regression case now requires the clean-room public implementation to retain
  the upstream hot-start/collision-resolution heavy-tail boundary.

## Formation result: prior art closes the current frontier

At the registered N5-Stressed boundary, the current frame-piggyback policy has
mean RMSE 0.09513, charged utilization 0.33077 and 0/30 safety failures.

| Arm | RMSE | Charged utilization | Safety failures | Registered result |
|---|---:|---:|---:|---|
| Current frame-piggyback | 0.09513 | 0.33077 | 0/30 | reference |
| Periodic TDMA 8.333 Hz | 0.08194 | 0.16667 | 0/30 | dominates |
| Periodic TDMA 10 Hz | 0.07182 | 0.20000 | 0/30 | dominates |
| Periodic TDMA 12.5 Hz | 0.06081 | 0.25000 | 0/30 | dominates |

Periodic 8.333 Hz lowers RMSE by about 13.9% and charged utilization by about
49.6% relative to the current policy. Periodic 10 Hz lowers them by about
24.5% and 39.5%, respectively.

At N10-Moderate, current frame-piggyback has RMSE 0.21380, charged utilization
0.45277 and 25/30 safety failures. Periodic TDMA 8.333 Hz has RMSE 0.10176,
charged utilization 0.33333 and 0/30 failures; periodic TDMA 10 Hz has RMSE
0.08956, charged utilization 0.40000 and 0/30 failures. Both methods match or
beat the current policy in both registered primary cells.

This is sufficient by the frozen rule to stop the candidate branch. The
failure of the current policy is explained by access/service organization,
not by the absence of another ACK/AoI trigger heuristic.

The private age-gain and DELTA projections reduce RMSE and eliminate the N10
failures, but their charged utilization is substantially higher. Therefore no
existing private projection matches the current policy on all registered axes.

## Native result: a real typical-case information penalty with a heavy-tail caveat

The registered paired-relative-mean gate is positive in 6/6 `rho=0.50` cells,
with the paired 95% bootstrap interval entirely above zero. Thus the registered
native information-structure gap is supported.

However, DELTA has a highly skewed public-reference distribution. Private
delayed feedback is worse than public feedback in 76.7%--96.7% of paired seeds
and has a much larger median AoII in every registered gap cell. The public arm
nevertheless has a larger arithmetic mean in every cell because rare
hot-start/collision-resolution runs become catastrophic.

Examples:

| Cell | Public median / mean / max | Private median / mean / max | Public runs AoII > 100 | Private worse fraction |
|---|---:|---:|---:|---:|
| N5, eps 0.05 | 0.727 / 247.9 / 7,417 | 6.36 / 6.35 / 6.72 | 1/30 | 96.7% |
| N5, eps 0.20 | 1.61 / 1,486.9 / 10,920 | 8.57 / 372.8 / 10,259 | 8/30 | 76.7% |
| N10, eps 0.05 | 0.980 / 145.3 / 2,643 | 19.39 / 107.5 / 2,664 | 2/30 | 96.7% |
| N10, eps 0.20 | 2.47 / 169.5 / 2,519 | 22.72 / 55.2 / 993 | 3/30 | 86.7% |
| N20, eps 0.05 | 1.43 / 82.9 / 2,447 | 49.37 / 49.7 / 56.6 | 1/30 | 96.7% |
| N20, eps 0.20 | 4.27 / 636.3 / 7,256 | 54.50 / 55.3 / 79.1 | 4/30 | 86.7% |

The defensible conclusion is narrow: receiver-specific delayed/lossy feedback
usually impairs DELTA's slot-synchronous coordination, while broken synchrony
can occasionally avoid or escape a catastrophic public-protocol boundary.
This observation does not rescue the formation-policy branch and should not be
reported as “private feedback improves DELTA” or “public feedback is worse.”

## Research decision

1. Do not implement EXP20B as another causal trigger policy. The frozen gate
   explicitly forbids it, and periodic TDMA already explains the relevant
   formation frontier.
2. Do not promote current Causal-v3/frame-piggyback to hardware as the preferred
   policy. In the registered primary cells, a simpler scheduled baseline is
   both more accurate and cheaper and removes the observed safety failures.
3. Treat robust distributed scheduling as the next plausible research pivot:
   retain the periodic/scheduled service result, then study how much of it
   survives reservation overhead, topology change, hidden terminals, clock
   error and decentralized schedule disagreement.
4. Keep the native DELTA observation as a separate protocol-robustness lead.
   Any continuation must distinguish the published initialization/CR boundary
   from the causal effect of public versus private feedback, preferably by
   registering both faithful and non-absorbing variants before new outcomes.
5. The frozen EXP20A plan requires the full Aydin two-hop reservation/migration
   baseline only if EXP20A does not stop. Since EXP20A stops, that implementation
   is not required for this branch; it may become relevant only under a new
   scheduling-focused research question.

## Canonical artifacts

- Valid corrected verdict:
  `results/exp20a_native_protocol_correction/2026-09-01_005821/development_verdict.json`
- Supersession record:
  `results/exp20a_native_protocol_correction/2026-09-01_005821/supersession.json`
- Corrected native data:
  `results/exp20a_native_protocol_correction/2026-09-01_005821/native_tidy.csv`
- Unchanged valid formation data:
  `results/exp20a_native_protocol_correction/2026-09-01_005821/formation_tidy.csv`
- Registered decision gates:
  `results/exp20a_native_protocol_correction/2026-09-01_005821/decision_gates.csv`
- Native paired audit:
  `results/exp20a_native_protocol_correction/2026-09-01_005821/native_public_private_audit.csv`
- Post-hoc distribution audit:
  `results/exp20a_native_protocol_correction/2026-09-01_005821/native_distribution_audit_posthoc.csv`
- Formation prior-art audit:
  `results/exp20a_native_protocol_correction/2026-09-01_005821/formation_primary_audit.csv`

The original
`results/exp20a_prior_art_baseline_closure/2026-08-31_232833/native_tidy.csv`
is retained for audit only and must not be used for scientific claims.
