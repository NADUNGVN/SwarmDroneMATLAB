# EXP22I: event-driven renewal kernel results

**Run:** `results/exp22i_elcs_event_driven_order_repair/2026-09-01_192508`  
**Verdict:** `ELCS_F_KERNEL_VALID`  
**Rows:** 1,400/1,400  
**Gates:** 20/20

The event-driven control redesign and emission-order repair satisfy every
legacy and new gate:

- 200/200 zero-loss rows certify by frame N;
- zero scheduled collisions, false-valid edges, lock violations, stale/future
  accepts and GRANT-without-request events;
- STATUS attempt partition residual exactly zero;
- maximum observed/analytical control-bound ratio `0.982967`;
- 200/200 state-loss recovery and 200/200 post-fence reconfiguration recovery,
  with 600 automatic recolors; and
- all 400 restricted-visibility/blackout terminal failures retained.

In 400-frame zero-loss runs, mean control attempts fall from the accepted
pre-redesign values 1,794 to 523 at N5 and 3,774 to 1,385 at N10. The split is:

| Cell | Discovery STATUS | Request STATUS | GRANT | Total | Analytical bound |
|---|---:|---:|---:|---:|---:|
| N5 | 89 | 124 | 310 | 523 | 534 |
| N10 | 176 | 279 | 930 | 1,385 | 1,409 |

The 23,684 fallback collision frames in boundary conditions remain visible.
Passing authorizes only fresh-seed affine-clock closed-loop integration.
