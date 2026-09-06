# EXP23X — Local union-graph migration kernel plan

Status: selector implementation and unit contracts precede randomized packet
execution.

The first implementation unit is
`network/buildLocalUnionGraphMigration.m`. It accepts explicit retiring and
candidate conflict graphs, the locked old slot vector, one transition node,
management reach and packet-size limits. It independently forms the union,
rejects any nonincident graph change, verifies the retiring coloring, builds
the union witness map, chooses the smallest union-safe slot from a palette of
`N`, and rejects missing witness coverage or an over-MTU local response.

The adversarial fixture removes edge `{4,5}` and adds `{3,5}` while nodes 3
and 5 share old slot 1. Reusing the old tuple would therefore collide. A valid
selector must move node 5 to slot 3 and prove the complete union coloring.

The next executable stage will add a packet lifecycle around this selector:
cumulative fresh CLAIM receipts for every incident union witness, exact
version/sequence binding, delivered/lost REVOKE equivalence, fail-silent
permanent RESPONSE blackout and an independent time-varying actual-graph
oracle. Only after randomized kernel validation will the new slot be mapped
onto the common-PHY continuous schedule.
