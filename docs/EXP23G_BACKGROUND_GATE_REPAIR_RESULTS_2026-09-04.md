# EXP23G — Valid background-robustness gate-repair results

Run: `results/exp23g_background_gate_repair/2026-09-04_154603`

Status: **valid negative performance result; ELCS-W returns to design**.

## Integrity

- 30 fresh seeds, two topology cells, four occupancy conditions and two
  arms: 480/480 unique trajectories.
- Registry hash `78936880` over 72 leaves.
- All 20/20 integrity gates passed.
- Mean on-run duration was 1.177 ms for IID-15% and 48.70 ms for Markov-15%,
  confirming that the correlated condition was materially bursty.
- Both engines charged the same absolute occupied time and used the same
  underlying occupancy random field.
- ELCS-W variable packet, recipient, replay and causal accounting closed.

## Safety/liveness

No terminal-certification, false-valid, scheduled-collision, safety or
divergence failure occurred. Thus the isolated terminal failure seen in the
invalid EXP23F run did not repeat and is not treated as an established
safety failure.

## Decisive negative result

N5 under IID 15% occupancy satisfies the pre-registered periodic epsilon-
dominance kill rule:

- ELCS-W mean RMSE: `0.05444440` m;
- periodic mean RMSE: `0.05491311` m, only `0.8609%` above ELCS-W and hence
  within the allowed +1% band;
- ELCS-W mean offered utilization: `0.32438613`;
- periodic mean offered utilization: `0.28672000`, or `11.6115%` lower.

The RMSE paired interval for `periodic - ELCS-W` is
`[-0.00094532, 0.00194094]` m, so confidence-supported dominance is not
established. The frozen conservative rule uses point-estimate epsilon-
dominance, however, and therefore kills the current candidate.

All other load contrasts survive. In particular, periodic RMSE penalties are
3.34%/3.30% for N5 Markov-15/30 and 10.38%/8.04% for N10 Markov-15/30.

## Mechanism diagnosis

The weakness is not lease safety. Under IID-15%, a multi-millisecond packet
overlaps several independent 1 ms occupancy quanta. ELCS-W then performs on
average 181.37 retry CLAIMs in N5 and 275.93 in N10. Its current rule starts
a new CLAIM sequence on every retry and requires same-frame receipt from all
incident witnesses, discarding receipts already obtained from other
witnesses. This creates retry amplification under temporally fragmented
occupancy. At N5, the resulting control airtime cost is large while the RMSE
advantage collapses to below 1%.

## Redesign direction

The next candidate is a same-sequence cumulative-receipt transaction:

1. increment the CLAIM sequence only when a renewal transaction starts;
2. retransmit that same sequence while the transaction remains incomplete;
3. retain per-edge witness receipts across frames;
4. stop retransmission once every incident witness has acknowledged the
   current sequence;
5. retain all existing self-lock, lease-fence, local-certificate and fallback
   safety rules.

This directly targets the observed amplification without tuning formation or
threshold parameters. It must first pass kernel safety/liveness tests under
loss; only then may a new closed-loop background frontier be frozen. The
EXP23G data may be used for diagnosis, never for promotion evidence.
