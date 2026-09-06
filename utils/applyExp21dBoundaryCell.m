function cfg=applyExp21dBoundaryCell(cellId,seedValue)
%APPLYEXP21DBOUNDARYCELL Build a frozen boundary context.

R=exp21dBoundaryRegistry();
cellId=lower(strtrim(char(cellId)));
index=find(strcmp({R.cells.id},cellId),1);
if isempty(index)
    error('applyExp21dBoundaryCell: unknown cell "%s".',cellId);
end
cfg=applyExp21dClosedLoopCell(R.cells(index).closedLoopCell,seedValue);
cfg.exp21db=struct('version',R.version,'cell',cellId, ...
    'stage',R.stage,'policyOptimizationAllowed',false, ...
    'submissionClaimPermitted',false);

end
