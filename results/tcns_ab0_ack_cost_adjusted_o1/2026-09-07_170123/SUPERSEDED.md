# Superseded technical run

This first AB0.2 run grouped cumulative ACKs by outer tick and directed link.
Audit subsequently showed that `simSwarmAoICausal` invokes DATA delivery both
before and after scheduling, so a zero-delay acceptance can produce a second
ACK for the same link in the same outer tick. This run is preserved for
history but must not be cited. The authoritative corrected run is
`2026-09-07_170715`.
