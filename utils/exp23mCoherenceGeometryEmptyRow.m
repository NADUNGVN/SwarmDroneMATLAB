function row=exp23mCoherenceGeometryEmptyRow()
%EXP23MCOHERENCEGEOMETRYEMPTYROW Stable repaired geometry row.

row=exp23lCoherenceGeometryEmptyRow();
row.speedScale=NaN;
row.accelerationScale=NaN;
row.managementRadius=NaN;

end
