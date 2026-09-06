function cfg=applyExp14ECell(cellId,seedValue)
%APPLYEXP14ECELL Build one frozen EXP14E holdout cell.

if ~isscalar(seedValue) || ~isfinite(seedValue) || ...
        seedValue<0 || seedValue~=floor(seedValue)
    error('applyExp14ECell: seedValue must be a nonnegative integer.');
end
cellId=lower(strtrim(char(cellId)));
switch cellId
    case 'n5-csma'
        cfg=study2Exp14Config(seedValue,'moderate');
    case 'n10-ring2'
        cfg=applyExp14OODPoint('n10-ring2',seedValue);
    case 'n20-ring2'
        cfg=applyExp14OODPoint('n20-ring2',seedValue);
    case 'n5-aloha'
        cfg=applyExp14OODPoint('aloha-p020',seedValue);
    otherwise
        error('applyExp14ECell: unknown cell "%s".',cellId);
end
cfg.exp14e.version='EXP14E-PREREGISTERED-HOLDOUT-v1';
cfg.exp14e.cell=cellId;
cfg.mac=sharedMediumConfig(cfg);

end
