# EXP23: local conflict-witness lease certificates

## 1. Boundary being repaired

The accepted event-driven ELCS-F kernel is safe under restricted visibility,
but not live. In EXP22I, the one-hop-management condition produced 0/100 fully
certified rows in both N5 and N10. Mean certified node-frame fractions were
0.3995 and 0.1998, with 94.56 and 117.10 fallback collision frames per run.
No false-valid edge occurred, so the defect is availability rather than
safety.

The cause is structural. The sender-conflict graph contains hidden-terminal
edges beyond the direct data-neighbor graph: 4 of 10 edges for N5 and 17 of 30
for N10. All conflict edges are nevertheless inside the two-hop neighbor
closure. Treating every management packet as all-to-all therefore hides the
main communication problem rather than solving it.

## 2. Witness cover

Let `G_m` be the directed management-decode graph and `F` the symmetric sender
conflict graph. Edges are visited in lexicographic endpoint order. For each
edge `{i,j}` in `F`, choose the eligible witness with minimum current assigned
edge load, breaking ties by node ID,

`w(i,j) in X(i,j)`,

where `X(i,j)` contains nodes that exchange management packets bidirectionally
with both endpoints; an endpoint has a trivial self-link. The configuration is
admissible only if every conflict edge has at least one witness.

`buildConflictWitnessMap` constructs this map deterministically and rejects no
edge silently. On the current symmetric one-hop graphs, every conflict edge
has a witness because the conflict graph is contained in the two-hop closure.

The frozen payload model for the first kernel is a 24-byte CLAIM, 16-byte CERT
header, 8 bytes per edge entry and a 96-byte control MTU. A response therefore
holds at most 10 entries; excess entries are fragmented and every fragment is
charged as a separate transmission. `conflictWitnessPayloadBound` computes
the exact per-epoch attempt and byte bound from the witness map.
If the higher-ID endpoint is itself the selected witness, it creates the
certificate locally after decoding the lower CLAIM. The edge still consumes a
radio RESPONSE entry because the other endpoint needs a receipt binding the
CLAIM sequence; otherwise a lost renewal CLAIM is undetectable at its sender.

## 3. Proposed ELCS-W state

Each sender `i` stores only local state:

- tuple `(epoch_i, slot_i, version_i)`;
- self-lock expiry `L_i`;
- certificates for incident lower-priority conflict edges;
- pending recolor/reconfiguration state.

Each witness stores, per assigned conflict edge, the latest decoded CLAIM from
both endpoints. A CLAIM carries node ID, tuple and a declared lock expiry. A
sender that attempts a CLAIM must retain the claimed tuple through that expiry
regardless of delivery outcome.

After decoding compatible fresh CLAIMs from both endpoints, the witness emits
a CERT entry binding both tuple versions and their distinct slots. The entry
expiry cannot exceed the smaller declared endpoint lock expiry. The higher-ID
endpoint becomes active on that edge only after decoding the matching CERT.
Witness transmissions may aggregate entries, but payload bytes and any
fragmentation must be charged explicitly.

## 4. Safety invariant

For each active conflict edge `{i,j}`, the client holds a non-expired witness
certificate binding distinct endpoint slots. Because both endpoints attempted
the bound CLAIMs and therefore self-lock those tuples beyond certificate
expiry plus the fence, neither endpoint can change into the other's slot while
the certificate is valid. Hence two active conflicting senders cannot occupy
the same scheduled slot.

Loss is fail-silent with respect to validity:

- lost CLAIM prevents witness state refresh;
- lost CERT prevents client activation/renewal;
- stale, future or tuple-mismatched CERT is rejected;
- no delivery failure creates positive evidence.

The proof obligation is local to each conflict edge and composes over `F`.

## 5. Acquisition and repair flow

1. A ready lower-priority node emits discovery CLAIM at the declared lease
   cadence and self-locks its tuple.
2. A witness that learns a lower tuple can advertise it to an unready
   higher-priority endpoint.
3. The higher endpoint chooses the smallest locally feasible slot and emits a
   request CLAIM, self-locking that tuple.
4. The witness emits CERT only after decoding both matching claims with
   distinct slots.
5. Reconfiguration first stops scheduled use, waits all self-lock and
   certificate fences, then increments the tuple version and re-enters CLAIM.

The implementation must freeze a finite response-entry format and prove a
zero-loss acquisition bound before any performance comparison.

## 6. Falsification sequence

1. witness-cover utility and topology contract tests;
2. deterministic zero-loss ELCS-W kernel with local management only;
3. lost CLAIM/CERT, stale/future CERT, state loss and recolor witnesses;
4. accounting closure including witness response payload and fragmentation;
5. common-PHY continuous integration;
6. repeat the exact periodic 1%-cost kill test;
7. only then open IID/burst/scaling robustness.

No EXP23 result inherits EXP22M's frontier verdict automatically because local
witness traffic changes both service timing and communication cost.
