# EXP23J — ELCS-W control-overhead floor audit results

Source run: `results/exp23i_cumulative_closed_loop_target/2026-09-04_162852`

Status: **`RENEWAL_ARCHITECTURE_HAS_THEORETICAL_HEADROOM`**.

This is a posthoc mechanism diagnostic over the 60 EXP23I development seeds,
not independent confirmation evidence.

## Exact decomposition

Reconstructed common-PHY schedules close exactly against the physical control
byte count stored by EXP23I. Cumulative ELCS-W uses on average `12,958.93`
control bytes per 12 s run:

- CLAIM: `37.65%`;
- RESPONSE: `62.35%`;
- bootstrap through first complete certification: `5.66%`;
- post-certification renewal: `94.34%`.

The mean removal required to cost-match periodic is `71.62%` of remaining
control bytes (seed range `66.62%--77.19%`). Renewal bytes alone contain more
than that headroom in every aggregate comparison.

## Counterfactual floors

| Accounting counterfactual | Mean utilization | Relation to periodic `0.28672000` |
|---|---:|---:|
| Current cumulative | `0.31151929` | `+8.65%` |
| No control | `0.27696213` | `-3.40%` |
| Remove CLAIM only | `0.29850702` | `+4.11%` |
| Zero-marginal CLAIM and RESPONSE headers | `0.28722951` | `+0.18%` |
| Keep bootstrap, remove post-bootstrap renewal | `0.27891698` | `-2.72%` |

Thus neither retry repair nor header aggregation alone can create a robust
cost advantage. The bottleneck is the frequency of steady-state certificate
renewal.

## Required renewal scale

Under the explicitly idealized inverse-overhead approximation, keeping
bootstrap fixed requires a mean `4.186x` reduction of renewal frequency to
cost-match periodic (seed range `3.369x--5.272x`). Requiring the candidate to
be at least 1% cheaper than periodic instead gives a mean factor `6.642x` and
a worst-seed factor `8.876x`; the smallest conservative integer development
factor is therefore `9x`.

## Decision

The next candidate may alter only the renewal horizon: cumulative receipt
logic, witness cover, packet formats, PHY, DATA service, clocks and safety
fences remain fixed. A `9x` horizon-scaled candidate is a development probe,
not a tuned final method. It must first demonstrate the predicted cost margin
on the same diagnostic seeds, then acquire a mathematically defensible
topology-coherence/revocation rule and pass fresh kernel plus closed-loop
tests before any full robustness confirmation.

