# EXP23Y — Local migration common-PHY integration plan

Status: frozen before randomized execution.

EXP23Y maps the causal EXP23X transition kernel to one continuous PHY. Each
frame reserves deterministic per-node CLAIM/LOCK-PROOF/REVOKE minislots,
deterministic per-witness RESPONSE minislots and `N` scheduled DATA slots.
Actual packet airtime uses the exact payload bytes; the reserved control slot
uses the 96-byte maximum plus the analytical clock guard.

The matrix contains 50 seeds, `N={5,10,20}`, zero loss, IID-20, IID-40,
REVOKE blackout, RESPONSE blackout and incomplete-union cases, each under
zero and bounded affine clocks: 1,800 rows. The maximum clock offset is
0.25 ms, maximum drift is 40 ppm, and the guard is computed for a declared
30-second reset horizon.

Required gates cover exact kernel-to-PHY attempt/byte/airtime/recipient
mapping; explicit packet kinds; fixed proof-window independence; old-slot to
silence to changed-slot DATA; full logical-opportunity preservation across
clock arms; zero supported collisions and inter-group overlap; fail-silent
RESPONSE blackout; REVOKE-loss equivalence; visible incomplete-union
collisions; exact trace/state hashes; and causal/bound compliance.

This study does not run the UAV controller and cannot establish a performance
claim. A valid result only permits closed-loop migration integration.
