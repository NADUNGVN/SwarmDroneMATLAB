# EXP21D D-STR source-to-kernel rule map

This ledger prevents the D-STR label from being attached to a generic
round-robin or custom reservation mechanism.  Page numbers refer to
`arXiv:2511.12888v1`.

| Kernel rule | Primary-source location | Implementation status |
|---|---|---|
| periodic safety beacons carry state plus schedule/reception metadata | pp. 5, 7--8 | required |
| exactly five management slots `TG`, `TGn`, `TS`, `TSo`, `TSn` | pp. 7--8 | required |
| reception record values: none, decoded, energy/no decode | p. 8 | required |
| one first node; other nodes enter Assignment after decoding a beacon | pp. 10--12 | required |
| random choice among locally available transmission slots | p. 12 | required |
| later beacon records provide implicit reception evidence | pp. 12, 17--18 | required |
| Assignment succeeds only when all already-known reporters return fresh success; otherwise it selects another slot | Sec. 4.5 | unknown neighbors may still cause temporary acceptance, but a missing known report causes a causal one-superframe retry rather than indefinite wait |
| failed Assignment retries; `CT` failure or no slot triggers `TG` | pp. 12--13 | required |
| `TGn` energy signals colliding growth requests and applies `GM` growth | pp. 13--14 | required |
| Resolved node releases after failed reception evidence subject to retention probability | pp. 12, 17 | required |
| `TS` proposes shrink, `TSo` objects, `TSn` marks undecodable proposal | pp. 14--16 | required |
| only Resolved nodes count silent slots; every Assignment node objects to shrink | Sec. 4.4, pp. 14--15 | required |
| objected slots enter `failed_shrink`; `FST` expires entries and removal shifts cache indices | Sec. 4.4.1, pp. 15--16 | required with source-evaluated `FST=30` in v3; retained v1/v2 use `FST=10` |
| initial shrink backoff follows the node's order in the superframe; NACK-only retries use truncated exponential backoff | Sec. 4.4 and 4.4.2, pp. 15--16 | ascending preconfigured formation-node order supplies a unique causal rank even under spatial reuse; retry exponent cap is declared as six |
| removal shifts later slots and preserves transmission order | pp. 15, 17 | required |
| management transmissions use formation-wide higher-power reach in native model | pp. 9, 13--15 | required native assumption |
| native formation is a 10 m-spaced rectangular hexagonal structure with 10 m safety radius | Sec. 3 and Table 4 | compact rectangular hex graph reproduced for `N=5,10` |
| DATA success in the source is determined by path loss, aggregate interference, noise, and SINR | Sec. 3 and Table 4 | deliberate binary safety-neighborhood conflict-graph abstraction; kernel conformance cannot reproduce source numerical PHY outcomes |
| timing synchronization is treated as solved using GPS | p. 6 | preserved only in native arm; explicitly relaxed later |
| rigid, static neighborhood and no external interference | pp. 5--6 | preserved only in native arm; explicitly relaxed later |
| node may temporarily accept before an unheard neighbor supplies contrary evidence | p. 18 | must remain observable, not silently repaired by oracle |
| grow/shrink under incomplete management reach | outside native formation-wide management assumption | update only nodes that locally transmit, decode, or energy-detect the exchange; never shift all nodes from simulator truth |
| node loses its local scheduling state during boundary churn | outside rigid/static native assumption | reset only that node's local state; peers retain stale records until normal traffic changes their evidence |
| continuous oscillator phase/drift and guard overlap | not part of the isolated source-mapped state-machine reproduction | logical slot alignment retained in EXP21D-K; compose the already validated EXP21B/C timing layer only in EXP21D-CL |
| every node transmits in the same data slot, leaving no idle reception-record observer | mechanism boundary implied by half-duplex implicit evidence, not a claimed source result | preserve nonconvergence and zero hidden-truth repair; use a separate partial-collision witness for `TG/TGn` |

Any deliberate abstraction or omitted rule must be added here before a
randomized outcome is generated.
