# EXP23AP routed state-machine/common-PHY development plan

Frozen: 2026-09-06, before execution of seeds 16095201--16095701.

## Question

EXP23AO validates routed multi-origin bundles independently.  EXP23AP asks
whether those physical route outcomes can causally drive the complete receiver-
lifted migration state machine while every actual relay attempt is placed on a
continuous common-PHY timeline.

This is still a retained-fixture development study.  It does not drive the UAV
plant, validate renewal, constitute fresh confirmatory evidence, or permit a
submission claim.

## Frozen configuration

The N=10 online witness and full old/proposed physical-interference union are
inherited without tuning.  The EXP23AO optimum is fixed: four hop-local
repetitions, three PREPARE opportunities, four CLAIM opportunities with a two-
opportunity evidence prefix, two COMMIT opportunities, and 11 abstract phase
indices.  The exact transaction union bound is 0.00090955439743163613 and the
conservative post-request duration is 5.0346184407376295 s within 6.5 s.

For every phase, the packet set is chosen only from prior receipt state.  Its
route is then scheduled and replayed; per-receiver packet state, rather than an
all-or-nothing multicast flag, updates the state machine.  The emitted relay
attempts are converted to continuous events with integer packet bytes, exact
airtime, receiver-level outcomes, fixed DATA opportunities, and the existing
certified affine-clock transform.

## Registered evidence

- 500 IID routed transaction traces, seeds 16095201--16095700;
- one all-success trace with separate PREPARE, RESPONSE, and COMMIT link
  blackouts, seed 16095701;
- exact accounting and state-hash replay between the kernel and continuous
  builder;
- dynamic bundle schedules must remain inside the five EXP23AO registered
  bundle slot envelopes;
- every full 11-index continuous schedule must remain below both the
  conservative 5.034618441 s bound and the 6.5 s post-request budget.

Empirical failures are a trajectory sanity check, not an estimator intended to
prove a 1e-3 probability.  Agreement uses the registered analytical upper bound
plus five binomial standard errors and 1/n.  The analytical union certificate
remains the reliability evidence.

## Frozen gates

Eighteen gates cover the exact EXP23AO parent; source/tests; unique registered
seeds; exact selected retry/certificate identity; empirical completion versus
the analytical upper bound; safety barrier and coloring; independent route
collision/isolation/causality counters; integer accounting; kernel-to-continuous
replay identity; control/data non-overlap and horizon; conservative duration;
affine-clock preservation; dynamic bundle envelopes; the three registered
blackout state trajectories; implementation versions; and preservation of all
downstream scope flags.
