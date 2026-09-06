# EXP21C — Closed-loop continuous-time timing integration

**Status:** frozen integration design, written before closed-loop performance
outcomes are generated

**Study type:** development/model-integration; no candidate optimization

## 1. Objective

Integrate the EXP21B-validated continuous local-clock interval semantics into
the existing formation/shared-medium simulator without altering any legacy MAC
mode or EXP21A result.  This stage isolates timing from reservation logic.

The first integrated mode is `continuous-local-static-tdma`.  It uses a fixed
unique node-to-slot map, exact DATA airtime, configurable guard time, residual
clock offset at every synchronization epoch, and fixed node drift.  It does not
run reservation negotiation.  Reservation and control contention are a later
layer and cannot be used to explain a failure at this stage.

## 2. Integration semantics

- The legacy `mac.slotTime=1 ms` remains only the channel/background trace
  sampling quantum.
- A physical ownership slot is `8*DATA_bytes/PHY_rate + guard`.
- Transmission starts are arbitrary real times solving the EXP21B clock
  equation; they are never snapped to the legacy quantum.
- Frame completion, receiver loss, collision, retry and inline delivery reuse
  the existing shared-medium semantics.
- Exact half-open interval overlap and the receiver interference matrix decide
  collisions.
- Busy time is the union of active intervals plus any declared external
  background occupancy.  Offered airtime is the exact sum of transmitted frame
  durations.
- Clock and synchronization draws are absolute and pre-generated.  Policy
  actions never advance an RNG.

## 3. Mandatory integration contracts

1. All pre-existing shared-medium and EXP21A regression tests remain unchanged
   and pass.
2. With zero offset/drift/guard, the integrated transmission start sequence
   equals the standalone EXP21B kernel for the same queued workload.
3. Exact (non-rounded) DATA duration is visible in delivery events.
4. Below-bound adversarial clock error causes the same overlap/collision as the
   kernel; sufficient guard eliminates it.
5. Sparse interference preserves receiver-specific spatial reuse.
6. Event-time delivery updates controller-visible state before the next outer
   control sample.
7. DATA/terminal accounting and busy/offered airtime accounting close.
8. No receiver truth or future random draw enters the scheduler.

## 4. Development comparison

After contracts pass, use fresh development seeds to compare:

- ideal centralized TDMA;
- continuous static TDMA with zero clock error;
- continuous static TDMA with registered clock error and zero guard; and
- the same clock process at the EXP21B sufficient guard.

The integration is accepted only if zero-clock behavior is consistent with the
ideal collision-free reference, unguarded clock error exposes the registered
failure mechanism, and sufficient guard prevents endogenous timing collisions.
Formation performance is descriptive at this stage and cannot promote a
scheduling candidate.
