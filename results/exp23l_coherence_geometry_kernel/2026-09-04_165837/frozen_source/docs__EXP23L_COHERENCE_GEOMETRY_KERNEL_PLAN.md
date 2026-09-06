# EXP23L — Coherence geometry-kernel falsification

Status: frozen before fresh-seed execution on 2026-09-04.

## Scope

This study validates the motion-tube supergraph, horizon selector and local
self-revocation primitives introduced by the coherence-certified lease design.
It does not yet integrate dynamic certificates into the ELCS-W packet kernel.

## Frozen matrix

- 100 fresh seeds `16074001:16074100`.
- Swarm sizes N=5 and N=10.
- Paired low- and high-uncertainty causal state envelopes.
- Candidate horizons `[0.25, 0.5, 1, 2, 4, 6.8]` s.
- Two-dimensional bounded-motion fixtures with a 1 m interference radius,
  finite 1.5 m bidirectional management reach, 0.2 m/s^2 acceleration bound
  and complete membership knowledge.
- 400 rows, each checked over every candidate horizon and 41 time samples.

Low/high uncertainty share positions, nominal velocities, error directions
and actual bounded accelerations. Only declared position/velocity error radii
change.

## Gates

The study requires exact matrix/realization pairing and deterministic
reproduction; actual conflict graphs must be subsets of every constructed
supergraph; no actual conflict may share a color; edge sets must grow
monotonically with horizon and uncertainty; high uncertainty may not select a
longer horizon than low uncertainty; any issued horizon must have complete
witness cover, packet fit and slot feasibility; uncovered horizons must fail
silent; normal bounded motion must not self-revoke, while injected acceleration
violation must self-revoke locally; and all decisions must report zero future
random/receiver-truth reads.

The run is valid only if all gates pass. A pass authorizes integration of the
coherence horizon and self-revocation state into the distributed ELCS-W
kernel. It does not promote the method or permit a performance/submission
claim.
