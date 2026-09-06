# EXP23AA — Protected emergency DATA development plan

Status: frozen before randomized execution.

EXP23Z established a sharp boundary: fail-silent lease acquisition avoids an
unsafe shared-slot reuse, but permanent RESPONSE loss removes the migrating
UAV's DATA service and causes closed-loop separation failures. EXP23AA adds
one separately accounted emergency slot outside both the retiring and union
colorings. A suppressed sender may use only its own protected slot; this does
not certify or reuse the disputed shared slot.

The development matrix uses 20 new seeds and six IID-20 arms: periodic;
migration without emergency service; migration with emergency service;
protected migration with REVOKE blackout; protected migration with permanent
RESPONSE blackout; and the original silent RESPONSE-blackout negative
control. The maximum palette is ten slots; ordinary local recoloring still
moves UAV 10 from slot 7 to slot 9, while slot 10 is reserved exclusively for
emergency DATA.

Eighteen gates cover exact parent status, matrix pairing, graph stimulus,
emergency opportunity mapping, causal/clock/replay/accounting contracts,
zero collisions, normal reacquisition, the replicated unsafe silent negative
control, safety recovery under protected RESPONSE blackout, and REVOKE-loss
independence. Performance and cost contrasts remain descriptive development
outcomes. Geometry-to-plant online coupling and fresh-seed confirmation are
still prohibited regardless of outcome.
