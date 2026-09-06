# EXP23N — Coherence metadata packet-cost audit results

Source: `results/exp23k_horizon_scaled_development/2026-09-04_164602`

Status: **`COHERENCE_PACKET_FORMAT_RETAINS_COST_MARGIN`**.

The 60 physical schedules were reconstructed and every old RESPONSE packet
was decomposed into its exact certificate-entry count. Charging a 28-byte
coherence CLAIM and 10-byte horizon-bearing certificate entry gives:

- mean physical control bytes: `1,598.80 -> 1,817.03`;
- maximum packet size: `46` bytes, below the unchanged 96-byte MTU;
- MTU violations: `0`;
- charged candidate utilization: `0.28181609`;
- paired periodic utilization: `0.28672000`;
- charged candidate advantage: `1.710%`.

Thus explicit horizon metadata reduces the EXP23K cost advantage from 1.913%
to 1.710% but does not erase the frozen 1% development margin. REVOKE traffic
is zero only because the source cell is static; dynamic tests must charge each
24-byte REVOKE and any resulting reacquisition traffic.

This is same-seed accounting evidence. It permits the declared packet format
to enter distributed-kernel development but does not promote the method or
support a broad performance claim.

