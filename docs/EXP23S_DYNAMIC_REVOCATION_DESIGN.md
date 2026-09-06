# EXP23S — Dynamic self-revocation and reacquisition design

Status: implementation contract frozen before dynamic kernel testing.

## Safety role

The certified sender graph already contains every conflict allowed by the
advertised reachable tubes over the lease horizon. Edge additions and removals
inside those tubes therefore require no schedule change. If a sender detects
that it will leave its advertised tube, it must stop scheduled DATA locally
before the first violating frame. This local suppression—not REVOKE delivery—
is the safety action.

The 24-byte REVOKE reuses the revoking sender's reserved CLAIM minislot. It
carries the sender and revoked tuple version. A receiver clears positive
state only when that version exactly matches its cached certificate tuple.
Loss or rejection of REVOKE cannot create validity. Static and dynamic modes
share the same packet, recipient and airtime accounting.

## Reacquisition rule

After revocation, the sender increments its tuple version and remains in
fallback. It may start a cumulative CLAIM transaction only after a causal
`reacquireEligible` indication confirms that a new bounded tube/configuration
is available. It cannot resume scheduled DATA until:

1. it has issued a CLAIM for the incremented version;
2. every incident witness has acknowledged that CLAIM transaction; and
3. the maximum old self-lock fence captured at revocation has expired.

Waiting out the old fence ensures that a client which missed REVOKE cannot
retain an overlapping positive lease when the sender resumes. Delivered
REVOKE may invalidate cached state earlier, but is not used to shorten the
sender's mandatory silence.

The first dynamic kernel study keeps the certified supergraph and color map
fixed. It varies the actual physical graph inside that supergraph, injects a
single local envelope violation involving the revoking sender, and later
returns the sender to a bounded tube for reacquisition. Dynamic graph
reselection/color migration is a later obligation and is not claimed here.

## Falsification obligations

- static mode remains bit-identical in behavior and reports zero revocations;
- self-suppression begins no later than the first injected violating frame;
- actual edge additions/removals within the certified graph have zero
  scheduled collisions;
- an out-of-envelope edge involving the revoked sender cannot cause a
  scheduled collision while that sender is suppressed;
- permanent or asymmetric REVOKE loss does not change the mandatory silence
  fence and cannot create positive validity;
- the incremented tuple reacquires only after a fresh cumulative transaction
  and the old fence;
- stale/future/version-mismatched REVOKE metadata cannot clear a nonmatching
  cached tuple;
- CLAIM, RESPONSE, REVOKE, DATA recipient counts and bytes close exactly;
- decisions read no future random draw or receiver-side delivery truth.
