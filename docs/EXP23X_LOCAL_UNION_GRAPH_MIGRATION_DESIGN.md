# EXP23X — Causal local union-graph migration design

Status: mathematical design before kernel implementation.

## 1. Scope exposed by EXP23W

EXP23W confirms early reactivation only when the certified conflict graph and
slot map do not change. A real envelope violation can change the revoking
sender's potential incident edges and may invalidate its old slot. Treating a
boolean `migrationUnionGraphCertified` flag as evidence is not sufficient.
EXP23X must construct and verify the old/new union explicitly and must force a
real slot change.

The first migration primitive is deliberately local: one sender `i` violates
its advertised tube, while every conflict edge not incident to `i` remains
inside the other senders' existing certificates. Concurrent independent
migrations are outside this first theorem.

## 2. Causal migration objects

Let `F0` be the retiring certified sender-conflict graph and `F1` the graph
computed from the sender's new causally available tube. Define

`FU = F0 union F1`.

The selector must construct all three graphs through the same receiver-lifted
detectability rule used after the EXP23Q repair. An independent oracle must
verify `Factual(t) subseteq FU` for every transition frame. A caller-supplied
truth flag is forbidden.

All nonmigrating nodes keep their old locked slots `c0(j)`. The migrating
sender selects

`c1(i) = min {s in 1..N : s != c0(j) for every {i,j} in FU}`.

At most `N-1` incident neighbors occupy slots, so at least one of the `N`
slots exists. The experiment must include fixtures where `c1(i) != c0(i)`;
otherwise graph migration has not been exercised.

## 3. Transition protocol

Before the first frame not covered by the old tube, sender `i`:

1. stops scheduled DATA locally and increments its tuple version;
2. emits the already charged best-effort REVOKE for its old tuple;
3. obtains a new causal tube and constructs `F1` and `FU`;
4. chooses `c1(i)` using the locked slots of all union neighbors;
5. sends a fresh version/sequence-bound CLAIM for `(i,c1(i),expiry,FU)`;
6. waits for cumulative RESPONSES from the assigned witness of every union
   edge incident to `i`;
7. reactivates only after every such receipt closes.

The witness map is built from `FU`, not from `F0` or `F1` alone. A missing
union witness, over-MTU response, stale version, missing CLAIM field or missing
RESPONSE keeps the sender suppressed. REVOKE delivery is not a precondition
for reactivation.

## 4. Local migration safety theorem

Assume:

1. before suppression, the actual graph is covered by `F0` and active old
   tuples form a proper coloring of `F0`;
2. sender `i` suppresses before its old tube ceases to cover reality;
3. all non-`i` incident relations remain covered by their retiring
   certificates throughout the transition;
4. after the old-tube boundary, every actual edge incident to `i` lies in
   `FU`;
5. `c1(i)` differs from the current self-locked slot of every union neighbor;
6. every incident union witness returns fresh positive evidence bound to the
   new version and CLAIM sequence before `i` reactivates.

Then reactivating `i` cannot create a same-slot scheduled conflict during the
transition, even if every REVOKE is lost.

Proof sketch: while `i` is suppressed it cannot participate in a scheduled
collision. Every conflict among nonmigrating nodes remains safe by assumptions
1 and 3. When `i` reactivates, any actual incident edge belongs to `FU` by
assumption 4. The selected slot differs from that neighbor's still self-locked
slot by assumption 5, and fresh witness receipts make this a positive causal
fact rather than receiver truth. Therefore no actual incident conflicting
pair shares a slot. REVOKE affects only remote cache cleanup and cannot weaken
the local silence or positive receipt condition.

## 5. Required falsification cases

The kernel study must contain at least:

- added and removed incident edges with an actual changed slot;
- the adversarial case where reusing the old slot would collide on a new
  edge;
- delayed and erased CLAIM/RESPONSE with eventual cumulative closure;
- permanent required-witness RESPONSE blackout, which stays suppressed;
- permanent REVOKE blackout, which preserves the delivered-REVOKE local
  history;
- incomplete union graph, which the independent oracle rejects rather than
  accepting a false certificate;
- missing union management coverage and response payload above MTU, both
  fail-silent;
- stale/future/mismatched migration version and sequence fields;
- simultaneous two-sender migration as an explicit unsupported boundary,
  not silently treated as covered;
- exact CLAIM/RESPONSE/REVOKE bytes, recipients, airtime and analytical upper
  bounds.

Only a valid kernel result permits common-PHY continuous integration and then
closed-loop comparison. No new performance claim is attached to EXP23X.
