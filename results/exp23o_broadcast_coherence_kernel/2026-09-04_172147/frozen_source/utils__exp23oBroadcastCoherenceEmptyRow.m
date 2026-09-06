function row=exp23oBroadcastCoherenceEmptyRow()
%EXP23OBROADCASTCOHERENCEEMPTYROW Stable receiver-lift row.

row=exp23mCoherenceGeometryEmptyRow();
row.DATA_NEIGHBOR_GRAPH_HASH=NaN;
row.dataNeighborEdges=NaN;
row.selectedPhysicalEdges=NaN;
row.hiddenSenderConflictEdges=NaN;

end
