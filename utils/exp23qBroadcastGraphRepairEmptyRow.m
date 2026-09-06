function row=exp23qBroadcastGraphRepairEmptyRow()
%EXP23QBROADCASTGRAPHREPAIREMPTYROW Stable graph-repair row.

row=exp23oBroadcastCoherenceEmptyRow();
row.reachOnlyActualConflictEdges=NaN;
row.directDeliveryCollisionViolations=NaN;

end
