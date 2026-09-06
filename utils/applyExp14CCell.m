function cfg=applyExp14CCell(cellId,seedValue)
%APPLYEXP14CCELL Build one closed EXP14C development boundary cell.

if ~isscalar(seedValue) || ~isfinite(seedValue) || ...
        seedValue<0 || seedValue~=floor(seedValue)
    error('applyExp14CCell: seedValue must be a nonnegative integer.');
end
cellId=lower(strtrim(char(cellId)));

switch cellId
    case 'n5-csma'
        cfg=study2Exp14Config(seedValue,'moderate');
    case 'n5-aloha'
        cfg=applyExp14OODPoint('aloha-p020',seedValue);
    case 'n5-background030'
        cfg=applyExp14OODPoint('background030',seedValue);
    case 'n5-hidden'
        cfg=applyExp14OODPoint('hidden-terminal',seedValue);
    case 'n10-ring2'
        cfg=applyExp14OODPoint('n10-ring2',seedValue);
    case 'n20-ring2'
        cfg=applyExp14OODPoint('n20-ring2',seedValue);
    otherwise
        error('applyExp14CCell: unknown cell "%s".',cellId);
end

cfg.exp14c.version='EXP14C-DEVELOPMENT-v1';
cfg.exp14c.cell=cellId;
cfg.mac=sharedMediumConfig(cfg);

end
