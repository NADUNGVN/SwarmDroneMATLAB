# EXP23R — Coherence packet-kernel graph-repair validation

Status: frozen before fresh-seed execution on 2026-09-04.

EXP23R repeats the 20 frozen EXP23P packet gates after the EXP23Q graph
repair. It uses 50 disjoint fresh seeds `16079001:16079050`, N5/N10, the same
three geometry cells and six channel cells, for 1,800 rows. The sender graph
is now the receiver lift of `physical interference OR intended DATA reach`.

The exact charged format remains 28-byte CLAIM, 16+10e-byte RESPONSE,
24-byte REVOKE and 96-byte MTU. Cumulative receipts, lease binding, loss,
shared occupancy, permanent directed RESPONSE blackout, retry, causality,
accounting, control bounds and all selector branches retain their EXP23P
definitions. No threshold or safety gate is relaxed.

A pass repairs only the static packet kernel and permits dynamic revocation
implementation plus later common-PHY closed-loop validation. It does not
promote the proposed method.
