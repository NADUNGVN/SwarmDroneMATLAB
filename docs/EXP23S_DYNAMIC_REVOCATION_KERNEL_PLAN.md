# EXP23S — Dynamic self-revocation kernel falsification

Status: frozen before fresh-seed execution on 2026-09-04.

The matrix contains 800 rows: 100 fresh seeds `16080001:16080100`, N5/N10
and four paired channel conditions (zero loss with delivered REVOKE,
permanent directed REVOKE blackout, joint CLAIM/RESPONSE/REVOKE IID 5%, and
permanent reacquisition RESPONSE blackout).

Every row embeds a receiver-level motif in which senders 1 and 3 share a
color under the certified graph. A physical edge outside that graph would
make sender 3 collide at sender 1's intended receiver; sender 3 must revoke
one frame before this edge appears. A separate physical edge is added and
removed inside the certified supergraph. Reacquisition eligibility occurs
eight frames after revocation, but scheduled reuse remains fenced by the old
tuple lock.

The 25 frozen gates cover exact matrix pairing, positive pre-event state,
immediate suppression, edge-transition stimulus, zero scheduled collisions,
fresh-version/fence-respecting reacquisition, delivered-versus-lost REVOKE
independence, blackout fail-silence, 28/16+10e/24-byte packet closure, MTU,
recipient/byte/attempt accounting, absolute bounds, cumulative retry,
version-bound REVOKE rejection, causality and non-promotion scope.

A pass validates only the fixed-certified-supergraph dynamic lifecycle. It
does not validate online graph reselection/color migration or closed-loop
performance.
