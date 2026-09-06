# EXP23U — Dynamic common-PHY closed-loop operating envelope

Status: frozen before fresh-seed execution on 2026-09-04.

The frozen matrix uses 60 seeds `16082001:16082060` and six arms, for 360
closed-loop trajectories. Early and late events occur at 3 s and 8 s; causal
reacquisition eligibility follows after 0.5 s. All arms use IID-15% shared
occupancy and exact affine-clock/common-PHY replay. Performance CIs use
10,000 paired bootstrap resamples.

EXP23T establishes the static target mechanism. EXP23U must measure the
closed-loop cost of fail-silent revocation without treating expected
suppression as a protocol failure. The fixed N5 certified graph is retained;
the injected event represents a local advertised-envelope violation rather
than online graph migration.

Paired arms will include periodic and no-event coherence references, an early
single revocation with ordinary delivery, the same event with directed
REVOKE blackout, a late revocation, and an early revocation with permanent
reacquisition-RESPONSE blackout. Early eligibility occurs 0.5 s after the
event, but scheduled reuse must still wait for the captured old fence. A late
event is expected to remain suppressed through the mission when its old fence
extends beyond the horizon. The RESPONSE-blackout arm must also remain
suppressed, for a distinct causal reason.

Validation concerns exact continuous REVOKE mapping, pairing, safety,
fail-silence, fence timing, replay, occupancy, byte/recipient/airtime
accounting and causality. RMSE/cost effects and periodic dominance are
reported as operating-envelope outcomes, not used to invalidate a correctly
executed negative result. Online graph reselection/color migration remains a
separate next gate.
