# EXP23AC receiver-lifted dependency diagnostic

Date: 2026-09-05  
Stage: post-EXP23AB model-scope falsification; development diagnostic.

## Question

Can the one-sender local-union migration proved in EXP23X be connected directly to online causal motion tubes when only UAV 10 updates its advertised state?

The tempting assumption is that changing one node's tube changes only sender-conflict edges incident to that node. This diagnostic tests that assumption under the exact receiver-lift used by the common PHY.

## Causal plant stimulus

- N=10 ring-2 swarm, IID-20 DATA loss, seed 16089999 (not a confirmation seed).
- At 6 s, UAV 10 receives a public desired-offset ramp ending at 10 s.
- Five safe candidate offsets are characterized; candidate 3, `[-1.05, 0.55, 0]`, is used for graph scanning.
- At each online sample, all current self estimates are available; the retiring state differs only by using UAV 10's immediately preceding self estimate.
- No future trajectory enters the graph decision.

The scan covers tube horizons {0.5, 0.75, 1.0} s, physical interference radii {0.20, 0.25, ..., 0.45} m, and declared acceleration bounds {0.35, 0.40, 0.50} m/s^2.

## Falsification condition

For every old/new graph pair, compute the receiver-lifted sender conflict graphs through the production builder. If an edge not incident to UAV 10 changes, the one-sender local-migration premise is false even though only UAV 10 changed its tube.

This is a diagnostic, not a parameter-selection experiment. A radius for which no problem appears does not rescue the general claim. Any observed nonlocal dependency requires a closure-based multi-sender migration mechanism before online coupling can continue.

