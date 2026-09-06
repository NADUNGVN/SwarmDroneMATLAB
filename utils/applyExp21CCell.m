function cfg=applyExp21CCell(cellId,seedValue)
%APPLYEXP21CCELL Build one frozen EXP21C closed-loop context.

R=exp21cRegistry();
cellId=lower(strtrim(char(cellId)));
idx=find(strcmp({R.cells.id},cellId),1);
if isempty(idx), error('applyExp21CCell: unknown cell "%s".',cellId); end
c=R.cells(idx);
cfg=applyExp21ACell(c.exp21aCell,seedValue);
cfg.exp21c=struct('version',R.version,'cell',c.id, ...
    'stage',R.stage,'policyOptimizationAllowed',false);

end
