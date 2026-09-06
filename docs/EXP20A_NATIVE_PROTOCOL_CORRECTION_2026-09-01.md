# EXP20A native protocol correction — 2026-09-01

The original 1,800-row native panel is invalid and retained only as a
superseded artifact. It omitted the DELTA transition from collision-exit with
no transmitter back to the normal phase. It also differed from the upstream
implementation in the first-slot clock, hot-start boundary, `K=2.5N`, and the
ACK reset semantics of the zero-wait, maximum-age-first and round-robin
comparators.

Upstream comparison exposed one additional fidelity requirement:
`collision_steps` is initialized to zero. When hot-start ends in collision
resolution, this can produce a near-zero retry probability and a heavy-tailed
failure mode at high erasure and larger `N`. The clean-room implementation must
retain that behavior for a faithful public-reference arm rather than silently
repair it.

The correction does not alter Panel F, whose 2,520 rows and prior-art frontier
verdict remain valid. Corrected Panel N is executed as a separately identified
artifact. No original result file is overwritten, and manuscript/hardware
promotion remains prohibited.
