# EXP18A feasibility/value policy development results

## Run identity

- Canonical run: `2026-08-31_121134`
- Stage: development only
- Matrix: 1600/1600 simulations
- Seeds: `16024001:16024020`
- Contexts: 8 core plus reverse-asymmetric/hidden-terminal boundaries
- Access types: configured CSMA and ALOHA
- Arms: legacy selector, frame-aware piggyback, frame-aware legacy adaptive,
  frame-aware feasibility/value
- Runtime: 15 min 05 s on 16 process workers

The earlier directory `2026-08-31_120906` is an explicitly marked aborted
pre-performance run. It contains no result row and is not evidence.

## Integrity

All 12/12 gates pass: complete unique matrix, exact arm/access semantics, one
absolute trace across both access types and all four arms, finite output,
causal conservatism, bounded memory, closed physical accounting and exact
decision accounting. There are zero protocol violations, maximum queue depth
2 and maximum history depth 32.

## Frozen development verdict

The v1 candidate is **rejected/requires revision**. It passes 4/6 development
gates.

Passed:

- no more than one core context--MAC cell is jointly worse than both fixed
  frame-aware routes (observed: 1; allowed: 2);
- every ACK evaluation closes into permit, feasibility block or value block;
- 6251 value-block evaluations demonstrate that the marginal-value layer is
  active;
- the reverse-asymmetric boundary retains its declared optimistic calibration
  mismatch.

Failed:

1. **Failure nonincrease:** in N10 Moderate bg0 ALOHA, the candidate has 14/20
   observed failures versus 13/20 for frame-aware piggyback and 15/20 for
   frame-aware adaptive. One extra failure relative to piggyback is sufficient
   to fail the declared gate.
2. **N10 ALOHA access repair:** offered utilization falls by 65.9--74.5% in all
   four cells, but collision-rate reduction is only 9.07% and 9.19% in the two
   bg0.30 cells, below the declared 10% threshold. This gate is not relaxed
   after inspection.

No EXP18B holdout is opened.

## What is learned

### Frame-aware access is the dominant repair

Replacing `1/N` ALOHA access by `1/[N(2L_D-1)]` materially lowers absolute
contention. For example, N10 Moderate bg0 mean offered utilization falls from
about 1.75 to 0.45 and mean collision frames fall from 5016 to roughly 718--727
per run. DATA goodput rises from 19.5 Hz to 50--52 Hz. The collision *rate*
falls less because its denominator, total attempts, also falls; under bg0.30,
external-background collisions form a large irreducible fraction.

This distinction means the failed 10% collision-rate gate must remain failed,
while absolute collision burden is the more interpretable diagnostic for a
future design. A new version may preregister that quantity, but v1 cannot be
retroactively rescored.

### ACK marginal value remains secondary

The context arm generates many standalone ACKs in light-load cells and almost
none in high-background cells. Nevertheless, relative to frame-aware fixed
routes its RMSE/offered differences are generally small. The sole core cell
jointly worse than both fixed routes is N5 Stressed bg0 CSMA. At N10 Moderate
bg0 ALOHA, the value rule lies between piggyback and adaptive in failure count
rather than selecting the safer development route.

### The residual-slack feasibility proxy is insufficient

There are zero feasibility blocks in the complete run. Frame-aware access
reduces the busy EWMA enough that `1-busy-rho_D` remains positive, even where
observed closed-loop failure remains common. Busy slack alone therefore does
not certify that the achievable successful-update rate meets the semantic AoI
requirement.

## Consequence for the next candidate

Candidate v1 is frozen as a negative development result. A defensible v2 must
add an analytical per-node service-rate certificate derived from access
probability, multi-slot vulnerable period, background survival and calibrated
DATA success. The required service rate is fixed by the existing AoI threshold,
not fitted to failures. If achievable service is below that rate, the policy
must abstain from making a feedback-route claim and suppress standalone ACKs.

This is a new development version. It may reuse EXP18A seeds for development,
but any eventual confirmation requires a disjoint, unopened seed block and a
new preregistration.

