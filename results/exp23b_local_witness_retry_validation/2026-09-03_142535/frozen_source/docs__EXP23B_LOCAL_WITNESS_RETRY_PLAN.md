# EXP23B: local-witness causal retry validation

**Frozen before randomized outcomes:** 2026-09-03  
**Parent:** invalid EXP23A (`2026-09-01_203031`, 12/14 gates)  
**Rows:** 1,000 = 100 fresh seeds x 2 topologies x 5 conditions  
**Scope:** kernel repair only

The candidate, topology, one-hop management reach, payload sizes, loss rates,
permanent blackout and 95% liveness threshold are unchanged from EXP23A.

The repair adds only causal receipt/retry:

- every CLAIM attempt increments a local sequence and self-locks its tuple;
- each witness RESPONSE reports the exact endpoint sequences it decoded;
- a sender retries next frame until all incident witnesses return matching
  receipts;
- a higher-priority client also retries while any required CERT approaches
  its refresh boundary;
- a local client-witness still certifies locally, but its assigned edge remains
  in the transmitted RESPONSE so the other endpoint receives a receipt.

Two bounds are separated. The nominal bound counts scheduled renewal epochs
and must be met exactly at zero loss. The absolute finite-horizon bound permits
at most one CLAIM per node and one RESPONSE per active witness per frame; every
random-loss/blackout run must remain below it. Loss conditions must show
positive retry activation, preventing a false pass caused by an inert repair.

All EXP23A safety, DATA-separation, accounting and retained-failure gates remain
mandatory. Passing permits only common-PHY continuous integration.
