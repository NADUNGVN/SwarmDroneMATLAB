# EXP23G — Background robustness floating-point gate repair

Status: frozen before fresh-seed trajectory generation on 2026-09-03.

EXP23F completed its 480 trajectories but was invalid because one pairing
gate compared a derived background fraction with bit-exact `unique`. The two
engines accumulated identical occupied intervals in different event orders,
giving differences near `1.7e-14`; raw background busy time and every
exogenous hash passed their declared tolerances.

EXP23G changes only that comparison to

`max(fraction_pair)-min(fraction_pair) <= 1e-12`.

It preserves all four occupancy conditions, both topology cells, both arms,
policy parameters, packet sizes, clock bounds, dominance thresholds, safety
rules and the other 19 integrity gates from EXP23F. It uses 30 disjoint fresh
seeds `16069001:16069030`, for 480 trajectories. The invalid EXP23F output is
not pooled with EXP23G.

The decision rule remains unchanged. Any repeated terminal-certification,
safety, divergence or periodic epsilon-dominance failure sends ELCS-W back
to design. Only a 20/20 integrity pass without those failures can produce
`ELCS_W_BACKGROUND_ROBUSTNESS_SCREEN_SURVIVES`.
