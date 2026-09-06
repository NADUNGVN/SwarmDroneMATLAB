# EXP23V — Witness-confirmed early reactivation

Status: mathematical repair contract before implementation testing.

## Problem exposed by EXP23U

The conservative lifecycle waits until every old lease could have expired,
even after all incident witnesses have acknowledged the sender's fresh tuple.
This produced a multi-second outage and 2.32%/8.26% RMSE inflation for early /
late revocation. The old-fence wait is sufficient but not necessary when the
new schedule is certified against every still-locked neighbor tuple.

## Early-reactivation certificate

Let `F_union` contain every conflict edge in both the retiring and candidate
certified graphs over the transition interval. Sender `i` first suppresses
scheduled DATA and increments its tuple version. It may reactivate before the
old fence only if:

1. a causal new bounded configuration and `F_union` are available;
2. the new slot of `i` differs from the currently self-locked tuple at the
   other endpoint of every edge incident to `i` in `F_union`;
3. every assigned incident witness has received the same fresh CLAIM sequence
   and returned a version-bound RESPONSE entry to `i`; and
4. the sender remains suppressed until all those cumulative receipts close.

For an edge `{i,j}`, its witness checks the new tuple of `i` against the
self-locked current tuple of `j`. Therefore `i` receiving all incident
responses proves pairwise slot separation without requiring `j` to receive
REVOKE or the new certificate first. Node `j` keeps its locked slot; stale
belief about `i` cannot cause `j` to change tuple. Missing RESPONSE leaves the
transaction open and `i` suppressed. Missing REVOKE only delays cache cleanup.

This proof requires the transition graph to be the old/new union. Early
reactivation is forbidden if union coverage, witness coverage, payload/MTU or
fresh-response closure is absent. The first implementation test uses an
unchanged fixed graph, for which the union condition is exact. Online graph
replacement is a later, stricter study.
