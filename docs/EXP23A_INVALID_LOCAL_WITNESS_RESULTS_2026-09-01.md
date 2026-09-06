# EXP23A invalid local-witness kernel result

Run: `results/exp23a_local_witness_kernel_falsification/2026-09-01_203031`

EXP23A retained all 1,000 rows and passed 12/14 gates. All safety, causality,
witness-cover, DATA-separation, permanent-blackout and attempt/byte/recipient
accounting gates passed. The frozen 95% liveness gates failed:

- CLAIM erasure 5%: 37.5% terminal full certification;
- CERT erasure 5%: 53.0% terminal full certification.

The mechanism attempted renewal only once per 13-frame period. A lost CLAIM or
CERT close to lease expiry therefore caused an outage until the next period.
The result is invalid for continuous integration and no threshold is relaxed.

EXP23B adds causal receipt/retry. Every CLAIM attempt has a new sequence;
witness responses acknowledge the exact sequence decoded, and a sender retries
in the next frame until all incident witnesses return matching receipts. A
client also retries while any certificate approaches its refresh boundary.
The original payload is amended so every assigned edge consumes a witness
response entry: even when the client is the witness and certifies locally, the
other endpoint needs a radio receipt to know that its CLAIM was decoded.
