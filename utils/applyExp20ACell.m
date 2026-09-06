function cfg=applyExp20ACell(cellId,seedValue)
%APPLYEXP20ACELL Reuse the six frozen EXP19A formation contexts.

R=exp20aRegistry();
cellId=lower(strtrim(char(cellId)));
idx=find(strcmp({R.cells.id},cellId),1);
if isempty(idx)
    error('applyExp20ACell: unknown context "%s".',cellId);
end
cfg=applyExp19ACell(cellId,seedValue);
cfg.exp20a=struct('version',R.version,'cell',cellId, ...
    'developmentFalsification',true, ...
    'candidateOptimizationAllowed',false);

end

