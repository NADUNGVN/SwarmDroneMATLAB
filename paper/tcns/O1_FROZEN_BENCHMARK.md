# Frozen O1 benchmark

The centralized current-state oracle is permanently identified as
`centralized_state_oracle_frozen` at commit
`ce835c9c3195db86e610c24f4a6db21d42211559`.

This freeze covers:

- the O1 Gate-3 cross-term equation;
- (H=25);
- the 14-value (lambda) grid;
- S2--S6 development scenarios and seeds;
- the 11-arm periodic comparator;
- `DATA + 0.25 ACK` accounting and normalization;
- lower-left frontier construction and 101-point shared-domain matching;
- Stage-A and Stage-B result artifacts.

O1 is an upper diagnostic benchmark. It uses exact current plant and receiver
memory centrally, has zero ACK traffic in C0, and must never be presented as
the proposed or implementable algorithm. AB0 may add hypothetical ACK cost to
the saved O1 trajectories, but may not alter their actions, plant trajectories
or recorded C0 results.
