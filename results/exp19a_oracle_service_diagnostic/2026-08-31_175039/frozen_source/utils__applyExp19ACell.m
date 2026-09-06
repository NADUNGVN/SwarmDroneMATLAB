function cfg=applyExp19ACell(cellId,seedValue)
%APPLYEXP19ACELL Build one of the six frozen EXP19A diagnostic contexts.

R=exp19aRegistry();
cellId=lower(strtrim(char(cellId)));
idx=find(strcmp({R.cells.id},cellId),1);
if isempty(idx)
    error('applyExp19ACell: unknown context "%s".',cellId);
end
c=R.cells(idx);
cfg=applyExp18Cell(c.id,seedValue);
cfg.mac.type=c.macType;
cfg.mac.pAccess=min(0.20,1/cfg.swarm.N);
cfg.mac=sharedMediumConfig(cfg);
cfg.exp19a=struct('version',R.version,'cell',cellId, ...
    'originalMacType',c.macType,'developmentOnly',true);

end
