# EXP23A: local-witness kernel falsification

**Frozen before randomized outcomes:** 2026-09-01  
**Rows:** 1,000 = 100 fresh seeds x 2 topologies x 5 conditions  
**Scope:** kernel only; no closed-loop, promotion or submission claim

ELCS-W replaces all-to-all management with deterministic one-hop conflict
witnesses. CLAIM attempts self-lock the sender tuple; a witness certificate is
accepted only from fresh, distinct endpoint claims. The frozen payload is 24
bytes per CLAIM and `16 + 8m` bytes for a transmitted `m`-entry CERT, under a
96-byte MTU. Local client-witness entries consume no radio response.

Conditions are zero loss, 5% CLAIM loss, 5% CERT loss, 5% DATA loss, and one
permanent directed transmitted-CERT blackout. The random-control-loss liveness
gate requires at least 95% terminal full certification in each cell and loss
condition. Every condition requires zero false-valid edge-frames and zero
scheduled collisions. DATA loss must leave the certificate-state hash equal
to its paired zero-loss run. The permanent blackout must leave its target
client inactive and retain fallback attempts. Attempt, byte, recipient and
one-fallback-per-node-frame accounting must close exactly.
