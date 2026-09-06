function cfg=applyExp14DCell(cellId,seedValue)
%APPLYEXP14DCELL Build one fixed EXP14D boundary cell.

if ~isscalar(seedValue) || ~isfinite(seedValue) || ...
        seedValue<0 || seedValue~=floor(seedValue)
    error('applyExp14DCell: seedValue must be a nonnegative integer.');
end
cellId=lower(strtrim(char(cellId)));
switch cellId
    case 'n5-csma'
        cfg=study2Exp14Config(seedValue,'moderate');
    case 'n5-aloha'
        cfg=applyExp14OODPoint('aloha-p020',seedValue);
    case 'n10-ring2'
        cfg=applyExp14OODPoint('n10-ring2',seedValue);
    case 'n20-ring2'
        cfg=applyExp14OODPoint('n20-ring2',seedValue);
    otherwise
        error('applyExp14DCell: unknown cell "%s".',cellId);
end
cfg.exp14d.version='EXP14D-FACTORIAL-DEVELOPMENT-v1';
cfg.exp14d.cell=cellId;
cfg.mac=sharedMediumConfig(cfg);

end
