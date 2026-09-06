# EXP21D-K amendment 03 — separate resolution from conservative convergence

**Date:** 2026-09-01

**Trigger:** retained v2 run
`results/exp21d_dstr_kernel_conformance/2026-09-01_060611` and its
horizon-prefix continuation audit.

## Retained v2 result

V2 repaired allocation: all 200/200 source-native rows ended Resolved,
physically valid, and with formation-wide frame-length agreement. It still
failed the registered convergence gate because only 182/200 removed every
globally unused slot by superframe 200. Its verdict remains
`DSTR_KERNEL_INVALID_NO_CLOSED_LOOP`.

The 18 exact failed prefixes were continued to frame 1000 with bit-identical
logs over frames 1--200. Sixteen converged between frames 201 and 800; two
remained unconverged. This established that the failure mixed a conservative
shrink delay with a remaining starvation mechanism rather than allocation
invalidity.

## Mechanism diagnosis

Section 4.4.1 defines a `failed_shrink` cache so that a node does not repeatedly
propose locally silent slots that are globally occupied elsewhere in a
multi-hop formation. With `FST=10`, cache entries expired before a node could
traverse its set of locally silent candidates, starving a lower globally
unused gap. The source explicitly evaluates `FST=10` and `FST=30` and reports
the cache timeout as a shrink-only parameter.

The source also maps each node's initial shrink backoff to its order in the
superframe to prevent all nodes transmitting in `TS`. In a spatial-reuse
schedule, the transmission-slot index is not unique. V3 therefore uses the
preconfigured ascending formation-node order as the unique deterministic
order. This is deployment metadata, not runtime physical truth.

On the complete 100-seed v2 N=10 native development set, `FST=30` yielded
97/100 convergence by frame 200. The remaining three converged at frames 202,
212, and 230 under exact absolute-trace continuation. All allocation outcomes
remained physically valid. These are development diagnostics, not rescored v2
claims.

## Frozen v3 design

V3 is frozen before inspecting any v3 outcome:

- fresh seeds `16035001:16035100`;
- unchanged `N={5,10}` and four-condition 800-row matrix;
- `FST=30`, a source-evaluated setting;
- unique initial shrink order equal to ascending formation node index;
- native allocation must be Resolved and physically valid by frame 200;
- conservative no-unused-slot convergence must occur by frame 1000; and
- all boundary trajectories also run to frame 1000 and are retained.

The wider cap does not relax the resolution deadline or convert v1/v2 into
passes. It separates fast safety-schedule acquisition from later optimization
of update period, matching the source's design priority: grow/resolve first,
then shrink conservatively.
