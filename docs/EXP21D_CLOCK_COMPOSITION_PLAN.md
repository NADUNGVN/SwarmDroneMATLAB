# EXP21D-C: D-STR affine-clock composition

**Frozen before randomized closed-loop outcomes:** 2026-09-01  
**Upstream gates:** EXP21D-B 16/16; clock composition contracts 6/6  
**Stage:** prior-art timing-boundary falsification  
**Candidate design, tuning and submission claims:** prohibited

## 1. Question

EXP21D-B identifies unreliable implicit schedule evidence and loss of common
frame state as the active D-STR boundary. EXP21D-C asks whether bounded local
clock error remains a third unresolved mechanism after D-STR is executed on
the continuous event timeline.

The test deliberately uses a single affine clock epoch over the complete
12-second mission. This avoids assuming an unmodelled synchronization protocol.
For maximum initial offset `Theta`, fractional drift `Delta` and horizon `H`,
the finite-horizon boundary error and sufficient guard are

`E = (Theta + Delta H)/(1 - Delta)` and `G_safe = 2 E`.

With `Theta = 0.25 ms`, `Delta = 40 ppm` and `H = 12 s`, the mission-safe
guard is approximately `1.46006 ms`. A common lead `E` prevents the first
physical start from preceding time zero.

## 2. Frozen matrix

The study uses 30 fresh seeds (`16038001:16038030`), the accepted N5 6-DOF and
N10 ring2 zero-loss cells, and three native D-STR arms:

1. short guard (`0.54002 ms`) with zero clock, as a guard-cost reference;
2. mission-safe guard with zero clock, as the exact paired clock reference;
3. mission-safe guard with bounded random affine offset/drift.

The two mission-guard arms share one native kernel schedule and differ only in
the local-clock inverse map. All arms use the same outcome-blind nominal cutoff

`b_cut = (H - E - D)(1 - Delta) - Theta`,

where `D` is physical frame airtime. Thus every retained DATA/control group is
complete under every allowed clock realization, and the paired clock arms have
identical logical opportunities rather than different end-of-mission censoring.

## 3. Exact physical semantics

For node `n`, nominal boundary `b` is mapped to physical start

`t = E + (b - theta_n)/(1 + delta_n)`.

Transmitters sharing a logical slot may therefore start at different physical
times. The event engine keeps their logical group identity, applies half-duplex
to the entire group, and detects receiver-specific collision from the actual
overlapping intervals. A management group occupies the exact union envelope
from its earliest start to its latest completion, while offered cost remains
the sum of attempt airtimes.

## 4. Integrity gates

The study is valid only if:

1. all 180 seed/cell/arm rows are present exactly once;
2. shared, estimator, D-STR and clock traces are paired as frozen;
3. the two mission arms have identical base-schedule and logical-opportunity
   hashes for every seed/cell;
4. all affine equations close numerically and every schedule carries a valid
   sufficient-guard certificate;
5. every retained D-STR opportunity is attempted exactly once;
6. scheduled and observed DATA success/erasure/collision counts match;
7. kernel and event-engine collision witnesses match;
8. management recipient and attempt-airtime accounts close;
9. DATA and management intervals never overlap across logical groups;
10. recipient/right-censor and busy/offered accounting close;
11. causality and protocol invariants remain zero; and
12. all unsafe/divergent rows are retained.

There is no performance pass threshold. Paired RMSE, true AoI, offered
utilization, busy utilization and goodput effects are reported with bootstrap
intervals.

## 5. Decision rule

- If the mission-safe clock arm preserves all physical outcomes and has only a
  small paired closed-loop difference from mission-safe zero clock, the timing
  layer is considered closed for candidate design.
- If it creates new collision/outcome mismatches, the D-STR/clock composition
  remains invalid and candidate design stays closed.
- The short-vs-mission zero-clock contrast quantifies conservative guard cost;
  it cannot be used to select or tune a new method.

Only after timing composition is valid may the programme design an explicit
schedule-validity/evidence-repair/fallback candidate from the EXP21D-B gap.
